/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/ui/home/sync_dialog_viewmodel.dart';

void main() {
  group("isLocalNetworkHost", () {
    test("accepts localhost, .local and unqualified names", () {
      expect(isLocalNetworkHost("localhost"), isTrue);
      expect(isLocalNetworkHost("sheetopia.local"), isTrue);
      expect(isLocalNetworkHost("Sheetopia.Local"), isTrue);
      expect(isLocalNetworkHost("nas"), isTrue);
    });

    test("accepts loopback, private and link-local addresses", () {
      expect(isLocalNetworkHost("127.0.0.1"), isTrue);
      expect(isLocalNetworkHost("10.0.0.5"), isTrue);
      expect(isLocalNetworkHost("172.16.0.1"), isTrue);
      expect(isLocalNetworkHost("172.31.255.254"), isTrue);
      expect(isLocalNetworkHost("192.168.1.10"), isTrue);
      expect(isLocalNetworkHost("169.254.1.1"), isTrue);
      expect(isLocalNetworkHost("::1"), isTrue);
      expect(isLocalNetworkHost("fe80::1"), isTrue);
      expect(isLocalNetworkHost("fd00::1"), isTrue);
    });

    test("rejects public hosts and addresses", () {
      expect(isLocalNetworkHost("sync.example.com"), isFalse);
      expect(isLocalNetworkHost("8.8.8.8"), isFalse);
      expect(isLocalNetworkHost("172.15.0.1"), isFalse);
      expect(isLocalNetworkHost("172.32.0.1"), isFalse);
      expect(isLocalNetworkHost("192.169.1.1"), isFalse);
      expect(isLocalNetworkHost("2001:4860:4860::8888"), isFalse);
      expect(isLocalNetworkHost(""), isFalse);
    });

    test("matches how Uri exposes hosts", () {
      expect(isLocalNetworkHost(Uri.parse("http://[::1]:8080").host), isTrue);
      expect(
        isLocalNetworkHost(Uri.parse("http://192.168.0.2:9000/x").host),
        isTrue,
      );
    });
  });
}
