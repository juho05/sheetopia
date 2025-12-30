import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';
import 'package:sheetopia/data/services/sync/exceptions.dart';

class SyncDialogViewModel extends ChangeNotifier {
  final SyncRepository _repo;

  bool get signedIn => _repo.signedIn;

  bool _loading = false;
  bool get loading => _loading;

  String? _errorText;
  String? get errorText => _errorText;

  final form = FormGroup({
    "url": FormControl<String>(
      validators: [Validators.required, const _BaseUriValidator()],
    ),
    "user": FormControl<String>(validators: [Validators.required]),
    "password": FormControl<String>(validators: [Validators.required]),
  });

  SyncDialogViewModel({required SyncRepository repo}) : _repo = repo {
    repo.state.addListener(notifyListeners);
  }

  Future<void> login() async {
    assert(form.valid);
    _errorText = null;
    _loading = true;
    notifyListeners();
    try {
      final baseUri = Uri.parse(form.control("url").value.trim());

      final isValidUri = await _repo.isSheetopiaUri(baseUri);
      if (!isValidUri) {
        _errorText = "URL does not point to a sheetopia-sync server!";
        return;
      }

      await _repo.login(
        baseUri: baseUri,
        user: form.control("user").value.trim(),
        password: form.control("password").value.trim(),
      );
    } on UnauthenticatedException catch (_) {
      _errorText = "Invalid credentials!";
    } on DioException catch (e, st) {
      print("Connection failed: $e\n$st");
      _errorText = "Failed to connect to server!";
    } catch (e, st) {
      print("Connection failed: $e\n$st");
      _errorText = "An unexpected error occurred!";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _repo.state.removeListener(notifyListeners);
    super.dispose();
  }
}

class _BaseUriValidator extends Validator<dynamic> {
  const _BaseUriValidator();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    if (control.isNull || control.value is! String || control.value.isEmpty) {
      return {"baseUri": true};
    }
    final str = (control.value as String).trim();
    final uri = Uri.tryParse(str);
    if (uri == null) {
      return {"baseUri": true};
    }
    if (!uri.hasScheme ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return {"baseUri": true};
    }
    if (uri.scheme != "http" && uri.scheme != "https") {
      return {"baseUri": true};
    }
    return null;
  }
}
