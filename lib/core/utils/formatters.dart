import 'package:intl/intl.dart';

abstract final class Formatters {
  static final DateFormat _hm = DateFormat('HH:mm');
  static final DateFormat _dayMonth = DateFormat('d MMM', 'tr_TR');
  static final DateFormat _weekdayShort = DateFormat('EEE', 'tr_TR');
  static final DateFormat _dayMonthWeekday =
      DateFormat('d MMMM, EEEE', 'tr_TR');
  static final DateFormat _fullDate = DateFormat('d MMMM y, EEEE', 'tr_TR');

  /// 13:06
  static String time(DateTime value) => _hm.format(value);

  /// 26 Eyl
  static String dayMonth(DateTime value) => _dayMonth.format(value);

  /// Cmt
  static String weekdayShort(DateTime value) => _weekdayShort.format(value);

  /// 30 Eylül, Çarşamba
  static String dayMonthWeekday(DateTime value) =>
      _dayMonthWeekday.format(value);

  /// 26 Eylül 2026, Cumartesi
  static String fullDate(DateTime value) => _fullDate.format(value);

  /// 02:14:09
  static String countdown(Duration value) {
    final d = value.isNegative ? Duration.zero : value;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  /// "2 sa 14 dk" / "14 dk" / "1 dk'dan az"
  static String humanDuration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes % 60;
    if (hours > 0) return '$hours sa $minutes dk';
    if (minutes > 0) return '$minutes dk';
    return "1 dk'dan az";
  }
}
