import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/dates.dart';
import '../data/models/screening.dart';
import 'poster_image.dart';
import 'status_pill.dart';

class ScreeningCard extends StatelessWidget {
  const ScreeningCard({super.key, required this.screening, required this.onTap});

  final Screening screening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final movie = screening.movie;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface, Color(0xFF0E0E16)],
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PosterImage(
                url: movie.coverUrl,
                width: 86,
                height: 124,
                radius: 14,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusPill(status: screening.status),
                        const Spacer(),
                        Text(
                          screening.startsAtJalali,
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      movie.titleFa,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      movie.titleEn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 14, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Text(
                          screening.startsAtLabel.isEmpty
                              ? Dates.clock(screening.startsAtUtc)
                              : screening.startsAtLabel,
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (movie.imdbRating != null) ...[
                          const Icon(Icons.star_rounded,
                              size: 14, color: AppColors.gold),
                          const SizedBox(width: 3),
                          Text(
                            movie.imdbRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
