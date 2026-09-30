import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/hijri_calendar.dart';
import '../../core/utils/lunar_calendar.dart';
import '../../data/religious_days.dart';
import '../../providers/prayer_provider.dart';
import '../../widgets/common.dart';
import 'sub_page_scaffold.dart';

/// Önümüzdeki 12 ayın kandil ve mübarek günleri.
class ReligiousCalendarScreen extends StatelessWidget {
  const ReligiousCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final known = _knownHijri(context.read<PrayerProvider>(), today);
    final calendar = LunarHijriCalendar.anchored(today, known: known);
    final days = ReligiousDays.upcoming(
      calendar,
      from: today,
      currentHijri: known ?? HijriCalendar().fromGregorian(today),
    );

    return SubPageScaffold(
      title: 'İbadet Takvimi',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const InfoBanner(
            text: 'Tarihler astronomik yeni ay hesabıyla belirlenir; Diyanet '
                'takvimiyle nadiren ±1 gün fark olabilir.',
          ),
          const SizedBox(height: 16),
          for (final day in days) ...[
            _DayTile(day: day, daysLeft: day.date.difference(today).inDays),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  /// API'den gelen bugünün (Diyanet) hicri tarihi.
  static HijriDate? _knownHijri(PrayerProvider provider, DateTime today) {
    final day = provider.today(today);
    return day == null ? null : HijriDate.tryParse(day.hijriShort);
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.daysLeft});

  final ReligiousDay day;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final soon = daysLeft <= 7;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: soon ? AppColors.gold : AppColors.teal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${day.date.day}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: soon ? AppColors.navy : AppColors.beige,
                  ),
                ),
                Text(
                  Formatters.dayMonth(day.date).split(' ').last,
                  style: TextStyle(
                    fontSize: 12,
                    color: soon ? AppColors.navy : AppColors.beige,
                  ),
                ),
              ],
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
                        day.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (day.isNight) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.nightlight_round,
                          size: 14, color: AppColors.gold),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    Formatters.fullDate(day.date),
                    if (day.hijri != null) day.hijri.toString(),
                  ].join('\n'),
                  style: TextStyle(
                    color: AppColors.beigeMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Text(
            daysLeft == 0 ? 'Bugün' : '$daysLeft gün',
            style: TextStyle(
              color: soon ? AppColors.gold : AppColors.beigeMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
