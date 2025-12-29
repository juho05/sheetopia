import 'package:drift/drift.dart';

class DeletedScoresTable extends Table {
  late final scoreId = text()();
  late final deletedAt = dateTime().withDefault(currentDateAndTime)();

  @override
  String? get tableName => "deleted_scores";

  @override
  Set<Column<Object>>? get primaryKey => {scoreId};
}
