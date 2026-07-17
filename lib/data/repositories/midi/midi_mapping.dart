/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

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

  Map<String, dynamic> toJson() => {
    "nextPage": nextPage?.toJson(),
    "prevPage": prevPage?.toJson(),
  };

  factory MidiMappings.fromJson(Map<String, dynamic> json) => MidiMappings(
    nextPage: json["nextPage"] == null
        ? null
        : MidiMapping.fromJson((json["nextPage"] as Map).cast<String, dynamic>()),
    prevPage: json["prevPage"] == null
        ? null
        : MidiMapping.fromJson((json["prevPage"] as Map).cast<String, dynamic>()),
  );
}

class MidiMapping {
  final int command;
  final int? param;
  final int? minValue;

  MidiMapping({required this.command, this.param, this.minValue});

  Map<String, dynamic> toJson() => {
    "command": command,
    "param": param,
    "minValue": minValue,
  };

  factory MidiMapping.fromJson(Map<String, dynamic> json) => MidiMapping(
    command: json["command"] as int,
    param: json["param"] as int?,
    minValue: json["minValue"] as int?,
  );

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
