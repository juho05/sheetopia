import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';

Future<List<SingleChildWidget>> createProviders() async {
  final database = Database();

  return [
    Provider.value(value: database),
    Provider(create: (context) => ScoresRepository(db: context.read())),
  ];
}
