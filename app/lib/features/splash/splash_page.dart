import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/brand_mark.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 1800)),
      _restoreSession(),
    ]);
    if (!mounted) return;
    // Signing in is never forced: guests land on the timeline too.
    context.go('/timeline');
  }

  Future<void> _restoreSession() async {
    final tokenStore = ref.read(tokenStoreProvider);
    final session = ref.read(currentUserProvider.notifier);
    final token = await tokenStore.readToken();
    // Instant identity from the local cache while /me validates the token.
    session.set(
        (token != null && token.isNotEmpty) ? await tokenStore.readUser() : null);
    try {
      session.set(await ref.read(authRepositoryProvider).me());
    } catch (_) {
      // Offline or server hiccup: keep the cached identity and continue.
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 1.1,
            colors: [Color(0xFF241C10), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final value = Curves.easeOutCubic.transform(_animation.value);
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 24 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(),
                  const SizedBox(height: 18),
                  const Text(
                    'سینمای هم‌زمان، هر شب',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      letterSpacing: 1.2,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: AppColors.border,
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
