/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

/// True once the app is on its way out. Closing a window disposes the widget
/// tree just like leaving a page does, state that should survive the app has to
/// tell the two apart.
bool appIsClosing = false;
