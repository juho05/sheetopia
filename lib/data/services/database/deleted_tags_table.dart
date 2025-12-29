import 'package:drift/drift.dart';

class DeletedTagsTable extends Table {
  late final tagId = text()();
  late final deletedAt = dateTime().withDefault(currentDateAndTime)();

  @override
  String? get tableName => "deleted_tags";

  @override
  Set<Column<Object>>? get primaryKey => {tagId};
}
