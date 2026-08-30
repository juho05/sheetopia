/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

abstract class ScoreFileView {
  void nextPage();

  void prevPage();
}

class ScoreFileViewController {
  ScoreFileView? _view;

  void attach(ScoreFileView view) => _view = view;

  void detach(ScoreFileView view) {
    if (identical(_view, view)) _view = null;
  }

  void nextPage() => _view?.nextPage();

  void prevPage() => _view?.prevPage();
}
