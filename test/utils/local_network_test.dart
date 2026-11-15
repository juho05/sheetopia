/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/utils/local_network.dart';

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

    test("does not treat CGNAT as local", () {
      expect(isLocalNetworkHost("100.64.0.1"), isFalse);
      expect(isLocalNetworkHost("100.101.102.103"), isFalse);
    });

    test("treats CGNAT as local on Android", () {
      expect(
        isAndroidLocalNetworkAddress(InternetAddress("100.64.0.1")),
        isTrue,
      );
      expect(
        isAndroidLocalNetworkAddress(InternetAddress("100.127.255.254")),
        isTrue,
      );
      expect(
        isAndroidLocalNetworkAddress(InternetAddress("192.168.1.1")),
        isTrue,
      );
      expect(
        isAndroidLocalNetworkAddress(InternetAddress("100.63.255.255")),
        isFalse,
      );
      expect(
        isAndroidLocalNetworkAddress(InternetAddress("100.128.0.1")),
        isFalse,
      );
      expect(isAndroidLocalNetworkAddress(InternetAddress("8.8.8.8")), isFalse);
    });

    test("matches how Uri exposes hosts", () {
      expect(isLocalNetworkHost(Uri.parse("http://[::1]:8080").host), isTrue);
      expect(
        isLocalNetworkHost(Uri.parse("http://192.168.0.2:9000/x").host),
        isTrue,
      );
    });
  });

  group("sharesIpv6Subnet", () {
    final own = [
      InternetAddress("2001:db8:1:2::10"),
      InternetAddress("fe80::1"),
      InternetAddress("192.168.1.5"),
    ];

    test("matches addresses in the same /64", () {
      expect(
        sharesIpv6Subnet(InternetAddress("2001:db8:1:2::99"), own),
        isTrue,
      );
      expect(
        sharesIpv6Subnet(InternetAddress("2001:db8:1:2:ffff::1"), own),
        isTrue,
      );
    });

    test("rejects other subnets and IPv4", () {
      expect(
        sharesIpv6Subnet(InternetAddress("2001:db8:1:3::1"), own),
        isFalse,
      );
      expect(
        sharesIpv6Subnet(InternetAddress("fe80::2"), [
          InternetAddress("fe80::1"),
        ]),
        isFalse,
      );
      expect(sharesIpv6Subnet(InternetAddress("192.168.1.6"), own), isFalse);
    });
  });
}
