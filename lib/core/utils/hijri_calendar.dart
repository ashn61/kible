/// Hicri takvim yardımcıları (aritmetik/tablo usulü).
///
/// Aritmetik takvim, Diyanet'in rü'yet/hesap esaslı takviminden ±1–2 gün
/// sapabilir. Bu yüzden [HijriCalendar.calibrate] ile API'den gelen günün
/// hicri tarihi referans alınarak fark düzeltilir.
class HijriDate {
  const HijriDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  /// "15.4.1448" → HijriDate
  static HijriDate? tryParse(String value) {
    final parts = value.split('.');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return HijriDate(y, m, d);
  }

  static const monthNames = [
    'Muharrem',
    'Safer',
    'Rebiülevvel',
    'Rebiülahir',
    'Cemaziyelevvel',
    'Cemaziyelahir',
    'Recep',
    'Şaban',
    'Ramazan',
    'Şevval',
    'Zilkade',
    'Zilhicce',
  ];

  String get monthName => monthNames[month - 1];

  @override
  String toString() => '$day $monthName $year';
}

class HijriCalendar {
  HijriCalendar({this.offsetDays = 0});

  /// Aritmetik takvime eklenecek gün farkı (kalibrasyon sonucu).
  final int offsetDays;

  static const int _islamicEpoch = 1948440; // 16 Temmuz 622 (JDN)

  /// Referans bir günün (miladi → hicri) bilinen karşılığına göre kalibre eder.
  factory HijriCalendar.calibrate(DateTime gregorian, HijriDate known) {
    final arithmeticJdn = _hijriToJdn(known.year, known.month, known.day);
    final actualJdn = _gregorianToJdn(gregorian);
    return HijriCalendar(offsetDays: actualJdn - arithmeticJdn);
  }

  HijriDate fromGregorian(DateTime date) =>
      _jdnToHijri(_gregorianToJdn(date) - offsetDays);

  DateTime toGregorian(int year, int month, int day) =>
      _jdnToGregorian(_hijriToJdn(year, month, day) + offsetDays);

  // --- Julian Day Number dönüşümleri ---

  static int _hijriToJdn(int year, int month, int day) =>
      day +
      (29.5 * (month - 1)).ceil() +
      (year - 1) * 354 +
      ((3 + 11 * year) ~/ 30) +
      _islamicEpoch -
      1;

  static HijriDate _jdnToHijri(int jdn) {
    final year = (30 * (jdn - _islamicEpoch) + 10646) ~/ 10631;
    final monthRaw = ((jdn - (29 + _hijriToJdn(year, 1, 1))) / 29.5).ceil() + 1;
    final month = monthRaw.clamp(1, 12);
    final day = jdn - _hijriToJdn(year, month, 1) + 1;
    return HijriDate(year, month, day);
  }

  static int _gregorianToJdn(DateTime date) {
    final a = (14 - date.month) ~/ 12;
    final y = date.year + 4800 - a;
    final m = date.month + 12 * a - 3;
    return date.day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  static DateTime _jdnToGregorian(int jdn) {
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - 146097 * b ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - 1461 * d ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + m ~/ 10;
    return DateTime(year, month, day);
  }
}
