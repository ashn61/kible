import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/notification_settings.dart';
import '../../models/prayer_times.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/common.dart';
import 'sub_page_scaffold.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final settings = provider.settings;

    return SubPageScaffold(
      title: 'Ezan Bildirimleri',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!provider.isSupported) ...[
            const InfoBanner(
              icon: Icons.notifications_off_outlined,
              text: 'Bildirimler yalnızca Android ve iOS uygulamasında '
                  'kullanılabilir.',
            ),
            const SizedBox(height: 16),
          ],
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SwitchListTile(
              value: settings.enabled,
              activeThumbColor: AppColors.gold,
              title: const Text(
                'Vakit bildirimleri',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                settings.enabled
                    ? '${provider.scheduledCount} bildirim planlandı'
                    : 'Namaz vakti girdiğinde bildirim alın',
                style: TextStyle(color: AppColors.beigeMuted, fontSize: 12),
              ),
              onChanged: provider.isSupported
                  ? (on) => _toggle(context, provider, on)
                  : null,
            ),
          ),
          if (provider.supportsOngoing) ...[
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SwitchListTile(
                value: settings.ongoing,
                activeThumbColor: AppColors.gold,
                title: const Text(
                  'Bildirim panelinde göster',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Sıradaki vakte geri sayan kalıcı bildirim',
                  style: TextStyle(color: AppColors.beigeMuted, fontSize: 12),
                ),
                onChanged: (on) async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (!await provider.setOngoing(on)) {
                    messenger.showSnackBar(const SnackBar(
                      content: Text('Bildirim izni verilmedi.'),
                    ));
                  }
                },
              ),
            ),
          ],
          if (settings.enabled && !provider.exactAlarms) ...[
            const SizedBox(height: 12),
            const InfoBanner(
              icon: Icons.alarm_off,
              text: 'Tam zamanlı alarm izni verilmedi; bildirimler birkaç '
                  'dakika gecikebilir. Ayarlar › Uygulamalar › Kıble › '
                  'Alarmlar ve hatırlatıcılar bölümünden açabilirsiniz.',
            ),
          ],
          const SizedBox(height: 24),
          const SectionTitle('Vakitler'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final type in PrayerType.values)
                  SwitchListTile(
                    value: settings.prayers.contains(type),
                    activeThumbColor: AppColors.gold,
                    secondary: Icon(type.icon, color: AppColors.gold),
                    title: Text(type.label),
                    subtitle: type == PrayerType.gunes
                        ? Text(
                            'Sabah namazının son vakti',
                            style: TextStyle(
                              color: AppColors.beigeMuted,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    onChanged: settings.enabled
                        ? (on) => provider.togglePrayer(type, on)
                        : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Önceden hatırlat'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final minutes in NotificationSettings.reminderOptions)
                ChoiceChip(
                  label: Text(minutes == 0 ? 'Kapalı' : '$minutes dk önce'),
                  selected: settings.minutesBefore == minutes,
                  selectedColor: AppColors.teal,
                  backgroundColor: AppColors.anthracite,
                  side: BorderSide(color: AppColors.beigeFaint),
                  labelStyle: TextStyle(
                    color: settings.minutesBefore == minutes
                        ? AppColors.gold
                        : AppColors.beige,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: settings.enabled
                      ? (_) => provider.setMinutesBefore(minutes)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: const BorderSide(color: AppColors.gold),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: settings.enabled ? provider.sendTest : null,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Test bildirimi gönder'),
          ),
          const SizedBox(height: 16),
          Text(
            'Bildirimler, uygulama her açıldığında önümüzdeki günler için '
            'yeniden planlanır. Uygulamayı ara sıra açmanız yeterlidir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.beigeMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    NotificationProvider provider,
    bool on,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.setEnabled(on);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(
        content: Text(
          'Bildirim izni verilmedi. Cihaz ayarlarından izin verebilirsiniz.',
        ),
      ));
    }
  }
}
