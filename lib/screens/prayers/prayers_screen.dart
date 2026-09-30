import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/prayer_times.dart';
import '../../providers/prayer_provider.dart';
import '../../widgets/common.dart';

/// Vakit detayları (bugün) ve aylık vakit listesi.
class PrayersScreen extends StatelessWidget {
  const PrayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();
    final now = DateTime.now();
    final today = provider.today(now);

    return SafeArea(
      bottom: false,
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    flex: 3,
                    child: Text(
                      'Namaz Vakitleri',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.beige,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 2,
                    child: LocationPill(label: provider.location.label),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.anthracite,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: AppColors.gold,
                unselectedLabelColor: AppColors.beigeMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: const [Tab(text: 'Bugün'), Tab(text: 'Aylık')],
              ),
            ),
            Expanded(
              child: !provider.hasData
                  ? provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ErrorView(
                          message: provider.error ?? 'Veri bulunamadı.',
                          onRetry: provider.load,
                        )
                  : TabBarView(
                      children: [
                        today == null
                            ? ErrorView(
                                message: 'Bugünün vakitleri bulunamadı.',
                                onRetry: provider.load,
                              )
                            : _TodayDetails(day: today, now: now),
                        _MonthlyList(days: provider.days, now: now),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayDetails extends StatelessWidget {
  const _TodayDetails({required this.day, required this.now});

  final DailyPrayerTimes day;
  final DateTime now;

  static const Map<PrayerType, String> _descriptions = {
    PrayerType.imsak: 'Oruca başlama ve sabah namazı vaktinin girişi.',
    PrayerType.gunes: 'Güneşin doğuşu; sabah namazı vakti sona erer.',
    PrayerType.ogle: 'Güneşin tepe noktasından batıya meyletmesi.',
    PrayerType.ikindi: 'Gölge boyunun, cismin iki katına ulaşması.',
    PrayerType.aksam: 'Güneşin batışı; iftar vakti.',
    PrayerType.yatsi: 'Şafak kızıllığının kaybolması.',
  };

  @override
  Widget build(BuildContext context) {
    // Kaydırma yok: satırlar kalan alanı paylaşır, dar ekranda açıklamalar gizlenir.
    final tiny = MediaQuery.sizeOf(context).height < 640;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (day.moonImageUrl != null) ...[
                  ClipOval(
                    child: Image.network(
                      day.moonImageUrl!,
                      width: 40,
                      height: 40,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.brightness_2_outlined,
                        color: AppColors.gold,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.hijriLong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day.gregorianLong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.beigeMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (day.qiblaTime != null) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Kıble saati',
                        style: TextStyle(
                          color: AppColors.beigeMuted,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        day.qiblaTime!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: tiny ? 8 : 16),
          if (!tiny) const SectionTitle('Vakit Detayları'),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gap = tiny ? 5.0 : 8.0;
                final height =
                    math.min(84.0, (constraints.maxHeight - gap * 5) / 6);
                return Column(
                  children: [
                    for (final (i, moment) in day.moments.indexed) ...[
                      if (i > 0) SizedBox(height: gap),
                      SizedBox(
                        height: height,
                        child: _DetailTile(
                          moment: moment,
                          description: _descriptions[moment.type]!,
                          isPast: !moment.time.isAfter(now),
                          showDescription: height >= 68,
                          showStatus: height >= 50,
                          dense: height < 40,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.moment,
    required this.description,
    required this.isPast,
    required this.showDescription,
    required this.showStatus,
    this.dense = false,
  });

  final PrayerMoment moment;
  final String description;
  final bool isPast;
  final bool showDescription;
  final bool showStatus;

  /// Çok alçak satır: daha küçük yazı.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconBox = math.min(44.0, constraints.maxHeight - 12);
        return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  moment.type.icon,
                  color: AppColors.gold,
                  size: iconBox * 0.55,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moment.type.label,
                      style: TextStyle(
                        fontSize: dense ? 14 : 16,
                        height: dense ? 1.1 : null,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showDescription)
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.beigeMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.time(moment.time),
                    style: TextStyle(
                      fontSize: dense ? 15 : 18,
                      height: dense ? 1.1 : null,
                      fontWeight: FontWeight.w800,
                      color: AppColors.beige,
                    ),
                  ),
                  if (showStatus)
                    Text(
                      isPast ? 'Geçti' : 'Bekleniyor',
                      style: TextStyle(
                        fontSize: 11,
                        color: isPast ? AppColors.beigeMuted : AppColors.gold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthlyList extends StatelessWidget {
  const _MonthlyList({required this.days, required this.now});

  final List<DailyPrayerTimes> days;
  final DateTime now;

  static const _dateFlex = 5;
  static const _timeFlex = 4;

  @override
  Widget build(BuildContext context) {
    final todayIndex = days.indexWhere((d) => d.isSameDay(now));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 8, 30, 8),
          child: Row(
            children: [
              _cell('Tarih', flex: _dateFlex, header: true, alignStart: true),
              for (final type in PrayerType.values)
                _cell(type.label, flex: _timeFlex, header: true),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final day = days[i];
              final isToday = i == todayIndex;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.gold : AppColors.anthracite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: isToday ? AppColors.navy : AppColors.beige,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: _dateFlex,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Formatters.dayMonth(day.date),
                                style: const TextStyle(fontSize: 13)),
                            Text(
                              Formatters.weekdayShort(day.date),
                              style: TextStyle(
                                fontSize: 11,
                                color: isToday
                                    ? AppColors.navy
                                    : AppColors.beigeMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final type in PrayerType.values)
                        _cell(Formatters.time(day.timeOf(type)),
                            flex: _timeFlex),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _cell(
    String text, {
    required int flex,
    bool header = false,
    bool alignStart = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
        textAlign: alignStart ? TextAlign.start : TextAlign.center,
        style: header
            ? const TextStyle(
                fontSize: 11,
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              )
            : const TextStyle(
                fontSize: 12.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
      ),
    );
  }
}
