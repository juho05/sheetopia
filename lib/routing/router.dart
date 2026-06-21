/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetopia/data/repositories/logger/log_message.dart';
import 'package:sheetopia/routing/loading_page.dart';
import 'package:sheetopia/ui/edit_score/edit_score_page.dart';
import 'package:sheetopia/ui/home/home_page.dart';
import 'package:sheetopia/ui/install_update/install_update_page.dart';
import 'package:sheetopia/ui/score/score_page.dart';
import 'package:sheetopia/ui/settings/appearance_page.dart';
import 'package:sheetopia/ui/settings/debug_page.dart';
import 'package:sheetopia/ui/settings/importexport_page.dart';
import 'package:sheetopia/ui/settings/logs/choose_log_session_page.dart';
import 'package:sheetopia/ui/settings/logs/log_details_page.dart';
import 'package:sheetopia/ui/settings/logs/logs_page.dart';
import 'package:sheetopia/ui/settings/midi/midi_device_page.dart';
import 'package:sheetopia/ui/settings/midi/midi_page.dart';
import 'package:sheetopia/ui/settings/settings_page.dart';

GoRouter? _goRouter;

enum _ShareStatus { idle, importing, ready, empty }

class ShareImport {
  const ShareImport._(this._status, this.scoreId);

  const ShareImport.idle() : this._(_ShareStatus.idle, null);

  const ShareImport.importing() : this._(_ShareStatus.importing, null);

  const ShareImport.ready(String scoreId) : this._(_ShareStatus.ready, scoreId);

  const ShareImport.empty() : this._(_ShareStatus.empty, null);

  final _ShareStatus _status;
  final String? scoreId;
}

final ValueNotifier<ShareImport> shareImport = ValueNotifier(
  const ShareImport.idle(),
);

bool _isSharingScheme(String scheme) =>
    scheme == "content" ||
    scheme == "file" ||
    scheme.startsWith("sharingmedia");

GoRouter get goRouter {
  _goRouter ??= GoRouter(
    restorationScopeId: "router",
    refreshListenable: shareImport,
    redirect: (context, state) {
      final isShareLink = _isSharingScheme(state.uri.scheme);
      final atLoading = state.uri.path == "/loading";
      if (!isShareLink && !atLoading) {
        return null;
      }

      switch (shareImport.value._status) {
        case _ShareStatus.ready:
          return "/scores/${shareImport.value.scoreId}/edit";
        case _ShareStatus.empty:
          return "/";
        case _ShareStatus.idle:
        case _ShareStatus.importing:
          return atLoading ? null : "/loading";
      }
    },
    onException: (context, state, router) => router.go("/"),
    initialLocation: "/",
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'scores/:scoreId',
            builder: (context, state) =>
                ScorePage(scoreId: state.pathParameters["scoreId"]!),
          ),
          GoRoute(
            path: 'scores/:scoreId/edit',
            builder: (context, state) =>
                EditScorePage(scoreId: state.pathParameters["scoreId"]!),
          ),
          GoRoute(
            path: "settings",
            builder: (context, state) => const SettingsPage(),
            routes: [
              GoRoute(
                path: "midi",
                builder: (context, state) => const MidiPage(),
                routes: [
                  GoRoute(
                    path: "devices/:deviceId",
                    builder: (context, state) => MidiDevicePage(
                      deviceId: Uri.decodeComponent(
                        state.pathParameters["deviceId"]!,
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: "appearance",
                builder: (context, state) => const AppearancePage(),
              ),
              GoRoute(
                path: "debug",
                builder: (context, state) => const DebugPage(),
                routes: [
                  GoRoute(
                    path: "logs",
                    builder: (context, state) => const LogsPage(),
                    routes: [
                      GoRoute(
                        path: "details",
                        builder: (context, state) =>
                            LogDetailsPage(msg: state.extra! as LogMessage),
                      ),
                      GoRoute(
                        path: "session",
                        builder: (context, state) => ChooseLogSessionPage(
                          highlight: state.extra as DateTime?,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: "importExport",
                builder: (context, state) => const ImportExportPage(),
              ),
            ],
          ),
          GoRoute(
            path: "installUpdate",
            builder: (context, state) => const InstallUpdatePage(),
          ),
          GoRoute(
            path: "loading",
            builder: (context, state) => const LoadingPage(),
          ),
        ],
      ),
    ],
  );
  return _goRouter!;
}
