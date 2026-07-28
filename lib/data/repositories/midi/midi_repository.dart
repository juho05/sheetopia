/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
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
  static const _reconnectScanTimeout = Duration(seconds: 20);
  static const _reconnectStartupScanTimeout = Duration(minutes: 1);
  static const _reconnectBackoff = Duration(seconds: 5);
  static const _devicePollInterval = Duration(seconds: 20);

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

  final Map<MidiDeviceKey, MidiMappings> _midiMappings = {};

  final Set<MidiActionListener> _actionListeners = {};

  final Map<MidiDeviceKey, Completer<void>> _registerNextPageKeys = {};
  final Map<MidiDeviceKey, Completer<void>> _registerPrevPageKeys = {};

  final Map<MidiDeviceKey, Set<int>> _pressedContinuousControllers = {};

  MidiRepository({required KeyValueRepository keyValue})
    : _keyValue = keyValue {
    // TODO init only when midi is enabled in settings
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_scanRefCount > 0) {
        unawaited(_startBleScan());
      }
      _scanToReconnect(timeout: _reconnectStartupScanTimeout);
    }
  }

  Future<void> _init() async {
    await _loadRememberedDevices();
    _devices.add(await _midi.devices ?? []);
    _midi.onMidiDataReceived?.listen(_onData);
    _midi.onMidiDeviceDisconnected?.listen(_onDeviceDisconnected);
    _midi.onMidiSetupChanged?.listen(_onSetupChanged);
    _midi.onBluetoothStateChanged.listen(_onBluetoothStateChanged);
    await _midi
        .startBluetoothCentral()
        .catchError((e, st) {
          Log.error("Failed to start Bluetooth central", e: e, st: st);
        })
        .then((value) async {
          await _midi.waitUntilBluetoothIsInitialized().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              Log.warn("Timed out waiting for Bluetooth to initialize");
            },
          );
        });
    await _scanToReconnect(timeout: _reconnectStartupScanTimeout);
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
      _rememberedKeys.add({..._rememberedKeys.value, key});
    }
    await _persistRememberedDevices();
  }

  Future<void> forgetDevice(MidiDeviceKey key) async {
    if (!_rememberedKeys.value.contains(key)) return;
    _rememberedKeys.add({..._rememberedKeys.value}..remove(key));
    _midiMappings.remove(key);
    await _persistRememberedDevices();
  }

  Future<void> _onData(MidiPacket? packet) async {
    if (packet == null) return;

    final key = MidiDeviceKey.fromDevice(packet.device);

    final mapping = _createMappingsFromData(packet.data);
    if (mapping != null) {
      if (_registerNextPageKeys.containsKey(key)) {
        _midiMappings[key] = (_midiMappings[key] ?? MidiMappings())
            .withNextPage(mapping);
        await _rememberAndPersist(key);
        _registerNextPageKeys[key]?.complete();
        _registerNextPageKeys.remove(key);
        return;
      }
      if (_registerPrevPageKeys.containsKey(key)) {
        _midiMappings[key] = (_midiMappings[key] ?? MidiMappings())
            .withPrevPage(mapping);
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

  int _scanRefCount = 0;
  bool _bleScanActive = false;
  bool _pollScheduled = false;

  final Map<MidiDeviceKey, Future<void>> _connectsInFlight = {};
  final Map<MidiDeviceKey, DateTime> _reconnectBackoffUntil = {};

  bool _reconnectScanActive = false;
  Timer? _reconnectScanTimer;

  Future<void> startScanning() async {
    _scanRefCount++;
    if (_scanRefCount > 1) return;
    await _startBleScan();
    _startPollLoop();
  }

  void stopScanning() {
    if (_scanRefCount == 0) return;
    _scanRefCount--;
    if (_scanRefCount > 0) return;
    _bleScanActive = false;
    _midi.stopScanningForBluetoothDevices();
  }

  Future<void> _startBleScan() async {
    if (_midi.bluetoothState != BluetoothState.poweredOn) {
      Log.info(
        "Skipping BLE scan: Bluetooth is not powered on (${_midi.bluetoothState.name})",
      );
      return;
    }
    try {
      await _midi.startScanningForBluetoothDevices();
      _bleScanActive = true;
    } catch (e) {
      Log.error("Failed to start BLE scan", e: e);
    }
  }

  Future<void> _connect(MidiDevice device) {
    final key = MidiDeviceKey.fromDevice(device);
    return _connectsInFlight[key] ??= _doConnect(device, key);
  }

  Future<void> _doConnect(MidiDevice device, MidiDeviceKey key) async {
    try {
      await _midi.connectToDevice(device).timeout(_connectTimeout);
    } catch (_) {
      _midi.disconnectDevice(device);
      rethrow;
    } finally {
      _connectsInFlight.remove(key);
    }
  }

  // Event-driven refresh comes from onMidiSetupChanged; this slow poll is only a
  // fallback for platforms/paths that miss a setup event.
  void _startPollLoop() {
    if (_pollScheduled) return;
    _pollScheduled = true;
    _pollDevices();
  }

  Future<void> _pollDevices() async {
    if (_scanRefCount == 0) {
      _pollScheduled = false;
      return;
    }
    await _refreshDevices();
    Future.delayed(_devicePollInterval, _pollDevices);
  }

  Future<void> _refreshDevices() async {
    final devices = await _midi.devices ?? [];
    if (!_sameDevices(_devices.value, devices)) {
      _devices.add(devices);
      _maybeAutoReconnect();
    }
  }

  bool _sameDevices(List<MidiDevice> a, List<MidiDevice> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].name != b[i].name ||
          a[i].type != b[i].type ||
          a[i].connected != b[i].connected) {
        return false;
      }
    }
    return true;
  }

  Future<void> _onSetupChanged(String event) async {
    _devices.add(await _midi.devices ?? []);
    _maybeAutoReconnect();
  }

  Future<void> _onBluetoothStateChanged(BluetoothState state) async {
    switch (state) {
      case BluetoothState.poweredOn:
        if (_scanRefCount > 0 && !_bleScanActive) {
          await _startBleScan();
        }
        await _scanToReconnect();
      case BluetoothState.poweredOff:
        _bleScanActive = false;
        _stopReconnectScan();
        _devices.add(await _midi.devices ?? []);
        Toast.show("Bluetooth is off");
      case BluetoothState.unauthorized:
        _bleScanActive = false;
        _stopReconnectScan();
        _devices.add(await _midi.devices ?? []);
        Toast.show("Bluetooth permission denied");
      case BluetoothState.resetting:
        _bleScanActive = false;
        _stopReconnectScan();
      default:
        break;
    }
  }

  void _maybeAutoReconnect() {
    if (_hasReconnectableDisconnected()) {
      _reconnectMatching(_devices.value);
    } else {
      _stopReconnectScan();
    }
  }

  bool _hasReconnectableDisconnected() {
    final remembered = _rememberedKeys.value;
    if (remembered.isEmpty) return false;
    final connected = _devices.value
        .where((d) => d.connected)
        .map(MidiDeviceKey.fromDevice)
        .toSet();
    return remembered.any((k) => !connected.contains(k));
  }

  // Bounded scan that connects remembered devices as they appear, then stops
  // once all are connected or the timeout elapses.
  Future<void> _scanToReconnect({
    Duration timeout = _reconnectScanTimeout,
  }) async {
    if (_midi.bluetoothState != BluetoothState.poweredOn) return;
    if (!_hasReconnectableDisconnected()) return;
    if (_reconnectScanActive) {
      _reconnectScanTimer?.cancel();
      _reconnectScanTimer = Timer(timeout, _stopReconnectScan);
      await _reconnectMatching(_devices.value);
      return;
    }
    _reconnectScanActive = true;
    await startScanning();
    _reconnectScanTimer = Timer(timeout, _stopReconnectScan);
    await _reconnectMatching(_devices.value);
  }

  void _stopReconnectScan() {
    if (!_reconnectScanActive) return;
    _reconnectScanActive = false;
    _reconnectScanTimer?.cancel();
    _reconnectScanTimer = null;
    stopScanning();
  }

  Future<void> _reconnectMatching(List<MidiDevice> devices) async {
    if (_midi.bluetoothState != BluetoothState.poweredOn) return;
    final remembered = _rememberedKeys.value;
    if (remembered.isEmpty) return;
    for (final device in devices) {
      final key = MidiDeviceKey.fromDevice(device);
      if (!remembered.contains(key)) continue;
      if (device.connected) continue;
      if (_connectsInFlight.containsKey(key)) continue;
      final until = _reconnectBackoffUntil[key];
      if (until != null && DateTime.now().isBefore(until)) continue;
      unawaited(_autoConnect(device, key));
    }
  }

  Future<void> _autoConnect(MidiDevice device, MidiDeviceKey key) async {
    try {
      await _connect(device);
      _reconnectBackoffUntil.remove(key);
      _devices.add(await _midi.devices ?? []);
      Toast.show("Reconnected to ${device.name}");
    } catch (_) {
      _reconnectBackoffUntil[key] = DateTime.now().add(_reconnectBackoff);
    } finally {
      if (!_hasReconnectableDisconnected()) _stopReconnectScan();
    }
  }

  Future<void> _onDeviceDisconnected(MidiDevice device) async {
    final key = MidiDeviceKey.fromDevice(device);
    _unregisterDevice(device);
    final devices = await _midi.devices ?? [];
    for (final d in devices) {
      if (device.id == d.id) d.connected = false;
    }
    _devices.add(devices);
    Toast.show("${device.name} disconnected");
    if (_rememberedKeys.value.contains(key)) {
      await _scanToReconnect();
    }
  }

  Future<void> connectDevice(MidiDevice device) async {
    final key = MidiDeviceKey.fromDevice(device);
    try {
      await _connect(device);
      await _rememberAndPersist(key);
    } catch (_) {
      Toast.show("Could not connect to ${device.name}");
    } finally {
      _devices.add(await _midi.devices ?? []);
    }
  }

  Future<void> disconnectDevice(MidiDevice device) async {
    final key = MidiDeviceKey.fromDevice(device);
    _unregisterDevice(device);
    await forgetDevice(key);
    _midi.disconnectDevice(device);
    _devices.add(await _midi.devices ?? []);
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
    _devices.close();
    _rememberedKeys.close();
  }
}
