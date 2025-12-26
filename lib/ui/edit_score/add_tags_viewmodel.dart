import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';

class AddTagsViewModel extends ChangeNotifier {
  final ScoresRepository _repo;

  final Set<Tag> _scoreTags;
  Set<Tag> get scoreTags => UnmodifiableSetView(_scoreTags);

  List<Tag> _results = [];
  List<Tag> get results => UnmodifiableListView(_results);

  final Set<Tag> _selected = {};
  Set<Tag> get selected => UnmodifiableSetView(_selected);

  String _currentFilter = "";
  String get currentFilter => _currentFilter;

  bool _manageTagsMode = false;
  bool get manageTagsMode => _manageTagsMode;

  AddTagsViewModel({
    required Set<Tag> scoreTags,
    required ScoresRepository repo,
  }) : _scoreTags = scoreTags,
       _repo = repo {
    _loadTags("").then((_) => notifyListeners());
  }

  Future<void> enterManageTagsMode() async {
    _manageTagsMode = true;
    await _loadTags(_currentFilter);
    notifyListeners();
  }

  Future<void> exitManageTagsMode() async {
    _manageTagsMode = false;
    await _loadTags(_currentFilter);
    notifyListeners();
  }

  Future<void> filter(String query) async {
    _currentFilter = query;
    await _loadTags(query);
    notifyListeners();
  }

  Future<void> createdTag(Tag tag) async {
    _selected.add(tag);
    await _loadTags(_currentFilter);
    notifyListeners();
  }

  Future<void> editedTag() async {
    await _loadTags(_currentFilter);
    notifyListeners();
  }

  Future<void> _loadTags(String filter) async {
    final tags = await _repo.getTags(
      filter: filter.isNotEmpty ? filter : null,
      excludeTagIds: manageTagsMode ? const [] : _scoreTags.map((t) => t.id),
    );
    _results = tags;
  }

  void select(Tag t) {
    _selected.add(t);
    notifyListeners();
  }

  void deselect(Tag t) {
    _selected.remove(t);
    notifyListeners();
  }

  Future<void> deleteTag(Tag t) async {
    await _repo.deleteTag(t.id);
    await editedTag();
  }
}
