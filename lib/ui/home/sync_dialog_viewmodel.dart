/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';
import 'package:sheetopia/data/services/sync/exceptions.dart';

class SyncDialogViewModel extends ChangeNotifier {
  final SyncRepository _repo;

  bool get signedIn => _repo.signedIn;

  bool _loading = false;
  bool get loading => _loading;

  String? _errorText;
  String? get errorText => _errorText;

  String get user => _repo.user;
  String get server => _repo.serverUri.toString();

  SyncState get state => _repo.state.value;

  String? _lastSync;
  String? get lastSync => _lastSync;

  final form = FormGroup({
    "url": FormControl<String>(
      validators: [Validators.required, const _BaseUriValidator()],
    ),
    "user": FormControl<String>(validators: [Validators.required]),
    "password": FormControl<String>(validators: [Validators.required]),
  });

  SyncDialogViewModel({required SyncRepository repo}) : _repo = repo {
    repo.state.addListener(notifyListeners);
    repo.lastSync.addListener(_updateLastSync);
    _updateLastSync();
  }

  void _updateLastSync() {
    final dateTime = _repo.lastSync.value;
    if (dateTime == null) {
      _lastSync = null;
    } else {
      _lastSync = DateFormat("yyyy-MM-dd HH:mm:ss").format(dateTime.toLocal());
    }

    notifyListeners();
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
      Log.warn("Failed to connect to sync server", e: e, st: st);
      _errorText = "Failed to connect to server!";
    } catch (e, st) {
      Log.error(
        "Unexpected error while logging in to sync server",
        e: e,
        st: st,
      );
      _errorText = "An unexpected error occurred!";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repo.logout();
  }

  void syncNow() {
    _repo.syncNow();
  }

  @override
  void dispose() {
    _repo.lastSync.removeListener(_updateLastSync);
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
    if (uri.scheme == "http" &&
        (Platform.isIOS || Platform.isMacOS) &&
        !isLocalNetworkHost(uri.host)) {
      return {"insecureHttp": true};
    }
    return null;
  }
}

// Mirrors what App Transport Security exempts via NSAllowsLocalNetworking:
// localhost, .local and unqualified names, loopback, link-local and private ranges.
bool isLocalNetworkHost(String host) {
  final normalized = host.toLowerCase();
  if (normalized.isEmpty) {
    return false;
  }
  if (normalized == "localhost" || normalized.endsWith(".local")) {
    return true;
  }

  final address = InternetAddress.tryParse(normalized);
  if (address == null) {
    return !normalized.contains(".");
  }
  if (address.isLoopback || address.isLinkLocal) {
    return true;
  }

  final bytes = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) {
    return bytes[0] == 10 ||
        (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) ||
        (bytes[0] == 192 && bytes[1] == 168);
  }
  return (bytes[0] & 0xfe) == 0xfc;
}
