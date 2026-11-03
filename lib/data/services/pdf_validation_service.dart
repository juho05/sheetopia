/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:pdfrx/pdfrx.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';

enum PdfValidity { valid, invalid, passwordProtected }

class PdfValidationService {
  const PdfValidationService();

  Future<PdfValidity> validate(String path) async {
    PdfDocument? pdf;
    try {
      pdf = await PdfDocument.openFile(path, useProgressiveLoading: true);
      return pdf.pages.isNotEmpty ? PdfValidity.valid : PdfValidity.invalid;
    } on PdfPasswordException catch (e) {
      Log.warn("Rejected password protected PDF $path", e: e);
      return PdfValidity.passwordProtected;
    } catch (e) {
      Log.warn("Rejected invalid PDF $path", e: e);
      return PdfValidity.invalid;
    } finally {
      await pdf?.dispose();
    }
  }
}
