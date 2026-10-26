import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'sidebar_navigation.dart';
import '../theme/glass_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Ambient cinematic backdrop behind the glass layers
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.85, -0.65),
          radius: 1.6,
          colors: [
            Color(0xFF2A0A12),
            GlassTheme.bgDeep,
          ],
          stops: [0.0, 0.55],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            SidebarNavigation(router: GoRouter.of(context)),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
