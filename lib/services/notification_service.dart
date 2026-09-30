import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Planlanacak tek bir bildirim.
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.utcTime,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime utcTime;
  final String title;
  final String body;
}

/// Yerel bildirimleri (Android / iOS) yöneten ince katman.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  /// iOS en fazla 64 bekleyen bildirime izin verir.
  static const int iosPendingLimit = 60;
  static const int androidPendingLimit = 300;

  static const _channelId = 'ezan_vakti';
  static const _channelName = 'Ezan vakitleri';
  static const _channelDescription =
      'Namaz vakti girdiğinde bildirim gönderir.';

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      color: Color(0xFF0E5A5F),
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    ),
  );

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  int get pendingLimit => defaultTargetPlatform == TargetPlatform.iOS
      ? iosPendingLimit
      : androidPendingLimit;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    if (!isSupported || _initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // İzin, kullanıcı bildirimleri açtığında istenir.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  /// Bildirim iznini ister. Android'de ayrıca tam zamanlı alarm izni istenir
  /// (verilmezse bildirimler birkaç dakika gecikmeli gelebilir).
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await init();

    final android = _android;
    if (android != null) {
      final granted = await android.requestNotificationsPermission() ?? false;
      if (granted && !(await canScheduleExact())) {
        await android.requestExactAlarmsPermission();
      }
      return granted;
    }
    return await _ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  Future<bool> canScheduleExact() async {
    final android = _android;
    if (android == null) return true;
    return await android.canScheduleExactNotifications() ?? false;
  }

  /// Bekleyen tüm bildirimleri silip verilenleri planlar. Planlanan sayıyı döner.
  Future<int> replaceAll(List<PlannedNotification> notifications) async {
    if (!isSupported) return 0;
    await init();
    await _plugin.cancelAll();

    final now = DateTime.now().toUtc();
    final upcoming = notifications
        .where((n) => n.utcTime.isAfter(now))
        .take(pendingLimit)
        .toList();
    if (upcoming.isEmpty) return 0;

    final mode = await canScheduleExact()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (final n in upcoming) {
      await _plugin.zonedSchedule(
        id: n.id,
        scheduledDate: tz.TZDateTime.from(n.utcTime, tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: mode,
        title: n.title,
        body: n.body,
      );
    }
    return upcoming.length;
  }

  Future<void> cancelAll() async {
    if (!isSupported) return;
    await init();
    await _plugin.cancelAll();
  }

  Future<void> showNow({required String title, required String body}) async {
    if (!isSupported) return;
    await init();
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }
}
