/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/utils/week_start.dart';

void main() {
  test("the first weekday depends on the region", () {
    expect(firstWeekdayOfRegion("DE"), DateTime.monday);
    expect(firstWeekdayOfRegion("GB"), DateTime.monday);
    expect(firstWeekdayOfRegion("US"), DateTime.sunday);
    expect(firstWeekdayOfRegion("us"), DateTime.sunday);
    expect(firstWeekdayOfRegion("EG"), DateTime.saturday);
    expect(firstWeekdayOfRegion("MV"), DateTime.friday);
    expect(firstWeekdayOfRegion(null), DateTime.monday);
  });

  test("the region is read from a POSIX locale name", () {
    expect(regionOfPosixLocale("de_DE.UTF-8"), "DE");
    expect(regionOfPosixLocale("en_US"), "US");
    expect(regionOfPosixLocale("ca_ES@valencia"), "ES");
    expect(regionOfPosixLocale("C.UTF-8"), isNull);
    expect(regionOfPosixLocale("POSIX"), isNull);
    expect(regionOfPosixLocale(null), isNull);
  });

  test("LC_TIME wins over LANG and loses to LC_ALL", () {
    expect(
      posixTimeRegion({"LANG": "en_US.UTF-8", "LC_TIME": "de_DE.UTF-8"}),
      "DE",
    );
    expect(
      posixTimeRegion({
        "LANG": "en_US.UTF-8",
        "LC_TIME": "de_DE.UTF-8",
        "LC_ALL": "ja_JP.UTF-8",
      }),
      "JP",
    );
    expect(posixTimeRegion({"LANG": "en_US.UTF-8", "LC_ALL": ""}), "US");
    expect(posixTimeRegion({}), isNull);
  });

  testWidgets("date pickers start the week on the regional weekday", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_MondayDelegate()],
        home: Material(
          child: CalendarDatePicker(
            initialDate: DateTime(2026, 3, 11),
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
            onDateChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final context = tester.element(find.byType(CalendarDatePicker));
    expect(MaterialLocalizations.of(context).firstDayOfWeekIndex, 1);
    // March 2026 starts on a Sunday, the last column of a Monday based grid
    expect(
      tester.getCenter(find.text("1")).dx,
      greaterThan(tester.getCenter(find.text("2")).dx),
    );
  });
}

class _MondayDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _MondayDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      const RegionalMaterialLocalizations(firstWeekday: DateTime.monday);

  @override
  bool shouldReload(_MondayDelegate old) => false;
}
