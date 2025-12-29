import 'package:drift/drift.dart';

class DeletedTagsTable extends Table {
  late final tagId = text()();
  late final deletedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();

  @override
  String? get tableName => "deleted_tags";

  @override
  Set<Column<Object>>? get primaryKey => {tagId};
}
