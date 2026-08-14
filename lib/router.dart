import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const MapScreen(),
    ),
  ],
);
