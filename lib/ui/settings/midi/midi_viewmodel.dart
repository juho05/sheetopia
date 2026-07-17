/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:sheetopia/data/repositories/midi/midi_repository.dart';
import 'package:sheetopia/data/repositories/midi/remembered_device.dart';

class MidiViewModel extends ChangeNotifier {
  final MidiRepository _repo;

  List<MidiDevice> _devices = [];
  UnmodifiableListView<MidiDevice> get devices =>
      UnmodifiableListView(_devices);

  Set<MidiDeviceKey> _remembered = {};

  final Set<String> _connectingIds = {};
  UnmodifiableSetView<String> get connectingIds =>
      UnmodifiableSetView(_connectingIds);

  // Remembered devices that are not currently visible in the scan.
  List<MidiDeviceKey> get rememberedAbsent {
    final present = _devices.map(MidiDeviceKey.fromDevice).toSet();
    return _remembered.where((k) => !present.contains(k)).toList();
  }

  StreamSubscription? _devicesSub;
  StreamSubscription? _rememberedSub;
  MidiViewModel({required MidiRepository midiRepository})
    : _repo = midiRepository {
    _devicesSub = _repo.devices.listen((devices) {
      _devices = devices;
      notifyListeners();
    });
    _rememberedSub = _repo.rememberedKeys.listen((remembered) {
      _remembered = remembered;
      notifyListeners();
    });
    _repo.startScanning();
  }

  void forget(MidiDeviceKey key) => _repo.forgetDevice(key);

  Future<void> connectDevice(MidiDevice device) async {
    _connectingIds.add(device.id);
    notifyListeners();
    try {
      await _repo.connectDevice(device);
    } finally {
      _connectingIds.remove(device.id);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    _rememberedSub?.cancel();
    _repo.stopScanning();
    super.dispose();
  }
}
