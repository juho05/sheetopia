/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:sheetopia/data/repositories/midi/midi_mapping.dart';

class MidiDeviceKey {
  final String name;
  final String type;

  const MidiDeviceKey({required this.name, required this.type});

  factory MidiDeviceKey.fromDevice(MidiDevice device) =>
      MidiDeviceKey(name: device.name, type: normalizeType(device.type));

  // "BLE" and "bonded" are the same physical bluetooth device across launches.
  static String normalizeType(String type) {
    if (type == "BLE" || type == "bonded") return "bluetooth";
    return type;
  }

  @override
  bool operator ==(Object other) =>
      other is MidiDeviceKey && other.name == name && other.type == type;

  @override
  int get hashCode => Object.hash(name, type);

  @override
  String toString() => "$name ($type)";
}

class RememberedDevice {
  final String name;
  final String type;
  final MidiMappings mappings;

  RememberedDevice({
    required this.name,
    required this.type,
    required this.mappings,
  });

  MidiDeviceKey get key => MidiDeviceKey(name: name, type: type);

  RememberedDevice copyWith({MidiMappings? mappings}) => RememberedDevice(
    name: name,
    type: type,
    mappings: mappings ?? this.mappings,
  );

  Map<String, dynamic> toJson() => {
    "version": 1,
    "name": name,
    "type": type,
    "mappings": mappings.toJson(),
  };

  factory RememberedDevice.fromJson(Map<String, dynamic> json) =>
      RememberedDevice(
        name: json["name"] as String,
        type: json["type"] as String,
        mappings: MidiMappings.fromJson(
          (json["mappings"] as Map).cast<String, dynamic>(),
        ),
      );
}
