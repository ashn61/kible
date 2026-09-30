import '../core/utils/hijri_calendar.dart';
import '../core/utils/lunar_calendar.dart';

class ReligiousDay {
  const ReligiousDay({
    required this.name,
    required this.date,
    required this.hijri,
    this.isNight = false,
  });

  final String name;
  final DateTime date;
  final HijriDate? hijri;

  /// Kandil gibi, gece (akşamdan itibaren) idrak edilen günler.
  final bool isNight;
}

/// Hicri takvime göre sabit dini gün ve geceler.
class _Rule {
  const _Rule(this.name, this.month, this.day, {this.isNight = false});

  final String name;
  final int month;
  final int day;
  final bool isNight;
}

abstract final class ReligiousDays {
  static const _rules = [
    _Rule('Hicri Yılbaşı', 1, 1),
    _Rule('Aşure Günü', 1, 10),
    _Rule('Mevlid Kandili', 3, 11, isNight: true),
    _Rule('Üç Ayların Başlangıcı', 7, 1),
    _Rule('Miraç Kandili', 7, 26, isNight: true),
    _Rule('Berat Kandili', 8, 14, isNight: true),
    _Rule('Ramazan Başlangıcı', 9, 1),
    _Rule('Kadir Gecesi', 9, 26, isNight: true),
    _Rule('Ramazan Bayramı (1. Gün)', 10, 1),
    _Rule('Kurban Bayramı Arifesi', 12, 9),
    _Rule('Kurban Bayramı (1. Gün)', 12, 10),
  ];

  /// [from] tarihinden itibaren [monthsAhead] ay içindeki dini günler.
  static List<ReligiousDay> upcoming(
    LunarHijriCalendar calendar, {
    required DateTime from,
    required HijriDate currentHijri,
    int monthsAhead = 12,
  }) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(start.year, start.month + monthsAhead, start.day);
    final result = <ReligiousDay>[];

    void add(String name, DateTime? date, {bool isNight = false}) {
      if (date == null) return;
      result.add(ReligiousDay(
        name: name,
        date: date,
        hijri: calendar.fromGregorian(date),
        isNight: isNight,
      ));
    }

    for (var year = currentHijri.year; year <= currentHijri.year + 1; year++) {
      for (final rule in _rules) {
        add(
          rule.name,
          calendar.toGregorian(year, rule.month, rule.day),
          isNight: rule.isNight,
        );
      }

      // Ramazan Bayramı arifesi: Şevval'in 1'inden bir önceki gün.
      final eid = calendar.toGregorian(year, 10, 1);
      add('Ramazan Bayramı Arifesi', eid?.subtract(const Duration(days: 1)));

      // Regaip Kandili: Recep ayının ilk cumasından önceki gece (perşembe).
      var firstFriday = calendar.toGregorian(year, 7, 1);
      if (firstFriday != null) {
        while (firstFriday!.weekday != DateTime.friday) {
          firstFriday = firstFriday.add(const Duration(days: 1));
        }
        add(
          'Regaip Kandili',
          firstFriday.subtract(const Duration(days: 1)),
          isNight: true,
        );
      }
    }

    return result
        .where((d) => !d.date.isBefore(start) && d.date.isBefore(end))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}
