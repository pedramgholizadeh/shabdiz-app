import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import '../../data/models/movie.dart';
import '../../data/models/screening.dart';
import '../../data/repositories/movie_repository.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/poster_image.dart';
import '../../widgets/status_pill.dart';

class MovieDetailPage extends ConsumerWidget {
  const MovieDetailPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(movieDetailProvider(slug));

    return Scaffold(
      body: detail.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (error, _) => _DetailError(
          message: apiErrorMessage(error),
          onRetry: () => ref.invalidate(movieDetailProvider(slug)),
        ),
        data: (data) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 360,
              backgroundColor: AppColors.background,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
              title: const BrandMark(compact: true),
              flexibleSpace: FlexibleSpaceBar(
                background: _Backdrop(movie: data.movie),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              sliver: SliverList.list(
                children: [
                  _TitleBlock(movie: data.movie),
                  const SizedBox(height: 20),
                  _Ratings(movie: data.movie),
                  const SizedBox(height: 22),
                  Text(
                    'داستان',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.movie.synopsis.isEmpty
                        ? 'توضیحی برای این فیلم ثبت نشده است.'
                        : data.movie.synopsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'سانس‌های پخش',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (data.screenings.isEmpty)
                    const Text(
                      'سانسی برای این فیلم ثبت نشده است.',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: AppColors.muted,
                      ),
                    )
                  else
                    ...data.screenings.map(
                      (screening) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ScreeningRow(screening: screening),
                      ),
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

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final url = movie.backdropUrl.isEmpty ? movie.coverUrl : movie.backdropUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url.isNotEmpty)
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => const ColoredBox(
              color: AppColors.surface,
            ),
          )
        else
          const ColoredBox(color: AppColors.surface),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xAA08080C),
                Color(0x6608080C),
                AppColors.background,
              ],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PosterImage(url: movie.coverUrl, width: 92, height: 132, radius: 16),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movie.titleFa,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 26,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                movie.titleEn,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (movie.year > 0) _MetaChip(label: '${movie.year}'),
                  if (movie.durationSeconds > 0)
                    _MetaChip(label: movie.durationLabel),
                  if (movie.director.isNotEmpty)
                    _MetaChip(label: movie.director),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 11,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _Ratings extends StatelessWidget {
  const _Ratings({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (movie.imdbRating != null)
          _RatingBadge(
            label: 'IMDb',
            value: movie.imdbRating!.toStringAsFixed(1),
          ),
        if (movie.imdbRating != null) const SizedBox(width: 10),
        if (movie.rottenTomatoesRating > 0)
          _RatingBadge(
            label: 'Rotten',
            value: '${movie.rottenTomatoesRating}%',
          ),
        const Spacer(),
        ...movie.genres.take(2).map(
              (genre) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _MetaChip(label: genre),
              ),
            ),
      ],
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreeningRow extends StatelessWidget {
  const _ScreeningRow({required this.screening});

  final Screening screening;

  @override
  Widget build(BuildContext context) {
    final live = screening.isLive;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: live
              ? AppColors.live.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                screening.startsAtJalali.isEmpty
                    ? Dates.jalaliDate(screening.startsAtUtc)
                    : screening.startsAtJalali,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                screening.startsAtLabel.isEmpty
                    ? Dates.clock(screening.startsAtUtc)
                    : screening.startsAtLabel,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(status: screening.status),
              const SizedBox(height: 6),
              if (live)
                SizedBox(
                  height: 30,
                  child: FilledButton(
                    onPressed: () => context.push('/watch/${screening.id}'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(96, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      textStyle: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('ورود به سالن'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 42, color: AppColors.muted),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  color: AppColors.muted,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 12),
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
        ),
      ),
    );
  }
}
