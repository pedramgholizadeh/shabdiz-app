import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shabdiz/core/theme/app_colors.dart';

import '../../features/account/account_page.dart';
import '../../features/auth/auth_page.dart';
import '../../features/movie/movie_detail_page.dart';
import '../../features/player/player_page.dart';
import '../../features/splash/splash_page.dart';
import '../../features/timeline/timeline_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: '/timeline',
      builder: (context, state) => const TimelinePage(),
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountPage(),
    ),
    GoRoute(
      path: '/movie/:slug',
      builder: (context, state) => MovieDetailPage(
        slug: state.pathParameters['slug'] ?? '',
      ),
    ),
    GoRoute(
      path: '/watch/:id',
      builder: (context, state) => PlayerPage(
        screeningId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
      ),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'صفحه پیدا نشد',
        style: const TextStyle(
          fontFamily: 'Vazirmatn',
          color: AppColors.text,
        ),
      ),
    ),
  ),
);
