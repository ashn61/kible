import 'package:flutter/foundation.dart';

import '../services/qibla_service.dart';

/// Kıble ekranı durumu: kullanıcının konumu ve hesaplanan kıble açısı.
/// Konum alınamazsa Trabzon merkez koordinatlarıyla hesaplanır.
class QiblaProvider extends ChangeNotifier {
  QiblaProvider({QiblaService? service}) : _service = service ?? QiblaService();

  final QiblaService _service;

  Coordinates _coordinates = QiblaService.fallback;
  bool _usingFallback = true;
  bool _loading = false;
  String? _message;

  Coordinates get coordinates => _coordinates;
  bool get isUsingFallback => _usingFallback;
  bool get isLoading => _loading;

  /// Konum alınamadıysa kullanıcıya gösterilecek açıklama.
  String? get message => _message;

  double get qiblaBearing => QiblaService.qiblaBearing(_coordinates);
  String get directionName => QiblaService.directionName(qiblaBearing);
  double get distanceKm => QiblaService.distanceToKaabaKm(_coordinates);

  Future<void> locate() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    try {
      _coordinates = await _service.currentPosition();
      _usingFallback = false;
      _message = null;
    } on LocationUnavailable catch (e) {
      _message = '${e.message} Trabzon merkez koordinatları kullanılıyor.';
    } on Exception {
      _message = 'Konum alınamadı. Trabzon merkez koordinatları kullanılıyor.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
