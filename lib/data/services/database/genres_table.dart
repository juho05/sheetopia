import 'package:drift/drift.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';

class GenresTable extends Table {
  late final score = text().references(
    ScoresTable,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();
  late final genre = text()();

  @override
  String? get tableName => "genres";

  @override
  Set<Column<Object>>? get primaryKey => {score, genre};
}
