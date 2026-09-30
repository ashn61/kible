abstract final class AppConstants {
  static const String appName = 'Kıble';
  static const String slogan = 'Her vakit, huzura bir adım';

  static const String apiBaseUrl = 'https://ezanvakti.emushaf.net';

  /// Varsayılan konum: Trabzon (Merkez).
  static const String defaultDistrictId = '9905';
  static const String defaultDistrictName = 'Trabzon';

  /// Türkiye'nin API'deki ülke kimliği.
  static const String turkeyCountryId = '2';

  /// Trabzon merkez koordinatları (konum izni yoksa kıble hesabı için).
  static const double defaultLatitude = 41.0027;
  static const double defaultLongitude = 39.7168;

  /// Kâbe koordinatları.
  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;
}
