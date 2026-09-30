import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/location_models.dart';
import '../models/notification_settings.dart';
import '../models/prayer_times.dart';

/// Seçilen konumu ve son alınan vakitleri cihazda saklar
/// (uygulama çevrimdışıyken de vakitler gösterilebilsin diye).
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static const _kDistrictId = 'location.districtId';
  static const _kDistrictName = 'location.districtName';
  static const _kCityName = 'location.cityName';
  static const _kCachePrefix = 'prayerCache.';
  static const _kTesbihCount = 'tesbih.count';
  static const _kNotifications = 'notifications.settings';

  static Future<StorageService> create() async =>
      StorageService(await SharedPreferences.getInstance());

  SelectedLocation loadLocation() => SelectedLocation(
        districtId:
            _prefs.getString(_kDistrictId) ?? AppConstants.defaultDistrictId,
        districtName: _prefs.getString(_kDistrictName) ??
            AppConstants.defaultDistrictName,
        cityName: _prefs.getString(_kCityName) ??
            (_prefs.containsKey(_kDistrictId)
                ? null
                : AppConstants.defaultDistrictName),
      );

  Future<void> saveLocation(SelectedLocation location) async {
    await _prefs.setString(_kDistrictId, location.districtId);
    await _prefs.setString(_kDistrictName, location.districtName);
    if (location.cityName != null) {
      await _prefs.setString(_kCityName, location.cityName!);
    } else {
      await _prefs.remove(_kCityName);
    }
  }

  List<DailyPrayerTimes>? loadCachedTimes(String districtId) {
    final raw = _prefs.getString('$_kCachePrefix$districtId');
    if (raw == null) return null;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(DailyPrayerTimes.fromJson).toList();
    } on Object {
      return null;
    }
  }

  Future<void> cacheTimes(String districtId, List<DailyPrayerTimes> days) =>
      _prefs.setString(
        '$_kCachePrefix$districtId',
        jsonEncode(days.map((d) => d.toJson()).toList()),
      );

  int loadTesbihCount() => _prefs.getInt(_kTesbihCount) ?? 0;

  Future<void> saveTesbihCount(int value) =>
      _prefs.setInt(_kTesbihCount, value);

  NotificationSettings loadNotificationSettings() {
    final raw = _prefs.getString(_kNotifications);
    if (raw == null) return const NotificationSettings();
    try {
      return NotificationSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object {
      return const NotificationSettings();
    }
  }

  Future<void> saveNotificationSettings(NotificationSettings settings) =>
      _prefs.setString(_kNotifications, jsonEncode(settings.toJson()));
}
