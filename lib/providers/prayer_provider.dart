import 'package:flutter/foundation.dart';

import '../models/location_models.dart';
import '../models/prayer_times.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// Namaz vakitleri durumu: konum, günlük/aylık veriler, yükleme ve hata.
class PrayerProvider extends ChangeNotifier {
  PrayerProvider({required ApiService api, required StorageService storage})
      : _api = api,
        _storage = storage,
        _location = storage.loadLocation() {
    final cached = _storage.loadCachedTimes(_location.districtId);
    if (cached != null && cached.isNotEmpty) {
      _days = cached;
      _fromCache = true;
    }
  }

  final ApiService _api;
  final StorageService _storage;

  SelectedLocation _location;
  List<DailyPrayerTimes> _days = const [];
  bool _loading = false;
  bool _fromCache = false;
  String? _error;
  DateTime? _lastAttempt;
  int _requestId = 0;

  static const Duration _autoRetryInterval = Duration(minutes: 30);

  SelectedLocation get location => _location;
  List<DailyPrayerTimes> get days => List.unmodifiable(_days);
  bool get isLoading => _loading;
  bool get isFromCache => _fromCache;
  String? get error => _error;
  bool get hasData => _days.isNotEmpty;

  Future<void> load() async {
    // Konum değişirse önceki isteğin sonucu yok sayılır.
    final requestId = ++_requestId;
    final districtId = _location.districtId;
    _loading = true;
    _error = null;
    _lastAttempt = DateTime.now();
    notifyListeners();

    String? error;
    List<DailyPrayerTimes>? fresh;
    try {
      fresh = await _api.fetchPrayerTimes(districtId);
      await _storage.cacheTimes(districtId, fresh);
    } on ApiException catch (e) {
      error = e.message;
    } on FormatException catch (e) {
      error = 'Veri çözümlenemedi: ${e.message}';
    }

    if (requestId != _requestId) return;
    if (fresh != null) {
      _days = fresh;
      _fromCache = false;
    }
    _error = error;
    _loading = false;
    notifyListeners();
  }

  Future<void> changeLocation(SelectedLocation location) async {
    _location = location;
    await _storage.saveLocation(location);
    _days = _storage.loadCachedTimes(location.districtId) ?? const [];
    _fromCache = _days.isNotEmpty;
    notifyListeners();
    await load();
  }

  DailyPrayerTimes? dayFor(DateTime date) {
    for (final day in _days) {
      if (day.isSameDay(date)) return day;
    }
    return null;
  }

  DailyPrayerTimes? today(DateTime now) => dayFor(now);

  /// Şu an içinde bulunulan vakit. İmsaktan önceyse bir önceki günün yatsısı.
  PrayerMoment? currentPrayer(DateTime now) {
    final day = today(now);
    if (day == null) return null;

    PrayerMoment? current;
    for (final moment in day.moments) {
      if (!moment.time.isAfter(now)) current = moment;
    }
    if (current != null) return current;

    final yesterday = dayFor(now.subtract(const Duration(days: 1)));
    return yesterday == null
        ? null
        : PrayerMoment(PrayerType.yatsi, yesterday.timeOf(PrayerType.yatsi));
  }

  /// Sıradaki vakit. Yatsıdan sonraysa ertesi günün imsakı.
  PrayerMoment? nextPrayer(DateTime now) {
    final day = today(now);
    if (day == null) return null;

    for (final moment in day.moments) {
      if (moment.time.isAfter(now)) return moment;
    }

    final tomorrow = dayFor(now.add(const Duration(days: 1)));
    return tomorrow == null
        ? null
        : PrayerMoment(PrayerType.imsak, tomorrow.timeOf(PrayerType.imsak));
  }

  /// Veriler bugünü ve yarını kapsamıyorsa (ör. gün değişti, önbellek eskidi)
  /// yeniden çeker. Ana ekrandaki sayaç her tikte çağırır; ağ isteği yalnızca
  /// gerektiğinde ve en fazla [_autoRetryInterval] aralıkla yapılır.
  void ensureFresh(DateTime now) {
    if (_loading) return;
    final last = _lastAttempt;
    if (last != null && now.difference(last) < _autoRetryInterval) return;
    final tomorrow = now.add(const Duration(days: 1));
    if (today(now) == null || dayFor(tomorrow) == null) {
      load();
    }
  }
}
