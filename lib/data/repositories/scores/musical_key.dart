/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

class MusicalKey implements Comparable<MusicalKey> {
  static const tonics = [
    "C",
    "C#",
    "D",
    "D#",
    "E",
    "F",
    "F#",
    "G",
    "G#",
    "A",
    "A#",
    "B",
  ];

  static const _enharmonics = {
    "C#": "Db",
    "D#": "Eb",
    "F#": "Gb",
    "G#": "Ab",
    "A#": "Bb",
    "B": "Cb",
  };

  final String tonic;
  final bool minor;

  const MusicalKey(this.tonic, {this.minor = false});

  String get name => _withMode(tonic);

  Iterable<String> get spellings => [
    name,
    if (_enharmonics[tonic] case final alt?) _withMode(alt),
  ];

  String get label => "${displayTonic(tonic)} ${minor ? "minor" : "major"}";

  String _withMode(String tonic) => minor ? "${tonic}m" : tonic;

  static String displayTonic(String tonic) =>
      [tonic, ?_enharmonics[tonic]].map(_withSymbols).join("/");

  static String _withSymbols(String tonic) =>
      tonic.replaceFirst("#", "\u266F", 1).replaceFirst("b", "\u266D", 1);

  static MusicalKey? parse(String? name) {
    if (name == null) return null;
    final minor = name.endsWith("m");
    final spelled = minor ? name.substring(0, name.length - 1) : name;
    final tonic = tonics.contains(spelled)
        ? spelled
        : _enharmonics.entries
              .where((e) => e.value == spelled)
              .firstOrNull
              ?.key;
    if (tonic == null) return null;
    return MusicalKey(tonic, minor: minor);
  }

  @override
  int compareTo(MusicalKey other) {
    final byTonic = tonics
        .indexOf(tonic)
        .compareTo(tonics.indexOf(other.tonic));
    if (byTonic != 0) return byTonic;
    return (minor ? 1 : 0).compareTo(other.minor ? 1 : 0);
  }

  @override
  bool operator ==(Object other) =>
      other is MusicalKey && other.tonic == tonic && other.minor == minor;

  @override
  int get hashCode => Object.hash(tonic, minor);

  @override
  String toString() => name;
}
