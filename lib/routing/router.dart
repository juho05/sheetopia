/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:go_router/go_router.dart';
import 'package:sheetopia/data/repositories/logger/log_message.dart';
import 'package:sheetopia/ui/annotate/annotate_page.dart';
import 'package:sheetopia/ui/edit_score/edit_score_page.dart';
import 'package:sheetopia/ui/home/home_page.dart';
import 'package:sheetopia/ui/install_update/install_update_page.dart';
import 'package:sheetopia/ui/practice/edit_exercise_page.dart';
import 'package:sheetopia/ui/practice/edit_routine_page.dart';
import 'package:sheetopia/ui/practice/exercise_play_page.dart';
import 'package:sheetopia/ui/practice/exercises_page.dart';
import 'package:sheetopia/ui/practice/routine_detail_page.dart';
import 'package:sheetopia/ui/practice/routine_play_page.dart';
import 'package:sheetopia/ui/score/score_page.dart';
import 'package:sheetopia/ui/setlists/setlist_detail_page.dart';
import 'package:sheetopia/ui/setlists/setlist_play_page.dart';
import 'package:sheetopia/ui/settings/appearance_page.dart';
import 'package:sheetopia/ui/settings/appimage_page.dart';
import 'package:sheetopia/ui/settings/debug_page.dart';
import 'package:sheetopia/ui/settings/importexport_page.dart';
import 'package:sheetopia/ui/settings/logs/choose_log_session_page.dart';
import 'package:sheetopia/ui/settings/logs/log_details_page.dart';
import 'package:sheetopia/ui/settings/logs/logs_page.dart';
import 'package:sheetopia/ui/settings/midi/midi_device_page.dart';
import 'package:sheetopia/ui/settings/midi/midi_page.dart';
import 'package:sheetopia/ui/settings/settings_page.dart';
import 'package:sheetopia/ui/settings/version_checking_page.dart';

GoRouter? _goRouter;

bool _isSharingScheme(String scheme) =>
    scheme == "content" ||
    scheme == "file" ||
    scheme.startsWith("sharingmedia");

GoRouter get goRouter {
  _goRouter ??= GoRouter(
    restorationScopeId: "router",
    onEnter: (context, current, next, router) =>
        _isSharingScheme(next.uri.scheme) &&
            router.routerDelegate.currentConfiguration.isNotEmpty
        ? const Block.stop()
        : const Allow(),
    redirect: (context, state) =>
        _isSharingScheme(state.uri.scheme) ? "/" : null,
    onException: (context, state, router) => router.go("/"),
    initialLocation: "/",
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'scores/import',
            builder: (context, state) =>
                const EditScorePage(scoreId: null, importMode: true),
          ),
          GoRoute(
            path: 'scores/:scoreId',
            builder: (context, state) =>
                ScorePage(scoreId: state.pathParameters["scoreId"]!),
          ),
          GoRoute(
            path: 'scores/:scoreId/edit',
            builder: (context, state) => EditScorePage(
              scoreId: state.pathParameters["scoreId"]!,
              importMode: false,
            ),
            routes: [
              GoRoute(
                path: 'annotate',
                builder: (context, state) =>
                    AnnotatePage(scoreId: state.pathParameters["scoreId"]!),
              ),
            ],
          ),
          GoRoute(
            path: 'setlists/:setlistId',
            builder: (context, state) => SetlistDetailPage(
              setlistId: state.pathParameters["setlistId"]!,
            ),
            routes: [
              GoRoute(
                path: 'play',
                builder: (context, state) => SetlistPlayPage(
                  setlistId: state.pathParameters["setlistId"]!,
                  startIndex: int.tryParse(
                    state.uri.queryParameters["startIndex"] ?? "",
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: "practice/routines/create",
            builder: (context, state) => const EditRoutinePage(routineId: null),
          ),
          GoRoute(
            path: "practice/routines/:routineId/details",
            builder: (context, state) => RoutineDetailPage(
              routineId: state.pathParameters["routineId"]!,
            ),
            routes: [
              GoRoute(
                path: "edit",
                builder: (context, state) => EditRoutinePage(
                  routineId: state.pathParameters["routineId"],
                ),
              ),
              GoRoute(
                path: "play",
                builder: (context, state) => RoutinePlayPage(
                  routineId: state.pathParameters["routineId"]!,
                  startIndex: int.tryParse(
                    state.uri.queryParameters["startIndex"] ?? "",
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: "practice/routines/:routineId/edit",
            builder: (context, state) =>
                EditRoutinePage(routineId: state.pathParameters["routineId"]),
          ),
          GoRoute(
            path: "practice/exercises",
            builder: (context, state) => const ExercisesPage(),
            routes: [
              GoRoute(
                path: "create",
                builder: (context, state) => EditExercisePage(
                  exerciseId: null,
                  separate: state.uri.queryParameters["separate"] == "true",
                ),
                routes: [
                  GoRoute(
                    path: 'scores/:scoreId',
                    builder: (context, state) =>
                        AnnotatePage(scoreId: state.pathParameters["scoreId"]!),
                  ),
                ],
              ),
              GoRoute(
                path: ":exerciseId",
                builder: (context, state) => EditExercisePage(
                  exerciseId: state.pathParameters["exerciseId"],
                ),
                routes: [
                  GoRoute(
                    path: 'scores/:scoreId',
                    builder: (context, state) =>
                        AnnotatePage(scoreId: state.pathParameters["scoreId"]!),
                  ),
                  GoRoute(
                    path: 'play',
                    builder: (context, state) => ExercisePlayPage(
                      exerciseId: state.pathParameters["exerciseId"]!,
                    ),
                  ),
                ],
              ),
            ],
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
                path: "versionChecking",
                builder: (context, state) => const VersionCheckingPage(),
              ),
              GoRoute(
                path: "appimage",
                builder: (context, state) => const AppImagePage(),
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
        ],
      ),
    ],
  );
  return _goRouter!;
}
