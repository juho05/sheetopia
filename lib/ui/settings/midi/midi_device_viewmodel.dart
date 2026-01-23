import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:sheetopia/data/repositories/midi/midi_repository.dart';

class MidiDeviceViewModel extends ChangeNotifier {
  final MidiRepository _repo;

  MidiDevice? _device;
  MidiDevice? get device => _device;

  bool _recordingNextPage = false;
  bool get recordingNextPage => _recordingNextPage;
  bool _recordingPrevPage = false;
  bool get recordingPrevPage => _recordingPrevPage;

  String? get nextPageMapping => _device != null
      ? _repo.getMidiMappings(_device!).nextPage?.toString()
      : null;
  String? get prevPageMapping => _device != null
      ? _repo.getMidiMappings(_device!).prevPage?.toString()
      : null;

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

  Future<void> recordNextPage() async {
    _recordingNextPage = true;
    notifyListeners();
    try {
      await _repo.registerNextPage(_device!);
    } finally {
      _recordingNextPage = false;
      notifyListeners();
    }
  }

  void cancelNextPage() {
    _repo.cancelRegisterNextPage(_device!);
    _recordingNextPage = false;
    notifyListeners();
  }

  void resetNextPage() {
    _repo.removeNextPageMapping(_device!);
    notifyListeners();
  }

  Future<void> recordPrevPage() async {
    _recordingPrevPage = true;
    notifyListeners();
    try {
      await _repo.registerPrevPage(_device!);
    } finally {
      _recordingPrevPage = false;
      notifyListeners();
    }
  }

  void cancelPrevPage() {
    _repo.cancelRegisterPrevPage(_device!);
    _recordingPrevPage = false;
    notifyListeners();
  }

  void resetPrevPage() {
    _repo.removePrevPageMapping(_device!);
    notifyListeners();
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
