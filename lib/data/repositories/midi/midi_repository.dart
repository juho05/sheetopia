/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/midi/midi_mapping.dart';
import 'package:sheetopia/data/repositories/midi/remembered_device.dart';
import 'package:sheetopia/ui/common/toast.dart';

enum MidiAction { nextPage, prevPage }

typedef MidiActionListener = void Function(MidiAction action);

class MidiRepository with WidgetsBindingObserver {
  static const _rememberedDevicesKey = "midi.remembered_devices";
  static const _connectTimeout = Duration(seconds: 20);
  static const _reconnectBackoff = Duration(seconds: 5);
  static const _devicePollInterval = Duration(seconds: 20);

  // Android downgrades scans running for 30 minutes to opportunistic mode.
  static const _bleScanRestartInterval = Duration(minutes: 25);

  // Android throttles apps that start more than 5 scans within 30 seconds.
  static const _bleScanStopDelay = Duration(seconds: 10);
  static const _bluetoothOffToastDelay = Duration(seconds: 2);

  final MidiCommand _midi = MidiCommand();
  final KeyValueRepository _keyValue;

  final int _minContinuousValue = 40;

  final BehaviorSubject<List<MidiDevice>> _devices = BehaviorSubject.seeded(
    const [],
  );

  ValueStream<List<MidiDevice>> get devices => _devices.stream;

  final BehaviorSubject<Set<MidiDeviceKey>> _rememberedKeys =
      BehaviorSubject.seeded(const {});

  ValueStream<Set<MidiDeviceKey>> get rememberedKeys => _rememberedKeys.stream;

  late final BehaviorSubject<BluetoothState> _bluetoothState =
      BehaviorSubject.seeded(_midi.bluetoothState);

  ValueStream<BluetoothState> get bluetoothState => _bluetoothState.stream;

  final Map<MidiDeviceKey, MidiMappings> _midiMappings = {};

  final Set<MidiActionListener> _actionListeners = {};

  final Map<MidiDeviceKey, Completer<void>> _registerNextPageKeys = {};
  final Map<MidiDeviceKey, Completer<void>> _registerPrevPageKeys = {};

  final Map<MidiDeviceKey, Set<int>> _pressedContinuousControllers = {};

  Future<void>? _bluetoothStarting;

  int _pageScanRefs = 0;
  bool _foreground = _isForeground(WidgetsBinding.instance.lifecycleState);
  bool _wasInBackground = false;

  bool _bleScanActive = false;
  Timer? _bleScanRestartTimer;
  Timer? _bleScanStopTimer;
  Timer? _pollTimer;

  final Map<MidiDeviceKey, Future<void>> _connectsInFlight = {};
  final Map<MidiDeviceKey, DateTime> _reconnectBackoffUntil = {};

