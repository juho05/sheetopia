/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sheetopia/data/repositories/midi/midi_mapping.dart';
import 'package:sheetopia/ui/common/toast.dart';

enum MidiAction { nextPage, prevPage }

typedef MidiActionListener = void Function(MidiAction action);

class MidiRepository {
  final _midi = MidiCommand();

  final int _minContinuousValue = 40;

  final BehaviorSubject<List<MidiDevice>> _devices = BehaviorSubject.seeded(
    const [],
  );

  ValueStream<List<MidiDevice>> get devices => _devices.stream;

  // device id -> mappings
  final Map<String, MidiMappings> _midiMappings = {};

  final Set<MidiActionListener> _actionListeners = {};

  final Map<String, Completer<void>> _registerNextPageDeviceIds = {};
  final Map<String, Completer<void>> _registerPrevPageDeviceIds = {};

  MidiRepository() {
    // TODO init only when midi is enabled in settings
    _init();
  }

  Future<void> _init() async {
    _devices.add(await _midi.devices ?? []);
    _midi.onMidiDataReceived?.listen(_onData);
    _midi.onMidiDeviceDisconnected?.listen(_onDeviceDisconnected);
    await _midi
        .startBluetoothCentral()
        .catchError((e, st) {
          print("$e\n$st");
        })
        .then((value) async {
          await _midi.waitUntilBluetoothIsInitialized().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print("bluetooth timeout");
            },
          );
        });
  }

  // device id -> controller ids
  final Map<String, Set<int>> _pressedContinuousControllers = {};

  Future<void> _onData(MidiPacket? packet) async {
    if (packet == null) return;

    final mapping = _createMappingsFromData(packet.data);
    if (mapping != null) {
      if (_registerNextPageDeviceIds.containsKey(packet.device.id)) {
        _midiMappings[packet.device.id] ??= MidiMappings();
        _midiMappings[packet.device.id] = _midiMappings[packet.device.id]!
            .withNextPage(mapping);
        _registerNextPageDeviceIds[packet.device.id]!.complete();
        _registerNextPageDeviceIds.remove(packet.device.id);
        return;
      }
      if (_registerPrevPageDeviceIds.containsKey(packet.device.id)) {
        _midiMappings[packet.device.id] ??= MidiMappings();
        _midiMappings[packet.device.id] = _midiMappings[packet.device.id]!
            .withPrevPage(mapping);
        _registerPrevPageDeviceIds[packet.device.id]!.complete();
        _registerPrevPageDeviceIds.remove(packet.device.id);
        return;
      }
    }

    if (packet.data.first >= 0xB0 &&
        packet.data.first < 0xC0 &&
        packet.data.length >= 3) {
      if (packet.data[2] == 0) {
        _pressedContinuousControllers[packet.device.id]?.remove(packet.data[1]);
      } else if (_pressedContinuousControllers[packet.device.id]?.contains(
            packet.data[1],
          ) ??
          false) {
        return;
      }
      if (packet.data[2] >= _minContinuousValue) {
        _pressedContinuousControllers[packet.device.id] ??= {};
        _pressedContinuousControllers[packet.device.id]!.add(packet.data[1]);
      }
    }

    final mappings = _midiMappings[packet.device.id];
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
    final mappings = _midiMappings[device.id];
    if (mappings == null) return;
    _midiMappings[device.id] = mappings.withNextPage(null);
  }

  void removePrevPageMapping(MidiDevice device) async {
    final mappings = _midiMappings[device.id];
    if (mappings == null) return;
    _midiMappings[device.id] = mappings.withPrevPage(null);
  }

  MidiMappings getMidiMappings(MidiDevice device) {
    return _midiMappings[device.id] ?? MidiMappings();
  }

  Future<void> registerNextPage(MidiDevice device) async {
    final completer = Completer<void>();
    _registerNextPageDeviceIds[device.id] = completer;
    return completer.future;
  }

  void cancelRegisterNextPage(MidiDevice device) async {
    final completer = _registerNextPageDeviceIds[device.id];
    if (completer == null) return;
    if (!completer.isCompleted) {
      completer.complete();
    }
    _registerNextPageDeviceIds.remove(device.id);
  }

  Future<void> registerPrevPage(MidiDevice device) async {
    final completer = Completer<void>();
    _registerPrevPageDeviceIds[device.id] = completer;
    return completer.future;
  }

  void cancelRegisterPrevPage(MidiDevice device) async {
    final completer = _registerPrevPageDeviceIds[device.id];
    if (completer == null) return;
    if (!completer.isCompleted) {
      completer.complete();
    }
    _registerPrevPageDeviceIds.remove(device.id);
  }

  void addActionListener(MidiActionListener listener) {
    _actionListeners.add(listener);
  }

  void removeActionListener(MidiActionListener listener) {
    _actionListeners.remove(listener);
  }

  bool _scanning = false;

  Future<void> startScanning() async {
    if (_scanning) return;
    _scanning = true;

    if (_midi.bluetoothState == BluetoothState.poweredOn) {
      await _midi.startScanningForBluetoothDevices();
    } else {
      print("bluetooth not powered on: ${_midi.bluetoothState.name}");
    }

    await _checkForNewDevices();
  }

  void stopScanning() async {
    if (!_scanning) return;
    _scanning = false;
    _midi.stopScanningForBluetoothDevices();
  }

  Future<void> _onDeviceDisconnected(MidiDevice device) async {
    _unregisterDevice(device);
    _devices.add(await _midi.devices ?? []);
    Toast.show("${device.name} disconnected!");
  }

  Future<void> connectDevice(MidiDevice device) async {
    await _midi.connectToDevice(device);
    _devices.add(await _midi.devices ?? []);
  }

  Future<void> disconnectDevice(MidiDevice device) async {
    _unregisterDevice(device);
    _midi.disconnectDevice(device);
    _devices.add(await _midi.devices ?? []);
  }

  void _unregisterDevice(MidiDevice device) {
    _pressedContinuousControllers.remove(device.id);
    _midiMappings.remove(device.id);
    cancelRegisterNextPage(device);
    cancelRegisterPrevPage(device);
  }

  Future<void> _checkForNewDevices() async {
    if (!_scanning) return;

    final devices = await _midi.devices ?? [];
    if (!const ListEquality().equals(_devices.value, devices)) {
      _devices.add(devices);
    }
    Future.delayed(const Duration(seconds: 2)).then((value) {
      _checkForNewDevices();
    });
  }
}
