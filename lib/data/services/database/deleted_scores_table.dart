import 'package:drift/drift.dart';

class DeletedScoresTable extends Table {
  late final scoreId = text()();
  late final deletedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();

  @override
  String? get tableName => "deleted_scores";

  @override
  Set<Column<Object>>? get primaryKey => {scoreId};
}
