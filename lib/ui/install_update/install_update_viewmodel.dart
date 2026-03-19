import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sheetopia/data/repositories/auto_update/auto_update_repository.dart';

class InstallUpdateViewModel extends ChangeNotifier {
  final AutoUpdateRepository _repo;

  AutoUpdateStatus get status => _repo.status;
  ValueStream<double> get downloadProgress => _repo.downloadProgress;

  InstallUpdateViewModel({required AutoUpdateRepository autoUpdateRepository})
    : _repo = autoUpdateRepository {
    _repo.addListener(notifyListeners);
  }

  Future<void> installUpdate() async {
    await _repo.update();
  }

  @override
  void dispose() {
    _repo.removeListener(notifyListeners);
    super.dispose();
  }
}
