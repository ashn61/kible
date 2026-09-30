import 'package:flutter/material.dart';

/// Günün altı vakti (sıralı).
enum PrayerType {
  imsak('İmsak', Icons.nights_stay_outlined),
  gunes('Güneş', Icons.wb_twilight),
  ogle('Öğle', Icons.wb_sunny_outlined),
  ikindi('İkindi', Icons.wb_cloudy_outlined),
  aksam('Akşam', Icons.brightness_4_outlined),
  yatsi('Yatsı', Icons.bedtime_outlined);

  const PrayerType(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Belirli bir vakit ve saati.
class PrayerMoment {
  const PrayerMoment(this.type, this.time);

  final PrayerType type;
  final DateTime time;
}

/// ezanvakti.emushaf.net `/vakitler/{ilceId}` yanıtındaki tek günlük kayıt.
class DailyPrayerTimes {
  const DailyPrayerTimes({
    required this.date,
    required this.gregorianLong,
    required this.hijriShort,
    required this.hijriLong,
    required this.moonImageUrl,
    required this.qiblaTime,
    required this.times,
    required this.raw,
    this.utcOffset,
  });

  /// Günün tarihi (saat 00:00, cihaz yerel saati).
  final DateTime date;

  /// Örn. "26 Eylül 2026 Cumartesi"
  final String gregorianLong;

  /// Örn. "15.4.1448"
  final String hijriShort;

  /// Örn. "15 Rebiulahir 1448"
  final String hijriLong;

  final String? moonImageUrl;

  /// Güneşin tam kıble yönünde olduğu saat ("HH:mm").
  final String? qiblaTime;

  final Map<PrayerType, DateTime> times;

  /// Vakitlerin ait olduğu saat dilimi (API: GreenwichOrtalamaZamani, ör. 3.0).
  final Duration? utcOffset;

  /// Önbelleğe yazmak için ham JSON.
  final Map<String, dynamic> raw;

  static const Map<PrayerType, String> _jsonKeys = {
    PrayerType.imsak: 'Imsak',
    PrayerType.gunes: 'Gunes',
    PrayerType.ogle: 'Ogle',
    PrayerType.ikindi: 'Ikindi',
    PrayerType.aksam: 'Aksam',
    PrayerType.yatsi: 'Yatsi',
  };

  factory DailyPrayerTimes.fromJson(Map<String, dynamic> json) {
    final date = _parseDate(json['MiladiTarihKisa'] as String);
    final times = <PrayerType, DateTime>{
      for (final entry in _jsonKeys.entries)
        entry.key: _combine(date, json[entry.value] as String),
    };

    return DailyPrayerTimes(
      date: date,
      gregorianLong: (json['MiladiTarihUzun'] as String?) ?? '',
      hijriShort: (json['HicriTarihKisa'] as String?) ?? '',
      hijriLong: (json['HicriTarihUzun'] as String?) ?? '',
      moonImageUrl: json['AyinSekliURL'] as String?,
      qiblaTime: json['KibleSaati'] as String?,
      times: times,
      raw: json,
      utcOffset: switch (json['GreenwichOrtalamaZamani']) {
        final num hours => Duration(minutes: (hours * 60).round()),
        _ => null,
      },
    );
  }

  Map<String, dynamic> toJson() => raw;

  DateTime timeOf(PrayerType type) => times[type]!;

  /// Vaktin UTC karşılığı. Cihazın saat dilimi, ilçenin saat diliminden farklı
  /// olsa bile bildirimler doğru anda gelir.
  DateTime utcTimeOf(PrayerType type) {
    final t = timeOf(type);
    final offset = utcOffset;
    if (offset == null) return t.toUtc();
    return DateTime.utc(t.year, t.month, t.day, t.hour, t.minute)
        .subtract(offset);
  }

  List<PrayerMoment> get moments =>
      [for (final type in PrayerType.values) PrayerMoment(type, timeOf(type))];

  bool isSameDay(DateTime other) =>
      date.year == other.year &&
      date.month == other.month &&
      date.day == other.day;

  /// "dd.MM.yyyy" → DateTime
  static DateTime _parseDate(String value) {
    final parts = value.split('.');
    if (parts.length != 3) {
      throw FormatException('Geçersiz tarih biçimi: $value');
    }
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  /// Tarih + "HH:mm" → DateTime
  static DateTime _combine(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) {
      throw FormatException('Geçersiz saat biçimi: $hhmm');
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