  MidiRepository({required this._keyValue}) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  static bool _isForeground(AppLifecycleState? state) =>
      state == null ||
      state == AppLifecycleState.resumed ||
      state == AppLifecycleState.inactive;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = _isForeground(state);
    if (!foreground) _wasInBackground = true;
    if (state == AppLifecycleState.resumed) {
      if (_wasInBackground &&
          (_pageScanRefs > 0 ||
              _rememberedKeys.value.any((k) => k.type == "bluetooth")) &&
          _midi.bluetoothState == BluetoothState.unauthorized) {
        Log.debug(
          "Retrying Bluetooth start after resume, it was unauthorized before",
        );
        unawaited(startBluetooth());
      }
      _wasInBackground = false;
    }
    if (foreground == _foreground) return;
    _foreground = foreground;
    Log.debug(
      "MIDID: app moved to ${foreground ? "foreground" : "background"}",
    );
    if (foreground) {
      unawaited(_refreshDevices());
    } else {
      _updateScanning();
    }
  }

  Future<void> _init() async {
    await _loadRememberedDevices();
    _midi.onMidiDataReceived?.listen(_onData);
    _midi.onMidiDeviceDisconnected?.listen(_onDeviceDisconnected);
    _midi.onMidiSetupChanged?.listen((_) => _refreshDevices());
    _midi.onBatteryLevelChanged?.listen((_) => _refreshDevices());
    _midi.onBluetoothStateChanged.listen(_onBluetoothStateChanged);
    await _refreshDevices();
    if (_rememberedKeys.value.any((k) => k.type == "bluetooth")) {
      Log.debug(
        "Starting Bluetooth on launch because a bluetooth device is remembered",
      );
      await startBluetooth();
    }
  }

  Future<void> startBluetooth() =>
      _bluetoothStarting ??= _startBluetoothCentral().whenComplete(() {
        _bluetoothStarting = null;
      });

  Future<void> _startBluetoothCentral() async {
    Log.debug("Starting Bluetooth central");
    try {
      await _midi.startBluetoothCentral();
    } catch (e, st) {
      Log.error("Failed to start Bluetooth central", e: e, st: st);
      return;
    }
    await _midi.waitUntilBluetoothIsInitialized().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        Log.warn("Timed out waiting for Bluetooth to initialize");
      },
    );
  }

  Future<void> _loadRememberedDevices() async {
    final remembered = (await _keyValue.loadObjectList(
      _rememberedDevicesKey,
      RememberedDevice.fromJson,
    ))?.toList();
    if (remembered == null) return;
    for (final device in remembered) {
      _midiMappings[device.key] = device.mappings;
    }
    _rememberedKeys.add(remembered.map((d) => d.key).toSet());
    Log.debug(
      "Loaded remembered MIDI devices: ${_rememberedKeys.value.join(", ")}",
    );
  }

  Future<void> _persistRememberedDevices() async {
    final devices = _rememberedKeys.value
        .map(
          (key) => RememberedDevice(
            name: key.name,
            type: key.type,
            mappings: _midiMappings[key] ?? MidiMappings(),
          ).toJson(),
        )
        .toList();
    await _keyValue.store(_rememberedDevicesKey, devices);
  }

  Future<void> _rememberAndPersist(MidiDeviceKey key) async {
    if (!_rememberedKeys.value.contains(key)) {
      Log.debug("Remembering MIDI device $key");
      _rememberedKeys.add({..._rememberedKeys.value, key});
      _updateScanning();
    }
    await _persistRememberedDevices();
  }

  Future<void> forgetDevice(MidiDeviceKey key) async {
    if (!_rememberedKeys.value.contains(key)) return;
    Log.debug("Forgetting MIDI device $key");
    _rememberedKeys.add({..._rememberedKeys.value}..remove(key));
    _midiMappings.remove(key);
    _updateScanning();
    await _persistRememberedDevices();
  }

  Future<void> _onData(MidiPacket? packet) async {
    if (packet == null) return;
    final data = packet.data;
    // a note_on with velocyity 0 is equivalent to note_off and should be ignored
    if (data.length >= 3 && data[0] & 0xF0 == 0x90 && data[2] == 0) return;

    final key = MidiDeviceKey.fromDevice(packet.device);

    final mapping = _createMappingsFromData(packet.data);
    if (mapping != null) {
      if (_registerNextPageKeys.containsKey(key)) {
        _midiMappings[key] = (_midiMappings[key] ?? MidiMappings())
            .withNextPage(mapping);
        Log.debug("Mapped next page of $key to $mapping");
        await _rememberAndPersist(key);
        _registerNextPageKeys[key]?.complete();
        _registerNextPageKeys.remove(key);
        return;
      }
      if (_registerPrevPageKeys.containsKey(key)) {
        _midiMappings[key] = (_midiMappings[key] ?? MidiMappings())
            .withPrevPage(mapping);
        Log.debug("Mapped previous page of $key to $mapping");
        await _rememberAndPersist(key);
        _registerPrevPageKeys[key]?.complete();
        _registerPrevPageKeys.remove(key);
        return;
      }
    }

    if (packet.data.first >= 0xB0 &&
        packet.data.first < 0xC0 &&
        packet.data.length >= 3) {
      if (packet.data[2] == 0) {
        _pressedContinuousControllers[key]?.remove(packet.data[1]);
      } else if (_pressedContinuousControllers[key]?.contains(packet.data[1]) ??
          false) {
        return;
      }
      if (packet.data[2] >= _minContinuousValue) {
        _pressedContinuousControllers[key] ??= {};
        _pressedContinuousControllers[key]!.add(packet.data[1]);
      }
    }

    final mappings = _midiMappings[key];
    if (mappings == null) return;

    if (mappings.nextPage?.matches(packet.data) ?? false) {
      for (final listener in _actionListeners) {
        listener(MidiAction.nextPage);
      }
      return;
    }
    if (mappings.prevPage?.matches(packet.data) ?? false) {
      for (final listener in _actionListeners) {
        listener(MidiAction.prevPage);
      }
    }
  }

  MidiMapping? _createMappingsFromData(Uint8List data) {
    if (data.isEmpty) return null;
    if (data.first >= 0x90 && data.first < 0xA0 && data.length >= 2) {
      return MidiMapping(command: data.first, param: data[1]);
    }
    if (data.first >= 0xB0 && data.first < 0xC0 && data.length >= 2) {
      return MidiMapping(
        command: data.first,
        param: data[1],
        minValue: _minContinuousValue,
      );
    }
    return null;
  }

  void removeNextPageMapping(MidiDevice device) async {
    final key = MidiDeviceKey.fromDevice(device);
    final mappings = _midiMappings[key];
    if (mappings == null) return;
    _midiMappings[key] = mappings.withNextPage(null);
    await _persistRememberedDevices();
  }

  void removePrevPageMapping(MidiDevice device) async {
    final key = MidiDeviceKey.fromDevice(device);
    final mappings = _midiMappings[key];
    if (mappings == null) return;
    _midiMappings[key] = mappings.withPrevPage(null);
    await _persistRememberedDevices();
  }

  MidiMappings getMidiMappings(MidiDevice device) {
    return _midiMappings[MidiDeviceKey.fromDevice(device)] ?? MidiMappings();
  }

  Future<void> registerNextPage(MidiDevice device) async {
    final completer = Completer<void>();
    _registerNextPageKeys[MidiDeviceKey.fromDevice(device)] = completer;
    return completer.future;
  }

  void cancelRegisterNextPage(MidiDevice device) async {
    final key = MidiDeviceKey.fromDevice(device);
    final completer = _registerNextPageKeys[key];
    if (completer == null) return;
    if (!completer.isCompleted) {
      completer.complete();
    }
    _registerNextPageKeys.remove(key);
  }

  Future<void> registerPrevPage(MidiDevice device) async {
    final completer = Completer<void>();
    _registerPrevPageKeys[MidiDeviceKey.fromDevice(device)] = completer;
    return completer.future;
  }

  void cancelRegisterPrevPage(MidiDevice device) async {
    final key = MidiDeviceKey.fromDevice(device);
    final completer = _registerPrevPageKeys[key];
    if (completer == null) return;
    if (!completer.isCompleted) {
      completer.complete();
    }
    _registerPrevPageKeys.remove(key);
  }

  void addActionListener(MidiActionListener listener) {
    _actionListeners.add(listener);
  }

  void removeActionListener(MidiActionListener listener) {
    _actionListeners.remove(listener);
  }

  void startScanning() {
    _pageScanRefs++;
    Log.debug("MIDI page scan requested, refs: $_pageScanRefs");
    _updateScanning();
  }

  void stopScanning() {
    if (_pageScanRefs == 0) return;
    _pageScanRefs--;
    Log.debug("MIDI page scan released, refs: $_pageScanRefs");
    _updateScanning();
  }

  // Scans while the MIDI page is open or a remembered device could reconnect.
  // Wired devices report hot plugs on their own, the poll is only a fallback.
  void _updateScanning() {
    final missing = _missingRememberedKeys().where(_canReconnect).toList();
    final active = _foreground && (_pageScanRefs > 0 || missing.isNotEmpty);
    final bluetooth =
        active &&
        _midi.bluetoothState == BluetoothState.poweredOn &&
        (_pageScanRefs > 0 || missing.any((k) => k.type == "bluetooth"));

    if (active && _pollTimer == null) {
      Log.debug("Starting MIDI device poll: ${_scanReason(missing)}");
      _pollTimer = Timer.periodic(
        _devicePollInterval,
        (_) => _refreshDevices(),
      );
    } else if (!active && _pollTimer != null) {
      Log.debug("Stopping MIDI device poll: ${_idleReason(bluetooth: false)}");
      _pollTimer!.cancel();
      _pollTimer = null;
    }

    if (bluetooth) {
      final bleMissing = missing.where((k) => k.type == "bluetooth");
      if (_bleScanStopTimer != null) {
        Log.debug(
          "Cancelled pending BLE scan stop: ${_scanReason(bleMissing)}",
        );
        _bleScanStopTimer!.cancel();
        _bleScanStopTimer = null;
      }
      if (!_bleScanActive) {
        Log.debug("Starting BLE scan: ${_scanReason(bleMissing)}");
        unawaited(_startBleScan());
      }
    } else if (_bleScanActive && _bleScanStopTimer == null) {
      Log.debug(
        "Stopping BLE scan in ${_bleScanStopDelay.inSeconds}s, "
        "${_idleReason(bluetooth: true)}",
      );
      _bleScanStopTimer = Timer(_bleScanStopDelay, () {
        Log.debug("Stopped BLE scan");
        _bleScanStopped();
        _midi.stopScanningForBluetoothDevices();
      });
    }
  }

  String _scanReason(Iterable<MidiDeviceKey> missing) {
    if (_pageScanRefs > 0) return "MIDI page open";
    return "remembered devices missing: ${missing.join(", ")}";
  }

  String _idleReason({required bool bluetooth}) {
    if (!_foreground) return "app in background";
    if (bluetooth && _midi.bluetoothState != BluetoothState.poweredOn) {
      return "Bluetooth ${_midi.bluetoothState.name}";
    }
    final kind = bluetooth ? "bluetooth device" : "device";
    return "MIDI page closed and no reconnectable remembered $kind missing";
  }

  Set<MidiDeviceKey> _missingRememberedKeys() {
    final connected = _devices.value
        .where((d) => d.connected)
        .map(MidiDeviceKey.fromDevice)
        .toSet();
    return _rememberedKeys.value.difference(connected);
  }

  bool _canReconnect(MidiDeviceKey key) =>
      key.type != "bluetooth" ||
      _midi.bluetoothState == BluetoothState.poweredOn;

  Future<void> _startBleScan() async {
    _bleScanActive = true;
    try {
      await _midi.startScanningForBluetoothDevices();
    } catch (e) {
      _bleScanActive = false;
      Log.error("Failed to start BLE scan", e: e);
      return;
    }
    if (!_bleScanActive || !Platform.isAndroid) return;
    _bleScanRestartTimer?.cancel();
    _bleScanRestartTimer = Timer.periodic(_bleScanRestartInterval, (_) {
      Log.debug("Restarting long running BLE scan");
      _midi.startScanningForBluetoothDevices().catchError((e) {
        Log.error("Failed to restart BLE scan", e: e);
      });
    });
  }

  void _bleScanStopped() {
    _bleScanActive = false;
    _bleScanRestartTimer?.cancel();
    _bleScanRestartTimer = null;
    _bleScanStopTimer?.cancel();
    _bleScanStopTimer = null;
  }

  Future<void> _connect(MidiDevice device) {
    final key = MidiDeviceKey.fromDevice(device);
    return _connectsInFlight[key] ??= _doConnect(device, key);
  }

  Future<void> _doConnect(MidiDevice device, MidiDeviceKey key) async {
    Log.debug("Connecting to MIDI device $key");
    try {
      await _midi.connectToDevice(device).timeout(_connectTimeout);
      Log.debug("Connected to MIDI device $key");
    } catch (_) {
      _midi.disconnectDevice(device);
      rethrow;
    } finally {
      _connectsInFlight.remove(key);
    }
  }

  Future<void> _refreshDevices() async {
    final devices = await _midi.devices ?? [];
    if (_devices.isClosed) return;
    if (!_sameDevices(_devices.value, devices)) {
      Log.debug("MIDI devices changed: ${_describeDevices(devices)}");
      _devices.add(devices);
    }
    _onDevicesChanged();
  }

  void _onDevicesChanged() {
    _reconnectMatching();
    _updateScanning();
  }

  String _describeDevices(List<MidiDevice> devices) {
    if (devices.isEmpty) return "none";
    return devices
        .map((d) {
          final state = d.connected ? "connected" : "disconnected";
          final battery = d.batteryLevel == null ? "" : ", ${d.batteryLevel}%";
          return "${MidiDeviceKey.fromDevice(d)} [$state$battery]";
        })
        .join(", ");
  }

  bool _sameDevices(List<MidiDevice> a, List<MidiDevice> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].name != b[i].name ||
          a[i].type != b[i].type ||
          a[i].connected != b[i].connected ||
          a[i].batteryLevel != b[i].batteryLevel) {
        return false;
      }
    }
    return true;
  }

  Future<void> _onBluetoothStateChanged(BluetoothState state) async {
    Log.debug("Bluetooth state changed to ${state.name}");
    _bluetoothState.add(state);
    if (state != BluetoothState.poweredOn) {
      if (_bleScanActive) Log.debug("BLE scan ended: Bluetooth ${state.name}");
      _bleScanStopped();
    }
    if (state == BluetoothState.poweredOff) {
      unawaited(_toastIfBluetoothStaysOff());
    }
    await _refreshDevices();
  }

  // A toast shown while hidden stays frozen until the window is restored, since
  // no frames are produced. It would then report a state that may be long gone.
  Future<void> _toastIfBluetoothStaysOff() async {
    await Future.delayed(_bluetoothOffToastDelay);
    if (_midi.bluetoothState != BluetoothState.poweredOff) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle == AppLifecycleState.hidden ||
        lifecycle == AppLifecycleState.paused) {
      return;
    }
    Toast.show("Bluetooth is off");
  }

  void _reconnectMatching() {
    final missing = _missingRememberedKeys();
    for (final device in _devices.value) {
      if (device.connected) continue;
      final key = MidiDeviceKey.fromDevice(device);
      if (!missing.contains(key) || !_canReconnect(key)) continue;
      if (_connectsInFlight.containsKey(key)) continue;
      final until = _reconnectBackoffUntil[key];
      if (until != null && DateTime.now().isBefore(until)) continue;
      Log.debug("Reconnecting to remembered MIDI device $key");
      unawaited(_autoConnect(device, key));
    }
  }

  Future<void> _autoConnect(MidiDevice device, MidiDeviceKey key) async {
    try {
      await _connect(device);
    } catch (e) {
      Log.debug(
        "Reconnect to $key failed, retrying in "
        "${_reconnectBackoff.inSeconds}s at the earliest",
        e: e,
      );
      _reconnectBackoffUntil[key] = DateTime.now().add(_reconnectBackoff);
      return;
    }
    _reconnectBackoffUntil.remove(key);
    Toast.show("Reconnected to ${device.name}");
    await _refreshDevices();
  }

  Future<void> _onDeviceDisconnected(MidiDevice device) async {
    Log.debug("MIDI device ${MidiDeviceKey.fromDevice(device)} disconnected");
    _unregisterDevice(device);
    final devices = await _midi.devices ?? [];
    if (_devices.isClosed) return;
    for (final d in devices) {
      if (device.id == d.id) d.connected = false;
    }
    _devices.add(devices);
    Toast.show("${device.name} disconnected");
    _onDevicesChanged();
  }

  Future<void> connectDevice(MidiDevice device) async {
    final key = MidiDeviceKey.fromDevice(device);
    try {
      await _connect(device);
      await _rememberAndPersist(key);
    } catch (e) {
      Log.warn("Failed to connect to MIDI device $key", e: e);
      Toast.show("Could not connect to ${device.name}");
    } finally {
      await _refreshDevices();
    }
  }

  Future<void> disconnectDevice(MidiDevice device) async {
    final key = MidiDeviceKey.fromDevice(device);
    Log.debug("Disconnecting MIDI device $key on user request");
    _unregisterDevice(device);
    await forgetDevice(key);
    _midi.disconnectDevice(device);
    await _refreshDevices();
  }

  // Only clears transient runtime state; mappings survive for reconnect.
  void _unregisterDevice(MidiDevice device) {
    final key = MidiDeviceKey.fromDevice(device);
    _pressedContinuousControllers.remove(key);
    cancelRegisterNextPage(device);
    cancelRegisterPrevPage(device);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _bleScanRestartTimer?.cancel();
    _bleScanStopTimer?.cancel();
    _devices.close();
    _rememberedKeys.close();
    _bluetoothState.close();
  }
}
