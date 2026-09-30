import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/location_models.dart';
import '../models/prayer_times.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// ezanvakti.emushaf.net istemcisi.
///
/// Uç noktalar:
///  * `/sehirler/{ulkeId}`  → şehir listesi
///  * `/ilceler/{sehirId}`  → ilçe listesi
///  * `/vakitler/{ilceId}`  → yaklaşık 30 günlük vakit listesi
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 15);

  Future<List<DailyPrayerTimes>> fetchPrayerTimes(String districtId) async {
    final data = await _getList('/vakitler/$districtId');
    final days = data
        .cast<Map<String, dynamic>>()
        .map(DailyPrayerTimes.fromJson)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (days.isEmpty) {
      throw const ApiException('Bu konum için vakit bilgisi bulunamadı.');
    }
    return days;
  }

  Future<List<Region>> fetchCities({
    String countryId = AppConstants.turkeyCountryId,
  }) async {
    final data = await _getList('/sehirler/$countryId');
    return data.cast<Map<String, dynamic>>().map(Region.city).toList();
  }

  Future<List<Region>> fetchDistricts(String cityId) async {
    final data = await _getList('/ilceler/$cityId');
    return data.cast<Map<String, dynamic>>().map(Region.district).toList();
  }

  Future<List<dynamic>> _getList(String path) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on Exception {
      throw const ApiException(
        'Sunucuya ulaşılamadı. İnternet bağlantınızı kontrol edin.',
      );
    }

    if (response.statusCode != 200) {
      throw ApiException('Sunucu hatası (${response.statusCode}).');
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) throw const FormatException();
      return decoded;
    } on FormatException {
      throw const ApiException('Sunucudan beklenmeyen bir yanıt alındı.');
    }
  }

  void dispose() => _client.close();
}
