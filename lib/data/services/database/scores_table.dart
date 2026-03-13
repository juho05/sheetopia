import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart';

@TableIndex(name: "search_text_index", columns: {#searchText})
class ScoresTable extends Table {
  late final id = text()();
  late final title = text()();
  late final composer = text().nullable()();
  late final notes = text().nullable()();
  late final searchText = text()();

  late final metadataUpdatedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();
  late final fileUpdatedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();

  late final metadataUploaded = boolean().withDefault(const Constant(false))();
  late final fileUploaded = boolean().withDefault(const Constant(false))();
  late final fileDownloaded = boolean()();

  late final fileType = textEnum<FileType>()();

  @override
  Set<Column<Object>>? get primaryKey => {id};

  @override
  String? get tableName => "scores";
}

enum FileType {
  @JsonValue("pdf")
  pdf,
}

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
