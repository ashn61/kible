/// API'deki ülke / şehir / ilçe kayıtları için ortak model.
class Region {
  const Region({required this.id, required this.name});

  final String id;
  final String name;

  factory Region.city(Map<String, dynamic> json) => Region(
        id: json['SehirID'] as String,
        name: json['SehirAdi'] as String,
      );

  factory Region.district(Map<String, dynamic> json) => Region(
        id: json['IlceID'] as String,
        name: json['IlceAdi'] as String,
      );

  /// "TRABZON" → "Trabzon", "KÖPRÜBAŞI (T)" → "Köprübaşı (T)"
  String get displayName => name
      .split(' ')
      .map((word) => word.isEmpty
          ? word
          : word.startsWith('(')
              ? word
              : word[0] + _trLower(word.substring(1)))
      .join(' ');

  static String _trLower(String input) =>
      input.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
}

/// Kullanıcının seçtiği konum.
class SelectedLocation {
  const SelectedLocation({
    required this.districtId,
    required this.districtName,
    this.cityName,
  });

  final String districtId;
  final String districtName;
  final String? cityName;

  /// Ana sayfada gösterilen etiket. İlçe merkez ise yalnızca il adı.
  String get label {
    if (cityName == null || cityName == districtName) return districtName;
    return '$districtName, $cityName';
  }
}
