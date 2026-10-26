import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../navigation/app_screens.dart';
import '../theme/glass_theme.dart';
import '../theme/glass_widgets.dart';
import '../config.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Floating liquid-glass sidebar — Apple TV style rail over the content.
class SidebarNavigation extends StatelessWidget {
  final GoRouter router;

  const SidebarNavigation({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final String currentRoute = GoRouterState.of(context).uri.toString();
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    Widget item(AppScreen screen, {bool active = false}) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => router.go(screen.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: active
                ? LinearGradient(
                    colors: [
                      GlassTheme.accent.withValues(alpha: 0.28),
                      GlassTheme.accent.withValues(alpha: 0.10),
                    ],
                  )
                : null,
            border: Border.all(
              color: active
                  ? GlassTheme.accent.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.04),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(screen.icon,
                  size: 22,
                  color: active ? Colors.white : GlassTheme.textMuted),
              const SizedBox(width: 12),
              Text(
                screen.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? Colors.white : GlassTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: GlassPanel(
        borderRadius: 28,
        opacity: 0.07,
        child: SizedBox(
          width: 232,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand
                Padding(
                  padding: const EdgeInsets.only(bottom: 22, right: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: GlassTheme.accentGradient,
                          boxShadow: [
                            BoxShadow(
                              color: GlassTheme.accent.withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.star_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppConfig.appName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final screen in AppScreen.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: item(
                              screen,
                              active: currentRoute.startsWith(screen.route),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // User chip
                if (user != null)
                  GlassPanel(
                    borderRadius: 18,
                    opacity: 0.05,
                    blur: 12,
                    child: ListTile(
                      dense: true,
                      onTap: () => router.go('/settings'),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: GlassTheme.accentSecondary.withValues(alpha: 0.25),
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name.characters.first
                              : user.email.characters.first.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      title: Text(
                        user.name.isNotEmpty ? user.name : 'کاربر شبدیز',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, color: GlassTheme.textMuted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
