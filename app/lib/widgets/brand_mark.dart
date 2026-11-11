import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 42,
          height: compact ? 34 : 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [AppColors.gold, AppColors.goldDeep],
            ),
            borderRadius: BorderRadius.circular(compact ? 10 : 13),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.25),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.movie_filter_rounded,
            color: AppColors.background,
            size: compact ? 19 : 23,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'شب‌دیز',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w700,
            fontSize: compact ? 19 : 23,
            color: AppColors.text,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}
