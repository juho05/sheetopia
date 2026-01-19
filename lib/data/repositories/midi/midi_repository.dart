import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:rxdart/rxdart.dart';

class MidiRepository {
  final _midi = MidiCommand();

  final BehaviorSubject<List<MidiDevice>> _devices = BehaviorSubject.seeded(
    const [],
  );
  ValueStream<List<MidiDevice>> get devices => _devices.stream;

  MidiRepository() {
    // TODO init only when midi is enabled in settings
    _init();
  }

  Future<void> _init() async {
    _devices.add(await _midi.devices ?? []);
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

  Future<void> connectDevice(MidiDevice device) async {
    await _midi.connectToDevice(device);
    _devices.add(await _midi.devices ?? []);
  }

  Future<void> disconnectDevice(MidiDevice device) async {
    _midi.disconnectDevice(device);
    _devices.add(await _midi.devices ?? []);
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
