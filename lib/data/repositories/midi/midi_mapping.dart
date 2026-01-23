import 'dart:typed_data';

class MidiMappings {
  final MidiMapping? nextPage;
  final MidiMapping? prevPage;

  MidiMappings({this.nextPage, this.prevPage});

  MidiMappings withNextPage(MidiMapping? nextPage) {
    return MidiMappings(nextPage: nextPage, prevPage: prevPage);
  }

  MidiMappings withPrevPage(MidiMapping? prevPage) {
    return MidiMappings(nextPage: nextPage, prevPage: prevPage);
  }
}

class MidiMapping {
  final int command;
  final int? param;
  final int? minValue;

  MidiMapping({required this.command, this.param, this.minValue});

  bool matches(Uint8List data) {
    if (data.firstOrNull != command ||
        (param != null && data.elementAtOrNull(1) != param)) {
      return false;
    }
    if (minValue != null) {
      final value = data.elementAtOrNull(2);
      if (value == null) return false;
      if (value < minValue!) return false;
    }
    return true;
  }

  @override
  String toString() {
    if (command >= 0x90 && command < 0xA0) {
      return "NoteOn $param";
    }
    if (command >= 0xB0 && command < 0xC0) {
      return "Continuous $param";
    }
    return "$command $param";
  }
}
