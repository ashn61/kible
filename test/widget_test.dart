import 'package:flutter_test/flutter_test.dart';
import 'package:kible/core/utils/hijri_calendar.dart';
import 'package:kible/core/utils/lunar_calendar.dart';
import 'package:kible/data/religious_days.dart';
import 'package:kible/models/notification_settings.dart';
import 'package:kible/models/prayer_times.dart';
import 'package:kible/providers/notification_provider.dart';
import 'package:kible/services/widget_service.dart';
import 'package:kible/services/qibla_service.dart';

Map<String, dynamic> _day(String date, String hijri) => {
      'MiladiTarihKisa': date,
      'MiladiTarihUzun': '',
      'HicriTarihKisa': hijri,
      'HicriTarihUzun': '',
      'Imsak': '05:29',
      'Gunes': '06:54',
      'Ogle': '13:06',
      'Ikindi': '16:28',
      'Aksam': '19:09',
      'Yatsi': '20:28',
      'KibleSaati': '11:31',
    };

void main() {
  group('DailyPrayerTimes', () {
    test('API kaydını doğru ayrıştırır', () {
      final d = DailyPrayerTimes.fromJson(_day('26.09.2026', '15.4.1448'));
      expect(d.date, DateTime(2026, 9, 26));
      expect(d.timeOf(PrayerType.ogle), DateTime(2026, 9, 26, 13, 6));
      expect(d.moments.map((m) => m.type), PrayerType.values);
    });
  });

  group('Bildirim planı', () {
    final day = DailyPrayerTimes.fromJson({
      ..._day('26.09.2026', '15.4.1448'),
      'GreenwichOrtalamaZamani': 3.0,
    });

    test('vakitler ilçenin saat dilimine göre UTC hesaplanır', () {
      // 13:06 (GMT+3) = 10:06 UTC
      expect(day.utcTimeOf(PrayerType.ogle), DateTime.utc(2026, 9, 26, 10, 6));
    });

    test('seçili vakitler ve hatırlatmalar planlanır', () {
      const settings = NotificationSettings(
        enabled: true,
        prayers: {PrayerType.ogle, PrayerType.aksam},
        minutesBefore: 15,
      );
      final plan = NotificationProvider.buildPlan([day], settings, 'Trabzon');
      expect(plan.length, 4);
      expect(plan.first.utcTime, DateTime.utc(2026, 9, 26, 9, 51));
      expect(plan.first.title, 'Öğle vaktine 15 dk');
      expect(plan[1].title, '🕌 Öğle Vakti');
      expect(plan.map((n) => n.id).toSet().length, plan.length);
    });

    test('widget verisi dünden itibaren günleri ve UTC zamanlarını içerir', () {
      final payload = WidgetService.buildPayload(
        [day],
        'Trabzon',
        DateTime(2026, 9, 26, 14),
      );
      final days = payload['days'] as List;
      expect(payload['location'], 'Trabzon');
      expect(days.single['d'], '2026-09-26');
      expect(
        (days.single['t'] as List)[2],
        DateTime.utc(2026, 9, 26, 10, 6).millisecondsSinceEpoch,
      );
      expect((days.single['l'] as List)[2], '13:06');
    });

    test('ayarlar JSON ile kaydedilip geri okunur', () {
      const s = NotificationSettings(
        enabled: true,
        prayers: {PrayerType.imsak},
        minutesBefore: 10,
      );
      final back = NotificationSettings.fromJson(s.toJson());
      expect(back.signature, s.signature);
    });
  });

  group('HijriCalendar', () {
    test('kalibrasyon referans günü birebir eşler', () {
      final cal = HijriCalendar.calibrate(
        DateTime(2026, 9, 26),
        const HijriDate(1448, 4, 15),
      );
      final h = cal.fromGregorian(DateTime(2026, 9, 26));
      expect([h.year, h.month, h.day], [1448, 4, 15]);
      expect(cal.toGregorian(1448, 4, 15), DateTime(2026, 9, 26));
    });

    test('miladi ↔ hicri dönüşümü tutarlı', () {
      final cal = HijriCalendar();
      for (var i = 0; i < 800; i += 7) {
        final g = DateTime(2026, 1, 1).add(Duration(days: i));
        final h = cal.fromGregorian(g);
        expect(cal.toGregorian(h.year, h.month, h.day), g);
      }
    });
  });

  group('LunarHijriCalendar', () {
    test('yeni ay (kavuşum) anları ±5 dk doğrulukta', () {
      // Referans: NASA/USNO ay evreleri (UTC).
      final expected = {
        DateTime.utc(2026, 2, 17, 12, 1): 0,
        DateTime.utc(2026, 9, 11, 3, 27): 0,
        DateTime.utc(2026, 10, 10, 15, 50): 0,
      };
      for (final ref in expected.keys) {
        final k = ((ref.year + (ref.month - 1) / 12 - 2000) * 12.3685).round();
        final candidates = [k - 1, k, k + 1].map(LunarHijriCalendar.newMoonUtc);
        final closest = candidates.reduce((a, b) =>
            a.difference(ref).abs() < b.difference(ref).abs() ? a : b);
        expect(closest.difference(ref).inMinutes.abs(), lessThan(5));
      }
    });

    test("Diyanet'in (API) ay başlangıcıyla uyumlu", () {
      // API: 26.09.2026 = 15.4.1448, 12.10.2026 = 1.5.1448
      final cal = LunarHijriCalendar.anchored(
        DateTime(2026, 9, 26),
        known: const HijriDate(1448, 4, 15),
      );
      expect(cal.toGregorian(1448, 5, 1), DateTime(2026, 10, 12));
      final h = cal.fromGregorian(DateTime(2026, 10, 12))!;
      expect([h.year, h.month, h.day], [1448, 5, 1]);
    });

    test('dini günler sıralı ve gelecekte', () {
      final today = DateTime(2026, 9, 30);
      const known = HijriDate(1448, 4, 19);
      final days = ReligiousDays.upcoming(
        LunarHijriCalendar.anchored(today, known: known),
        from: today,
        currentHijri: known,
      );
      expect(days, isNotEmpty);
      expect(days.first.date.isBefore(today), isFalse);
      expect(days.map((d) => d.name), contains('Ramazan Başlangıcı'));
    });
  });

  group('QiblaService', () {
    test('Trabzon için kıble yaklaşık güney', () {
      final b = QiblaService.qiblaBearing(QiblaService.fallback);
      expect(b, closeTo(180, 2));
      expect(QiblaService.directionName(b), 'Güney');
    });

    test('İstanbul için kıble güneydoğu (~151°)', () {
      final b = QiblaService.qiblaBearing(const Coordinates(41.0082, 28.9784));
      expect(b, closeTo(151, 2));
      expect(QiblaService.directionName(b), 'Güneydoğu');
    });
  });
}
