import 'prayer_times.dart';

/// Ezan vakti bildirim tercihleri.
class NotificationSettings {
  const NotificationSettings({
    this.enabled = false,
    this.prayers = defaultPrayers,
    this.minutesBefore = 0,
    this.ongoing = false,
  });

  /// Güneş bir namaz vakti değil, varsayılan olarak kapalı.
  static const Set<PrayerType> defaultPrayers = {
    PrayerType.imsak,
    PrayerType.ogle,
    PrayerType.ikindi,
    PrayerType.aksam,
    PrayerType.yatsi,
  };

  /// Seçilebilir hatırlatma süreleri (0 = hatırlatma yok).
  static const List<int> reminderOptions = [0, 5, 10, 15, 30, 45];

  final bool enabled;
  final Set<PrayerType> prayers;

  /// Vakitten kaç dakika önce ek hatırlatma yapılacağı (0 = yapılmaz).
  final int minutesBefore;

  /// Android: bildirim panelinde sıradaki vakte geri sayan kalıcı bildirim.
  final bool ongoing;

  NotificationSettings copyWith({
    bool? enabled,
    Set<PrayerType>? prayers,
    int? minutesBefore,
    bool? ongoing,
  }) =>
      NotificationSettings(
        enabled: enabled ?? this.enabled,
        prayers: prayers ?? this.prayers,
        minutesBefore: minutesBefore ?? this.minutesBefore,
        ongoing: ongoing ?? this.ongoing,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'prayers': [for (final p in prayers) p.name],
        'minutesBefore': minutesBefore,
        'ongoing': ongoing,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final names = (json['prayers'] as List?)?.cast<String>();
    return NotificationSettings(
      enabled: json['enabled'] as bool? ?? false,
      prayers: names == null
          ? defaultPrayers
          : {
              for (final type in PrayerType.values)
                if (names.contains(type.name)) type,
            },
      minutesBefore: json['minutesBefore'] as int? ?? 0,
      ongoing: json['ongoing'] as bool? ?? false,
    );
  }

  /// Planlamayı etkileyen her şeyi özetleyen anahtar.
  String get signature =>
      '$enabled|${prayers.map((p) => p.index).toList()..sort()}|$minutesBefore';
}
