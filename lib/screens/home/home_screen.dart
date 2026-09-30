import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/notification_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/prayer_time_tile.dart';
import '../location/location_picker_screen.dart';
import '../more/notification_settings_screen.dart';
import 'widgets/countdown_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      context.read<PrayerProvider>().ensureFresh(_now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();
    final today = provider.today(_now);
    final current = provider.currentPrayer(_now);
    final next = provider.nextPrayer(_now);

    // Kaydırma yok: içerik her ekran boyuna sığacak şekilde yerleşir.
    final height = MediaQuery.sizeOf(context).height;
    final compact = height < 720;
    final tiny = height < 640;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, compact ? 8 : 12, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              locationLabel: provider.location.label,
              hijri: today?.hijriLong,
              date: _now,
              showSlogan: !tiny,
            ),
            SizedBox(height: compact ? 10 : 18),
            if (today == null)
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ErrorView(
                        message:
                            provider.error ?? 'Bugünün vakitleri bulunamadı.',
                        onRetry: provider.load,
                      ),
              )
            else ...[
              if (provider.error != null) ...[
                const InfoBanner(
                  icon: Icons.wifi_off_rounded,
                  text: 'Çevrimdışı: kayıtlı vakitler gösteriliyor.',
                ),
                const SizedBox(height: 8),
              ],

              if (next != null)
                CountdownCard(
                  current: current,
                  next: next,
                  now: _now,
                  compact: compact,
                  minimal: tiny,
                ),
              SizedBox(height: compact ? 10 : 20),
              if (!tiny) const SectionTitle('Bugünün Vakitleri'),
              // Altı vakit kalan alanı paylaşır (satır başına en fazla 64 px).
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final gap = compact ? 6.0 : 8.0;
                    final tileHeight = math.min(
                      64.0,
                      (constraints.maxHeight - gap * 5) / 6,
                    );
                    return Column(
                      children: [
                        for (final (i, moment) in today.moments.indexed) ...[
                          if (i > 0) SizedBox(height: gap),
                          SizedBox(
                            height: tileHeight,
                            child: PrayerTimeTile(
                              moment: moment,
                              isActive: current != null &&
                                  current.type == moment.type &&
                                  current.time == moment.time,
                              isPast: !moment.time.isAfter(_now),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.locationLabel,
    required this.hijri,
    required this.date,
    this.showSlogan = true,
  });

  final String locationLabel;
  final String? hijri;
  final DateTime date;
  final bool showSlogan;

  @override
  Widget build(BuildContext context) {
    final notificationsOn =
        context.select<NotificationProvider, bool>((n) => n.settings.enabled);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. satır: marka + bildirim düğmesi
        Row(
          children: [
            const KibleLogo(size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 24,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (showSlogan)
                    Text(
                      AppConstants.slogan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: AppColors.beigeMuted, fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.anthracite,
              shape: CircleBorder(
                side: BorderSide(color: AppColors.gold.withValues(alpha: 0.35)),
              ),
              child: IconButton(
                tooltip: 'Ezan bildirimleri',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen(),
                )),
                icon: Icon(
                  notificationsOn
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: AppColors.gold,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 2. satır: konum (solda) + tarih (sağ kenara yaslı)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: LocationPill(
                label: locationLabel,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const LocationPickerScreen(),
                )),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.dayMonthWeekday(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.beige,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hijri != null)
                    Text(
                      hijri!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: AppColors.beigeMuted, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
