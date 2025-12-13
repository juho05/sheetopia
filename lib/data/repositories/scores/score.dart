import 'dart:io';

import 'package:sheetopia/data/services/database/scores_table.dart';

class Score {
  final String id;
  final String title;

  final DateTime createdAt;
  final DateTime metadataUpdatedAt;
  final DateTime fileUpdatedAt;

  final FileType fileType;
  final File? file;

  Score({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.metadataUpdatedAt,
    required this.fileUpdatedAt,
    required this.fileType,
    required this.file,
  });
}
