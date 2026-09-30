import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/prayer_times.dart';

/// Ana sayfadaki büyük kart: o anki vakit, sıradaki vakit ve kalan süre sayacı.
class CountdownCard extends StatelessWidget {
  const CountdownCard({
    super.key,
    required this.current,
    required this.next,
    required this.now,
    this.compact = false,
    this.minimal = false,
  });

  final PrayerMoment? current;
  final PrayerMoment next;
  final DateTime now;

  /// Kısa ekranlarda daha sıkı yerleşim.
  final bool compact;

  /// Çok kısa ekranlarda ipucu satırı ve ilerleme çubuğu gizlenir.
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final remaining = next.time.difference(now);
    final progress = _progress();

    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(20, 14, 20, 14)
          : const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Şu anki vakit sola, sıradaki vakit sağ kenara yaslı.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: _Label(
                  caption: 'Şu anki vakit',
                  value: current?.type.label ?? '—',
                  icon: current?.type.icon,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: _Label(
                  caption: 'Sıradaki vakit',
                  value: '${next.type.label}  ${Formatters.time(next.time)}',
                  alignEnd: true,
                ),
              ),
            ],
          ),
          SizedBox(height: minimal ? 4 : (compact ? 10 : 26)),
          Center(
            child: Column(
              children: [
                Text(
                  'Kalan süre',
                  style: TextStyle(
                    color: AppColors.beige.withValues(alpha: 0.8),
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  child: Text(
                    Formatters.countdown(remaining),
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: minimal ? 38 : (compact ? 44 : 56),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (!minimal) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${next.type.label} vaktine ${Formatters.humanDuration(remaining)}',
                    style: TextStyle(
                      color: AppColors.beige.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: minimal ? 8 : (compact ? 12 : 20)),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: minimal ? 4 : 6,
              backgroundColor: AppColors.navy.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  /// İçinde bulunulan vaktin ne kadarının geçtiği (0–1).
  double? _progress() {
    final start = current?.time;
    if (start == null) return null;
    final total = next.time.difference(start).inSeconds;
    if (total <= 0) return null;
    return (now.difference(start).inSeconds / total).clamp(0.0, 1.0);
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.caption,
    required this.value,
    this.icon,
    this.alignEnd = false,
  });

  final String caption;
  final String value;
  final IconData? icon;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          caption,
          style: TextStyle(
            color: AppColors.beige.withValues(alpha: 0.75),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.gold, size: 20),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.beige,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
