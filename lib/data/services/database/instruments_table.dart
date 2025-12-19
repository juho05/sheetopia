import 'package:drift/drift.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';

class InstrumentsTable extends Table {
  late final score = text().references(
    ScoresTable,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();
  late final instrument = text()();

  @override
  String? get tableName => "instruments";

  @override
  Set<Column<Object>>? get primaryKey => {score, instrument};
}
