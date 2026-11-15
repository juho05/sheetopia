/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';

const _localNetworkPermissionSdk = 37;
const _lookupTimeout = Duration(seconds: 3);

Future<bool>? _pendingRequest;

bool isLocalNetworkAddress(InternetAddress address) {
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

// Android additionally blocks CGNAT, which ATS does not exempt.
bool isAndroidLocalNetworkAddress(InternetAddress address) {
  if (isLocalNetworkAddress(address)) return true;
  final bytes = address.rawAddress;
  return address.type == InternetAddressType.IPv4 &&
      bytes[0] == 100 &&
      (bytes[1] & 0xc0) == 64;
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
  return isLocalNetworkAddress(address);
}

// Android blocks the on-link prefix of every interface, which includes global
// IPv6 subnets. Interface prefix lengths are not exposed -> assume /64.
bool sharesIpv6Subnet(
  InternetAddress address,
  Iterable<InternetAddress> ownAddresses,
) {
  if (address.type != InternetAddressType.IPv6) return false;
  final bytes = address.rawAddress;
  return ownAddresses.any((own) {
    if (own.type != InternetAddressType.IPv6 || own.isLinkLocal) return false;
    final ownBytes = own.rawAddress;
    for (var i = 0; i < 8; i++) {
      if (bytes[i] != ownBytes[i]) return false;
    }
    return true;
  });
}

// Requests ACCESS_LOCAL_NETWORK when the uri likely targets the local network.
Future<void> requestLocalNetworkPermissionIfNeeded(Uri uri) async {
  if (!await localNetworkPermissionMissing(uri)) return;
  await (_pendingRequest ??= _request());
}

// Whether a failed connection to the uri may be caused by Android blocking
// local network access.
Future<bool> localNetworkPermissionMissing(Uri uri) async {
  if (!Platform.isAndroid) return false;
  try {
    final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    if (sdk < _localNetworkPermissionSdk) return false;
    if (!await _resolvesToLocalNetwork(uri.host)) return false;
    return !await Permission.accessLocalNetwork.isGranted;
  } catch (e, st) {
    Log.error("Failed to check local network permission", e: e, st: st);
    return false;
  }
}

Future<bool> _request() async {
  try {
    return (await Permission.accessLocalNetwork.request()).isGranted;
  } catch (e, st) {
    Log.error("Failed to request local network permission", e: e, st: st);
    return false;
  } finally {
    _pendingRequest = null;
  }
}

Future<bool> _resolvesToLocalNetwork(String host) async {
  List<InternetAddress> addresses;
  final literal = InternetAddress.tryParse(host);
  if (literal != null) {
    addresses = [literal];
  } else {
    try {
      addresses = await InternetAddress.lookup(host).timeout(_lookupTimeout);
    } on SocketException catch (_) {
      return isLocalNetworkHost(host);
    } on TimeoutException catch (_) {
      return isLocalNetworkHost(host);
    }
  }
  addresses = addresses.where((a) => !a.isLoopback).toList();
  if (addresses.any(isAndroidLocalNetworkAddress)) return true;
  if (!addresses.any((a) => a.type == InternetAddressType.IPv6)) return false;

  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv6,
  );
  final ownAddresses = interfaces.expand((i) => i.addresses).toList();
  return addresses.any((a) => sharesIpv6Subnet(a, ownAddresses));
}
