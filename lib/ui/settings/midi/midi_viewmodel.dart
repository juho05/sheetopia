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
