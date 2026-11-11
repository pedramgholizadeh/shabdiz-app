import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/breakpoints.dart';
import '../../data/repositories/movie_repository.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/screening_card.dart';

class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(timelineProvider);
    final user = ref.watch(currentUserProvider);
    final width = MediaQuery.sizeOf(context).width;
    final wide = isWide(width);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  const BrandMark(compact: true),
                  const Spacer(),
                  if (user == null)
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        backgroundColor: AppColors.surfaceAlt,
                        foregroundColor: AppColors.gold,
                        textStyle: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => context.push('/auth'),
                      child: const Text('ورود'),
                    )
                  else if (user.isGuest)
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        backgroundColor: AppColors.surfaceAlt,
                        foregroundColor: AppColors.gold,
                        textStyle: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => context.push('/auth'),
                      child: const Text('ورود با ایمیل'),
                    )
                  else
                    IconButton(
                      tooltip: 'حساب کاربری',
                      onPressed: () => context.push('/account'),
                      icon: const Icon(Icons.account_circle_rounded, size: 24),
                    ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                'برنامهٔ امشب',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'فیلم‌ها را انتخاب کن و سر ساعت، هم‌زمان با بقیه تماشا کن.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Expanded(
                child: timeline.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                  error: (error, _) => _ErrorState(
                    message: apiErrorMessage(error),
                    onRetry: () => ref.invalidate(timelineProvider),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const _EmptyState();
                    }
                    return RefreshIndicator(
                      color: AppColors.gold,
                      backgroundColor: AppColors.surface,
                      onRefresh: () => ref.refresh(timelineProvider.future),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth:
                                wide ? kMaxGridWidth : kMaxContentWidth,
                          ),
                          child: wide
                              ? GridView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 24),
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 420,
                                    mainAxisExtent: 176,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                  ),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final screening = items[index];
                                    return SizedBox(
                                      height: 176,
                                      child: ScreeningCard(
                                        screening: screening,
                                        onTap: () => context.push(
                                          '/movie/${screening.movie.slug}',
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding:
                                      const EdgeInsets.only(bottom: 24),
                                  itemCount: items.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final screening = items[index];
                                    return ScreeningCard(
                                      screening: screening,
                                      onTap: () => context.push(
                                        '/movie/${screening.movie.slug}',
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 90),
        Icon(Icons.nights_stay_rounded, size: 42, color: AppColors.muted),
        SizedBox(height: 16),
        Text(
          'هنوز فیلمی برای پخش برنامه‌ریزی نشده است.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.muted),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              color: AppColors.muted,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'تلاش دوباره',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
