import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/movies_screen.dart';
import '../screens/series_screen.dart';
import '../screens/search_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/countries_screen.dart';
import '../screens/livetv_screen.dart';
import '../screens/gate_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/app_shell.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/favorites_sync.dart';

/// Bootstrap executed while the gate splash is visible:
/// restore session token (so repositories are authenticated) and register
/// this installation as a device (login is optional).
Future<void> _bootstrap() async {
  // Restore any saved session so ApiClient carries the token.
  await AuthService().restoreSession();
  await DeviceService.instance.register();
  await FavoritesSync.pullAndMerge();
  await DeviceService.instance.register();
  await FavoritesSync.pullAndMerge();
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/gate',
  routes: <RouteBase>[
    GoRoute(
      path: '/gate',
      builder: (context, state) => GateScreen(
        init: _bootstrap,
        onReady: () => GoRouter.of(context).go('/movies'),
      ),
    ),
    GoRoute(path: '/', redirect: (_, __) => '/movies'),
    GoRoute(
      path: '/movies',
      builder: (BuildContext context, GoRouterState state) {
        return AppShell(child: const MoviesScreen());
      },
    ),
    GoRoute(
      path: '/series',
      builder: (BuildContext context, GoRouterState state) {
        return AppShell(child: const SeriesScreen());
      },
    ),
    GoRoute(
      path: '/search',
      builder: (BuildContext context, GoRouterState state) {
        return AppShell(child: const SearchScreen());
      },
    ),
    GoRoute(
      path: '/favorites',
      builder: (BuildContext context, GoRouterState state) {
        return AppShell(child: const FavoritesScreen());
      },
    ),
    GoRoute(
      path: '/countries',
      builder: (BuildContext context, GoRouterState state) {
        return AppShell(child: const CountriesScreen());
      },
    ),
    GoRoute(
      path: '/livetv',
      builder: (BuildContext context, GoRouterState state) {
        return AppShell(child: const LiveTvScreen());
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return AppShell(child: const SettingsScreen());
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (BuildContext context, GoRouterState state) {
        return AppShell(child: const ProfileScreen());
      },
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
  ],
);
