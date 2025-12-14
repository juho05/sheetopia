import 'package:go_router/go_router.dart';
import 'package:sheetopia/ui/home/home_page.dart';
import 'package:sheetopia/ui/score/score_page.dart';

final goRouter = GoRouter(
  restorationScopeId: "router",
  initialLocation: "/",
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: '/scores/:scoreId',
          builder: (context, state) =>
              ScorePage(scoreId: state.pathParameters["scoreId"]!),
        ),
      ],
    ),
  ],
);
