import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:sheetopia/data/repositories/midi/midi_repository.dart';

class MidiDeviceViewModel extends ChangeNotifier {
  final MidiRepository _repo;

  MidiDevice? _device;
  MidiDevice? get device => _device;

  StreamSubscription? _devicesSub;
  MidiDeviceViewModel({
    required String deviceId,
    required MidiRepository midiRepository,
  }) : _repo = midiRepository {
    _load(deviceId, _repo.devices.value);
    _devicesSub = _repo.devices.listen((devices) {
      _load(deviceId, devices);
    });
  }

  void _load(String id, List<MidiDevice> devices) {
    _device = devices.where((d) => d.id == id).firstOrNull;
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (_device == null) return;
    await _repo.disconnectDevice(_device!);
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    super.dispose();
  }
}
