import 'package:go_router/go_router.dart';
import 'package:sheetopia/data/repositories/logger/log_message.dart';
import 'package:sheetopia/routing/loading_page.dart';
import 'package:sheetopia/ui/edit_score/edit_score_page.dart';
import 'package:sheetopia/ui/home/home_page.dart';
import 'package:sheetopia/ui/score/score_page.dart';
import 'package:sheetopia/ui/settings/appearance_page.dart';
import 'package:sheetopia/ui/settings/debug_page.dart';
import 'package:sheetopia/ui/settings/logs/choose_log_session_page.dart';
import 'package:sheetopia/ui/settings/logs/log_details_page.dart';
import 'package:sheetopia/ui/settings/logs/logs_page.dart';
import 'package:sheetopia/ui/settings/midi/midi_device_page.dart';
import 'package:sheetopia/ui/settings/midi/midi_page.dart';
import 'package:sheetopia/ui/settings/settings_page.dart';

GoRouter? _goRouter;

GoRouter get goRouter {
  _goRouter ??= GoRouter(
    restorationScopeId: "router",
    redirect: (context, state) {
      if (state.uri.scheme == "content") {
        return "/loading";
      }
      return null;
    },
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
            ],
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
