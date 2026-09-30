import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/formatters.dart';
import '../models/notification_settings.dart';
import '../models/prayer_times.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import 'prayer_provider.dart';

/// Ezan vakti bildirimlerinin ayarlarını tutar; vakitler ya da ayarlar
/// değiştikçe bildirimleri yeniden planlar ve widget'ları / kalıcı bildirimi
/// günceller.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({
    required NotificationService service,
    required StorageService storage,
    WidgetService? widgets,
  })  : _service = service,
        _storage = storage,
        _widgets = widgets ?? WidgetService(),
        _settings = storage.loadNotificationSettings();

  final NotificationService _service;
  final StorageService _storage;
  final WidgetService _widgets;
  String? _widgetSignature;

  NotificationSettings _settings;
  PrayerProvider? _prayer;
  String? _scheduledSignature;
  int _scheduledCount = 0;
  bool _exactAlarms = true;
  bool _busy = false;
  bool _disposed = false;

  NotificationSettings get settings => _settings;
  bool get isSupported => _service.isSupported;
  int get scheduledCount => _scheduledCount;

  /// Android'de tam zamanlı alarm izni yoksa bildirimler gecikebilir.
  bool get exactAlarms => _exactAlarms;
  bool get isBusy => _busy;

  /// [PrayerProvider] her değiştiğinde çağrılır (ChangeNotifierProxyProvider).
  void attach(PrayerProvider prayer) {
    _prayer = prayer;
    // Build sırasında çağrılabilir; planlamayı bir sonraki mikro göreve ertele.
    scheduleMicrotask(_rescheduleIfNeeded);
    scheduleMicrotask(_syncWidgetsIfNeeded);
  }

  /// Android'de kalıcı bildirim desteklenir (iOS'ta widget'lar Bildirim
  /// Merkezi'nde gösterilir).
  bool get supportsOngoing =>
      _widgets.isSupported && defaultTargetPlatform == TargetPlatform.android;

  /// Kalıcı "sıradaki vakit" bildirimini açar/kapatır.
  Future<bool> setOngoing(bool on) async {
    if (on && !await _service.requestPermission()) return false;
    await _update(_settings.copyWith(ongoing: on));
    return true;
  }

  Future<void> _syncWidgetsIfNeeded() async {
    final prayer = _prayer;
    if (_disposed || !_widgets.isSupported || prayer == null) return;
    final days = prayer.days;
    final signature = [
      _settings.ongoing,
      prayer.location.label,
      if (days.isNotEmpty) ...[days.first.date, days.last.date],
    ].join('|');
    if (signature == _widgetSignature) return;
    _widgetSignature = signature;
    try {
      await _widgets.sync(
        days: days,
        locationLabel: prayer.location.label,
        ongoingNotification: _settings.ongoing,
      );
    } on Object catch (e) {
      debugPrint('Widget güncelleme hatası: $e');
    }
  }

  /// Bildirimleri açar/kapatır. Açarken izin istenir; verilmezse `false` döner.
  Future<bool> setEnabled(bool enabled) async {
    if (enabled && !await _service.requestPermission()) {
      return false;
    }
    await _update(_settings.copyWith(enabled: enabled));
    return true;
  }

  Future<void> togglePrayer(PrayerType type, bool on) {
    final prayers = {..._settings.prayers};
    on ? prayers.add(type) : prayers.remove(type);
    return _update(_settings.copyWith(prayers: prayers));
  }

  Future<void> setMinutesBefore(int minutes) =>
      _update(_settings.copyWith(minutesBefore: minutes));

  Future<void> sendTest() => _service.showNow(
        title: '🕌 Kıble',
        body: 'Bildirimler çalışıyor. Vakit girdiğinde haber vereceğiz.',
      );

  Future<void> _update(NotificationSettings next) async {
    _settings = next;
    _notify();
    await _storage.saveNotificationSettings(next);
    await _syncWidgetsIfNeeded();
    await _rescheduleIfNeeded();
  }

  Future<void> _rescheduleIfNeeded() async {
    final prayer = _prayer;
    if (_disposed || !_service.isSupported || prayer == null) return;

    final days = prayer.days;
    final signature = _signatureFor(prayer);
    if (signature == _scheduledSignature || _busy) return;

    _busy = true;
    _notify();
    try {
      if (!_settings.enabled || days.isEmpty) {
        await _service.cancelAll();
        _scheduledCount = 0;
      } else {
        _exactAlarms = await _service.canScheduleExact();
        _scheduledCount = await _service.replaceAll(
          buildPlan(days, _settings, prayer.location.label),
        );
      }
    } on Object catch (e) {
      debugPrint('Bildirim planlama hatası: $e');
    } finally {
      // Hata olsa da işaretle: aynı girdiyle sonsuz yeniden deneme olmasın.
      _scheduledSignature = signature;
      _busy = false;
      _notify();
    }

    // Planlama sürerken ayarlar değiştiyse tekrar dene.
    if (!_disposed && _signatureFor(prayer) != _scheduledSignature) {
      await _rescheduleIfNeeded();
    }
  }

  String _signatureFor(PrayerProvider prayer) {
    final days = prayer.days;
    return [
      _settings.signature,
      prayer.location.districtId,
      if (days.isNotEmpty) ...[days.first.date, days.last.date],
    ].join('|');
  }

  /// Verilen günler ve ayarlar için planlanacak bildirimleri üretir (saf
  /// fonksiyon; test edilebilir).
  @visibleForTesting
  static List<PlannedNotification> buildPlan(
    List<DailyPrayerTimes> days,
    NotificationSettings settings,
    String locationLabel,
  ) {
    final plan = <PlannedNotification>[];
    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      for (final type in PrayerType.values) {
        if (!settings.prayers.contains(type)) continue;
        final utc = day.utcTimeOf(type);
        final clock = Formatters.time(day.timeOf(type));

        if (settings.minutesBefore > 0) {
          plan.add(PlannedNotification(
            id: i * 20 + type.index * 2 + 1,
            utcTime: utc.subtract(Duration(minutes: settings.minutesBefore)),
            title: '${type.label} vaktine ${settings.minutesBefore} dk',
            body: '$locationLabel için ${type.label.toLowerCase()} vakti '
                "$clock'da girecek.",
          ));
        }
        plan.add(PlannedNotification(
          id: i * 20 + type.index * 2,
          utcTime: utc,
          title: '🕌 ${type.label} Vakti',
          body: _bodyFor(type, clock, locationLabel),
        ));
      }
    }
    plan.sort((a, b) => a.utcTime.compareTo(b.utcTime));
    return plan;
  }

  static String _bodyFor(PrayerType type, String clock, String location) =>
      switch (type) {
        PrayerType.imsak =>
          '$location · $clock — İmsak vakti girdi, sabah namazı vakti başladı.',
        PrayerType.gunes =>
          '$location · $clock — Güneş doğdu, sabah namazı vakti sona erdi.',
        _ => '$location · $clock — ${type.label} ezanı vakti.',
      };

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
