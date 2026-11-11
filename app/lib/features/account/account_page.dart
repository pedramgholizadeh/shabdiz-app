import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/breakpoints.dart';
import '../../data/models/user.dart';
import '../../data/models/watch_history_item.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/poster_image.dart';

/// The user panel: identity, watch history and account actions. Future
/// features (preferences, reminders, …) hang off this page.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 12),
                const Row(
                  children: [
                    BackButton(),
                    Spacer(),
                    BrandMark(compact: true),
                  ],
                ),
                const SizedBox(height: 24),
                _IdentityCard(user: user),
                const SizedBox(height: 14),
                if (user == null)
                  FilledButton(
                    onPressed: () => context.push('/auth'),
                    child: const Text('ورود با ایمیل'),
                  )
                else if (user.isGuest)
                  FilledButton(
                    onPressed: () => context.push('/auth'),
                    child: const Text('ورود با ایمیل'),
                  )
                else
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.live,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).logout();
                      ref.read(currentUserProvider.notifier).set(null);
                      ref.invalidate(watchHistoryProvider);
                      if (context.mounted) context.go('/timeline');
                    },
                    child: const Text('خروج از حساب'),
                  ),
                const SizedBox(height: 28),
                if (user != null) ...[
                  Text('تماشاهای اخیر',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const _HistoryList(),
                ] else ...[
                  const _GuestHint(),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    // A local copy so null-promotion works below (class fields don't promote).
    final account = user;
    final isGuest = account?.isGuest ?? true;
    final hasEmail = account != null && account.email.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.surfaceAlt,
            child: Icon(
              isGuest
                  ? Icons.person_outline_rounded
                  : Icons.person_rounded,
              size: 28,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        account == null
                            ? 'کاربر مهمان'
                            : (account.name.isEmpty
                                ? 'کاربر شب‌دیز'
                                : account.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    if (isGuest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                          'مهمان',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasEmail ? account.email : 'برای ذخیره تماشاها و امکانات بیشتر وارد شوید',
                  textDirection: hasEmail ? TextDirection.ltr : null,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestHint extends StatelessWidget {
  const _GuestHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        color: AppColors.surface,
      ),
      child: const Row(
        children: [
          Icon(Icons.history_rounded, size: 22, color: AppColors.muted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'به‌عنوان مهمان تماشا می‌کنید. با ورود، سابقه تماشای همین دستگاه به حسابتان منتقل می‌شود.',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                height: 1.9,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(watchHistoryProvider);
    return history.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          apiErrorMessage(error),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            height: 1.8,
            color: AppColors.muted,
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.movie_filter_outlined,
                    size: 20, color: AppColors.muted),
                SizedBox(width: 8),
                Text(
                  'هنوز تماشایی ثبت نشده است.',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (final item in items)
              _HistoryTile(
                item: item,
                onTap: () => context.push('/movie/${item.movieSlug}'),
              ),
          ],
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item, required this.onTap});

  final WatchHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PosterImage(
              url: item.coverUrl,
              width: 56,
              height: 80,
              radius: 12,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.movieTitleFa,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      if (item.completed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: AppColors.gold.withValues(alpha: 0.14),
                          ),
                          child: const Text(
                            'کامل تماشا شد',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 10,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.startsAtLabel,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: item.percent / 100,
                          minHeight: 4,
                          backgroundColor: AppColors.border,
                          color: item.completed
                              ? AppColors.success
                              : AppColors.gold,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${item.percent}٪',
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
