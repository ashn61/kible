import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/prayer_times.dart';

/// Vakit listesindeki tek satır. Aktif vakit altın sarısı ile vurgulanır.
class PrayerTimeTile extends StatelessWidget {
  const PrayerTimeTile({
    super.key,
    required this.moment,
    this.isActive = false,
    this.isPast = false,
  });

  final PrayerMoment moment;
  final bool isActive;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final Color fg = isActive
        ? AppColors.navy
        : isPast
            ? AppColors.beige.withValues(alpha: 0.45)
            : AppColors.beige;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      // Yükseklik ebeveynden gelir (ana sayfada ekrana göre hesaplanır).
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: isActive ? AppColors.gold : AppColors.anthracite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(moment.type.icon,
              color: isActive ? AppColors.navy : AppColors.gold, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              moment.type.label,
              style: TextStyle(
                color: fg,
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Şimdi',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          Text(
            Formatters.time(moment.time),
            style: TextStyle(
              color: fg,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
