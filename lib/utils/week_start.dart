/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

// CLDR weekData, every other region starts on Monday
final _sundayRegions =
    "AG AS BD BR BS BT BW BZ CA CO DM DO ET GT GU HK HN ID IL IN JM JP KE KH "
            "KR LA MH MM MO MT MX MZ NI NP PA PE PH PK PR PT PY SA SG SV TH TT "
            "TW UM US VE VI WS YE ZA ZW"
        .split(" ")
        .toSet();
final _saturdayRegions = "AE AF BH DJ DZ EG IQ IR JO KW LY OM QA SD SY"
    .split(" ")
    .toSet();
const _fridayRegions = {"MV"};

final _posixRegion = RegExp(r"^[A-Za-z]{2,3}_([A-Za-z]{2})(?![A-Za-z])");

/// Returns a [DateTime.weekday] value.
int firstWeekdayOfRegion(String? region) {
  final code = region?.toUpperCase();
  if (_sundayRegions.contains(code)) return DateTime.sunday;
  if (_saturdayRegions.contains(code)) return DateTime.saturday;
  if (_fridayRegions.contains(code)) return DateTime.friday;
  return DateTime.monday;
}

/// Region of a locale name like `de_DE.UTF-8`.
String? regionOfPosixLocale(String? name) =>
    name == null ? null : _posixRegion.firstMatch(name)?.group(1);

/// Region of the first usable locale in [environment], following the POSIX
/// precedence for date formats.
String? posixTimeRegion(Map<String, String> environment) {
  for (final key in const ["LC_ALL", "LC_TIME", "LANG"]) {
    final value = environment[key];
    if (value == null || value.isEmpty) continue;
    return regionOfPosixLocale(value);
  }
  return null;
}

int systemFirstWeekday() {
  // the Linux embedder only reports the message language, not LC_TIME
  final region =
      (Platform.isLinux ? posixTimeRegion(Platform.environment) : null) ??
      PlatformDispatcher.instance.locale.countryCode;
  return firstWeekdayOfRegion(region);
}

/// English localizations with the week start of the system region.
class RegionalMaterialLocalizations extends DefaultMaterialLocalizations {
  final int firstWeekday;

  const RegionalMaterialLocalizations({required this.firstWeekday});

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _RegionalMaterialLocalizationsDelegate();

  @override
  int get firstDayOfWeekIndex => firstWeekday % 7;
}

class _RegionalMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _RegionalMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(
        RegionalMaterialLocalizations(firstWeekday: systemFirstWeekday()),
      );

  @override
  bool shouldReload(_RegionalMaterialLocalizationsDelegate old) => false;
}
