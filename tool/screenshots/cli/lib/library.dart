import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import 'util.dart';

/// Ids of the demo library's items by name, read from the archive the app
/// imports.
class Library {
  final String path;
  final Map<String, Map<String, String>> _ids;

  Library._(this.path, this._ids);

  static Library read(String path) {
    final archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
    Map<String, String> ids(String file, String nameKey) {
      final entry = archive.findFile(file);
      if (entry == null) throw ToolException('$file missing in $path');
      final list = jsonDecode(utf8.decode(entry.content)) as List;
      return {for (final m in list.cast<Map>()) m[nameKey] as String: m['id'] as String};
    }

    return Library._(path, {
      'score': ids('scores.json', 'title'),
      'setlist': ids('setlists.json', 'name'),
      'routine': ids('practice_routines.json', 'name'),
      'exercise': ids('exercises.json', 'name'),
    });
  }

  String _id(String kind, String name) =>
      _ids[kind]![name] ?? (throw ToolException('the demo library has no $kind "$name", update tool/screenshots/cli/lib/scenes.dart'));

  String score(String title) => _id('score', title);
  String setlist(String name) => _id('setlist', name);
  String routine(String name) => _id('routine', name);
  String exercise(String name) => _id('exercise', name);
}
