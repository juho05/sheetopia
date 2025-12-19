import 'package:drift/drift.dart';

class ScoresTable extends Table {
  late final id = text()();
  late final title = text()();
  late final composer = text().nullable()();

  late final createdAt = dateTime().withDefault(currentDateAndTime)();
  late final metadataUpdatedAt = dateTime().withDefault(currentDateAndTime)();
  late final fileUpdatedAt = dateTime().withDefault(currentDateAndTime)();

  late final downloaded = boolean()();
  late final fileType = textEnum<FileType>()();

  @override
  Set<Column<Object>>? get primaryKey => {id};

  @override
  String? get tableName => "scores";
}

enum FileType { pdf }

FileType? fileTypeFromExtension(String ext) {
  ext = ext.toLowerCase();
  if (ext == ".pdf") {
    return FileType.pdf;
  }
  return null;
}

String fileTypeToExtension(FileType fileType) {
  return switch (fileType) {
    FileType.pdf => ".pdf",
  };
}
