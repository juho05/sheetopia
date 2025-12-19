import 'package:drift/drift.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';

class TagsTable extends Table {
  late final id = text()();
  late final name = text()();
  late final color = integer()();
  late final updatedAt = dateTime().withDefault(currentDateAndTime)();

  @override
  String? get tableName => "tags";

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class ScoreTagsTable extends Table {
  late final score = text().references(
    ScoresTable,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();
  late final tag = text().references(
    TagsTable,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();

  @override
  String? get tableName => "score_tags";

  @override
  Set<Column<Object>>? get primaryKey => {score, tag};
}
