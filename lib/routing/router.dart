import 'package:go_router/go_router.dart';
import 'package:sheetopia/ui/home/home_page.dart';

final goRouter = GoRouter(
  restorationScopeId: "router",
  initialLocation: "/",
  routes: [GoRoute(path: '/', builder: (context, state) => const HomePage())],
);
