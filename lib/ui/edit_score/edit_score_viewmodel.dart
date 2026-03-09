import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:diacritic/diacritic.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/file_picker.dart';

class EditScoreViewModel extends ChangeNotifier {
  final ScoresRepository _repo;

  Score? _score;
  Score? get score => _score;

  StreamSubscription? _updatedScoresSub;

  late final Queue<String> _freshImports;
  bool get hasNext => _freshImports.isNotEmpty;

  late final bool isImport;

  EditScoreViewModel({required ScoresRepository repo, required scoreId})
    : _repo = repo {
    isImport = _repo.freshImports.isNotEmpty;
    _freshImports = Queue.of(_repo.freshImports.where((id) => id != scoreId));
    _repo.clearFreshImports();

    _load(scoreId).then((_) {
      _updatedScoresSub = _repo.updatedScoreIds
          .where((s) => s.contains(_score?.id))
          .listen((_) => _load(scoreId));
    });
  }

  Future<void> _load(String scoreId) async {
    final score = await _repo.getScore(scoreId);
    _score = score;
    // TODO properly handle score == null
    notifyListeners();
  }

  Future<void> delete() async {
    await _repo.deleteScore(score!.id);
  }

  Future<void> changeFile() async {
    final file = await selectScoreFile();
    if (file == null) return;
    await _repo.updateScoreFile(score!.id, file.path);
  }

  Future<void> next() async {
    if (!hasNext) return;
    _updatedScoresSub?.cancel();
    _updatedScoresSub = null;

    final scoreId = _freshImports.removeFirst();

    await _load(scoreId);
    _updatedScoresSub = _repo.updatedScoreIds
        .where((s) => s.any((id) => id == scoreId))
        .listen((_) => _load(scoreId));
  }

  Future<void> share({Rect? sharePositionOrigin}) async {
    if (score?.file == null) return;
    final fileName = _suggestedFileName();
    await SharePlus.instance.share(
      ShareParams(
        title: "Share score file",
        fileNameOverrides: [fileName],
        mailToFallbackEnabled: false,
        sharePositionOrigin: sharePositionOrigin,
        files: [
          XFile(
            score!.file!.path,
            mimeType: switch (score!.fileType) {
              FileType.pdf => "application/pdf",
            },
            name: fileName,
          ),
        ],
      ),
    );
  }

  Future<bool> save() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return saveMobile();
    }
    if (score?.file == null) return false;
    final FileSaveLocation? result = await getSaveLocation(
      suggestedName: _suggestedFileName(),
      acceptedTypeGroups: switch (score!.fileType) {
        FileType.pdf => [
          const XTypeGroup(
            label: "PDF",
            extensions: <String>["pdf"],
            mimeTypes: ["application/pdf"],
            uniformTypeIdentifiers: ["com.adobe.pdf"],
          ),
        ],
      },
    );
    if (result == null) return false;
    await XFile(score!.file!.path).saveTo(result.path);
    return true;
  }

  Future<bool> saveMobile() async {
    if (score?.file == null) return false;
    final bytes = await score!.file!.readAsBytes();
    final result = await fp.FilePicker.platform.saveFile(
      allowedExtensions: ["pdf"],
      type: fp.FileType.custom,
      dialogTitle: "Save score file",
      fileName: _suggestedFileName(),
      bytes: bytes,
    );
    return result != null;
  }

  String _suggestedFileName() {
    if (score?.file == null) "";
    var suggestedName = removeDiacritics(score!.title);
    suggestedName = suggestedName.replaceAll(RegExp(r'\s'), "_");
    suggestedName = suggestedName.replaceAll(RegExp(r'[^\w-]'), "");
    suggestedName += switch (score!.fileType) {
      FileType.pdf => ".pdf",
    };
    return suggestedName;
  }

  @override
  void dispose() {
    _updatedScoresSub?.cancel();
    super.dispose();
  }
}
