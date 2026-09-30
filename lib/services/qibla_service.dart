import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../core/constants/app_constants.dart';

class Coordinates {
  const Coordinates(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// Örn. "41.00° K, 39.72° D"
  String get formatted {
    final lat =
        '${latitude.abs().toStringAsFixed(2)}° ${latitude >= 0 ? 'K' : 'G'}';
    final lon =
        '${longitude.abs().toStringAsFixed(2)}° ${longitude >= 0 ? 'D' : 'B'}';
    return '$lat, $lon';
  }
}

class QiblaService {
  static const Coordinates kaaba = Coordinates(
    AppConstants.kaabaLatitude,
    AppConstants.kaabaLongitude,
  );

  static const Coordinates fallback = Coordinates(
    AppConstants.defaultLatitude,
    AppConstants.defaultLongitude,
  );

  /// Verilen konumdan Kâbe'ye olan yön (gerçek kuzeye göre, 0–360°).
  static double qiblaBearing(Coordinates from) {
    final lat1 = _rad(from.latitude);
    final lat2 = _rad(kaaba.latitude);
    final dLon = _rad(kaaba.longitude - from.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (_deg(math.atan2(y, x)) + 360) % 360;
  }

  /// Kâbe'ye olan büyük daire mesafesi (km).
  static double distanceToKaabaKm(Coordinates from) {
    const earthRadiusKm = 6371.0;
    final dLat = _rad(kaaba.latitude - from.latitude);
    final dLon = _rad(kaaba.longitude - from.longitude);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(from.latitude)) *
            math.cos(_rad(kaaba.latitude)) *
            math.pow(math.sin(dLon / 2), 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// 0–360° açıyı Türkçe yön adına çevirir (8 yön).
  static String directionName(double degrees) {
    const names = [
      'Kuzey',
      'Kuzeydoğu',
      'Doğu',
      'Güneydoğu',
      'Güney',
      'Güneybatı',
      'Batı',
      'Kuzeybatı',
    ];
    final index = (((degrees % 360) + 22.5) ~/ 45) % 8;
    return names[index];
  }

  /// Cihaz konumunu alır. İzin verilmezse veya servis kapalıysa
  /// [LocationUnavailable] fırlatır.
  Future<Coordinates> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailable('Konum servisi kapalı.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationUnavailable('Konum izni verilmedi.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return Coordinates(position.latitude, position.longitude);
  }

  static double _rad(double deg) => deg * math.pi / 180;
  static double _deg(double rad) => rad * 180 / math.pi;
}

class LocationUnavailable implements Exception {
  const LocationUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}
