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

class MidiViewModel extends ChangeNotifier {
  final MidiRepository _repo;

  List<MidiDevice> _devices = [];
  UnmodifiableListView<MidiDevice> get devices =>
      UnmodifiableListView(_devices);

  final Set<String> _connectingIds = {};
  UnmodifiableSetView<String> get connectingIds =>
      UnmodifiableSetView(_connectingIds);

  StreamSubscription? _devicesSub;
  MidiViewModel({required MidiRepository midiRepository})
    : _repo = midiRepository {
    _devicesSub = _repo.devices.listen((devices) {
      _devices = devices;
      notifyListeners();
    });
    _repo.startScanning();
  }

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
    _repo.stopScanning();
    super.dispose();
  }
}
