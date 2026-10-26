import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/navigation/app_router.dart';
import 'src/providers/movie_provider.dart';
import 'src/providers/genre_provider.dart';
import 'src/providers/series_provider.dart';
import 'src/providers/seasons_provider.dart';
import 'src/providers/search_provider.dart';
import 'src/providers/countries_provider.dart';
import 'src/providers/tv_provider.dart';
import 'src/providers/auth_provider.dart';
import 'src/utils/theme_manager.dart';
import 'src/theme/glass_theme.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  MediaKit.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MovieProvider()),
        ChangeNotifierProvider(create: (_) => GenreProvider()),
        ChangeNotifierProvider(create: (_) => SeriesProvider()),
        ChangeNotifierProvider(create: (_) => SeasonsProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => CountriesProvider()),
        ChangeNotifierProvider(create: (_) => CountryMediaProvider()),
        ChangeNotifierProvider(create: (_) => TvProvider()),
      ],
      child: const ShabdizApp(),
    ),
  );
}

class ShabdizApp extends StatelessWidget {
  const ShabdizApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    return MaterialApp.router(
      title: 'شبدیز',
      theme: theme.lightTheme,
      darkTheme: GlassTheme.darkTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
  }
}
