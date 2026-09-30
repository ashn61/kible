import 'dart:math' as math;

import 'hijri_calendar.dart';

/// Astronomik yeni ay (kavuşum) hesabına dayalı hicri takvim.
///
/// Kavuşum anı Jean Meeus, "Astronomical Algorithms" (Bölüm 49) ile ±1 dk
/// hassasiyetle hesaplanır. Hicri ayın ilk günü, Diyanet'in uyguladığı hilalin
/// dünyanın herhangi bir yerinde görülebilirliği ölçütüne yaklaşım olarak:
/// kavuşum UTC [_visibilityCutoffHour] öncesindeyse ertesi gün, sonrasındaysa
/// iki gün sonra kabul edilir. (2026 Ramazan, Ramazan Bayramı ve Kurban
/// Bayramı tarihleriyle birebir uyumludur.)
class LunarHijriCalendar {
  LunarHijriCalendar._(this._starts);

  static const int _visibilityCutoffHour = 8;

  /// Sıralı ay başlangıçları.
  final List<_MonthStart> _starts;

  /// [today] için bilinen hicri tarihe ([known], ör. API'den) göre ayları
  /// numaralandırır ve [monthsAhead] ay ileriye kadar tabloyu oluşturur.
  /// [known] yoksa aritmetik takvimden tahmin edilir.
  factory LunarHijriCalendar.anchored(
    DateTime today, {
    HijriDate? known,
    int monthsAhead = 26,
  }) {
    final day = DateTime(today.year, today.month, today.day);
    final anchor = known ?? HijriCalendar().fromGregorian(day);
    final anchorStart = day.subtract(Duration(days: anchor.day - 1));

    // Bilinen ay başlangıcına en yakın kavuşumu bul.
    var k = _lunationIndex(anchorStart);
    var best = k;
    var bestDiff = 1 << 30;
    for (var i = k - 2; i <= k + 2; i++) {
      final diff = _monthStartFor(i).difference(anchorStart).inDays.abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = i;
      }
    }
    k = best;

    final starts = <_MonthStart>[
      // İçinde bulunulan ay için bilinen (API) başlangıç kullanılır.
      _MonthStart(anchor.year, anchor.month, anchorStart),
    ];
    var year = anchor.year;
    var month = anchor.month;
    for (var i = 1; i <= monthsAhead; i++) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      starts.add(_MonthStart(year, month, _monthStartFor(k + i)));
    }
    return LunarHijriCalendar._(starts);
  }

  /// Tablo kapsamındaki hicri tarihin miladi karşılığı; kapsam dışıysa null.
  DateTime? toGregorian(int year, int month, int day) {
    for (final s in _starts) {
      if (s.year == year && s.month == month) {
        return DateTime(s.date.year, s.date.month, s.date.day + day - 1);
      }
    }
    return null;
  }

  /// Miladi tarihin hicri karşılığı; kapsam dışıysa null.
  HijriDate? fromGregorian(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    for (var i = _starts.length - 1; i >= 0; i--) {
      final s = _starts[i];
      if (!d.isBefore(s.date)) {
        if (i == _starts.length - 1) return null;
        return HijriDate(s.year, s.month, d.difference(s.date).inDays + 1);
      }
    }
    return null;
  }

  // --- Astronomi ---

  static int _lunationIndex(DateTime date) {
    final years = date.year + (date.month - 1) / 12 + (date.day - 1) / 365.25;
    return ((years - 2000) * 12.3685).round();
  }

  static DateTime _monthStartFor(int k) {
    final conjunction = newMoonUtc(k);
    final base = DateTime(conjunction.year, conjunction.month, conjunction.day);
    final offset = conjunction.hour < _visibilityCutoffHour ? 1 : 2;
    return DateTime(base.year, base.month, base.day + offset);
  }

  /// k. yeni ayın (2000 Ocak'tan itibaren) UTC anı.
  static DateTime newMoonUtc(int k) {
    final t = k / 1236.85;
    final t2 = t * t, t3 = t2 * t, t4 = t3 * t;

    var jde = 2451550.09766 +
        29.530588861 * k +
        0.00015437 * t2 -
        0.000000150 * t3 +
        0.00000000073 * t4;

    final e = 1 - 0.002516 * t - 0.0000074 * t2;
    final m = _rad(2.5534 + 29.10535670 * k - 0.0000014 * t2 - 0.00000011 * t3);
    final mp = _rad(201.5643 +
        385.81693528 * k +
        0.0107582 * t2 +
        0.00001238 * t3 -
        0.000000058 * t4);
    final f = _rad(160.7108 +
        390.67050284 * k -
        0.0016118 * t2 -
        0.00000227 * t3 +
        0.000000011 * t4);
    final om =
        _rad(124.7746 - 1.56375588 * k + 0.0020672 * t2 + 0.00000215 * t3);

    double s(double x) => math.sin(x);
    jde += -0.40720 * s(mp) +
        0.17241 * e * s(m) +
        0.01608 * s(2 * mp) +
        0.01039 * s(2 * f) +
        0.00739 * e * s(mp - m) -
        0.00514 * e * s(mp + m) +
        0.00208 * e * e * s(2 * m) -
        0.00111 * s(mp - 2 * f) -
        0.00057 * s(mp + 2 * f) +
        0.00056 * e * s(2 * mp + m) -
        0.00042 * s(3 * mp) +
        0.00042 * e * s(m + 2 * f) +
        0.00038 * e * s(m - 2 * f) -
        0.00024 * e * s(2 * mp - m) -
        0.00017 * s(om) -
        0.00007 * s(mp + 2 * m) +
        0.00004 * s(2 * mp - 2 * f) +
        0.00004 * s(3 * m) +
        0.00003 * s(mp + m - 2 * f) +
        0.00003 * s(2 * mp + 2 * f) -
        0.00003 * s(mp + m + 2 * f) +
        0.00003 * s(mp - m + 2 * f) -
        0.00002 * s(mp - m - 2 * f) -
        0.00002 * s(3 * mp + m) +
        0.00002 * s(4 * mp);

    // TT → UTC (ΔT ≈ 70 sn)
    const deltaTDays = 70 / 86400;
    final days = jde - deltaTDays - 2451545.0; // J2000.0 = 2000-01-01 12:00 UTC
    return DateTime.utc(2000, 1, 1, 12)
        .add(Duration(milliseconds: (days * 86400000).round()));
  }

  static double _rad(double deg) => (deg % 360) * math.pi / 180;
}

class _MonthStart {
  const _MonthStart(this.year, this.month, this.date);

  final int year;
  final int month;
  final DateTime date;
}
