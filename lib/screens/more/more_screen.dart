import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';
import '../location/location_picker_screen.dart';
import 'dua_screen.dart';
import 'notification_settings_screen.dart';
import 'religious_calendar_screen.dart';
import 'tesbih_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Kaydırma yok; kısa ekranlarda "Hakkında" kartı gizlenir.
    final compact = MediaQuery.sizeOf(context).height < 720;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Daha Fazla',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.beige,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => GridView(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent:
                        ((constraints.maxHeight - 12) / 2).clamp(0, 168),
                  ),
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    _FeatureTile(
                      icon: Icons.menu_book_outlined,
                      title: 'Dualar',
                      subtitle: 'Günlük dualar ve anlamları',
                      page: DuaScreen(),
                    ),
                    _FeatureTile(
                      icon: Icons.touch_app_outlined,
                      title: 'Tesbihat',
                      subtitle: 'Dijital zikirmatik',
                      page: TesbihScreen(),
                    ),
                    _FeatureTile(
                      icon: Icons.event_note_outlined,
                      title: 'İbadet Takvimi',
                      subtitle: 'Kandiller ve mübarek günler',
                      page: ReligiousCalendarScreen(),
                    ),
                    _FeatureTile(
                      icon: Icons.location_city_outlined,
                      title: 'Konum',
                      subtitle: 'İl / ilçe değiştir',
                      page: LocationPickerScreen(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NotificationSettingsScreen(),
              )),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ezan Bildirimleri',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Vakit girince ve öncesinde hatırlatma',
                          style: TextStyle(
                            color: AppColors.beigeMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.beigeMuted),
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 12),
              AppCard(
                child: Row(
                  children: [
                    const KibleLogo(size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '${AppConstants.appName} v1.0.0',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${AppConstants.slogan}\nVakitler: Diyanet İşleri Başkanlığı '
                            '(ezanvakti.emushaf.net)',
                            style: TextStyle(
                              color: AppColors.beigeMuted,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Kısa kartlarda alt başlık gizlenir, ikon küçülür.
          final roomy = constraints.maxHeight >= 110;
          final iconBox = roomy ? 44.0 : 36.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.gold, size: iconBox * 0.55),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              if (roomy) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.beigeMuted, fontSize: 12),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
