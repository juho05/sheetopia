import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/settings/logging.dart';

class SettingsRepository {
  final LoggingSettings logging;

  SettingsRepository({required KeyValueRepository keyValueRepository})
    : logging = LoggingSettings(keyValueRepository: keyValueRepository) {
    load();
  }

  Future<void> load() async {
    Log.debug("loading settings from db");
    await logging.load();
  }

  void dispose() {
    logging.dispose();
  }
}
