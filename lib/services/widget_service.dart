import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../core/utils/formatters.dart';
import '../models/prayer_times.dart';

/// Ana ekran widget'ı (Android / iOS), iOS Bildirim Merkezi / kilit ekranı
/// widget'ları ve Android'deki kalıcı "sıradaki vakit" bildirimi için veriyi
/// yerel tarafa aktarır.
///
/// Yerel taraf sıradaki vakti ve geri sayımı bu veriden kendisi hesaplar;
/// böylece uygulama açılmadan da ~30 gün boyunca doğru çalışır.
class WidgetService {
  /// iOS: Runner ve KibleWidget hedeflerinde tanımlı App Group.
  static const String appGroupId = 'group.com.kible.kible';

  /// iOS WidgetKit `kind` değeri.
  static const String iOSWidgetName = 'KibleWidget';

  static const String dataKey = 'kible_data';
  static const String ongoingKey = 'kible_ongoing';

  static const MethodChannel _native = MethodChannel('kible/native');

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (!isSupported) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await HomeWidget.setAppGroupId(appGroupId);
    }
  }

  /// Vakitleri ve ayarları yerel tarafa yazar ve widget'ları yeniler.
  Future<void> sync({
    required List<DailyPrayerTimes> days,
    required String locationLabel,
    required bool ongoingNotification,
  }) async {
    if (!isSupported) return;
    await HomeWidget.saveWidgetData<String>(
      dataKey,
      jsonEncode(buildPayload(days, locationLabel, DateTime.now())),
    );
    await HomeWidget.saveWidgetData<bool>(ongoingKey, ongoingNotification);

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Widget'ları, kalıcı bildirimi ve bir sonraki vakit alarmını yeniler.
      await _native.invokeMethod<void>('refresh');
    } else {
      await HomeWidget.updateWidget(iOSName: iOSWidgetName);
    }
  }

  /// Yerel tarafın okuduğu JSON:
  /// `{"location": "...", "names": [...], "days": [{"d": "2026-09-30",
  ///   "h": "19 Rebiülahir 1448", "t": [epochMs × 6], "l": ["04:45", ...]}]}`
  @visibleForTesting
  static Map<String, dynamic> buildPayload(
    List<DailyPrayerTimes> days,
    String locationLabel,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final dateKey = DateFormat('yyyy-MM-dd');
    return {
      'location': locationLabel,
      'names': [for (final type in PrayerType.values) type.label],
      'days': [
        // Dünden itibaren: gece yarısından sonra "şu anki vakit" dünkü yatsıdır.
        for (final day in days)
          if (!day.date.isBefore(today.subtract(const Duration(days: 1))))
            {
              'd': dateKey.format(day.date),
              'h': day.hijriLong,
              't': [
                for (final type in PrayerType.values)
                  day.utcTimeOf(type).millisecondsSinceEpoch,
              ],
              'l': [
                for (final type in PrayerType.values)
                  Formatters.time(day.timeOf(type)),
              ],
            },
      ],
    };
  }
}
