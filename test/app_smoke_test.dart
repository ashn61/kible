import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:kible/main.dart';
import 'package:kible/services/api_service.dart';
import 'package:kible/services/notification_service.dart';
import 'package:kible/services/storage_service.dart';
import 'package:kible/services/widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// Bugünden bir gün önce başlayan 30 günlük sahte vakit listesi.
List<Map<String, dynamic>> _fakeDays() {
  final now = DateTime.now();
  return [
    for (var i = -1; i < 29; i++)
      () {
        final d = DateTime(now.year, now.month, now.day + i);
        return {
          'MiladiTarihKisa': '${_two(d.day)}.${_two(d.month)}.${d.year}',
          'MiladiTarihUzun': '${d.day} Eylül ${d.year} Cumartesi',
          'HicriTarihKisa': '${16 + i}.4.1448',
          'HicriTarihUzun': '${16 + i} Rebiulahir 1448',
          'AyinSekliURL': null,
          'Imsak': '05:29',
          'Gunes': '06:54',
          'Ogle': '13:06',
          'Ikindi': '16:28',
          'Aksam': '19:09',
          'Yatsi': '20:28',
          'KibleSaati': '11:31',
        };
      }(),
  ];
}

/// Testte platform kanalı yok; bildirimleri desteklenmeyen platform gibi davran.
class _NoopNotificationService extends NotificationService {
  @override
  bool get isSupported => false;
}

class _NoopWidgetService extends WidgetService {
  @override
  bool get isSupported => false;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
    Intl.defaultLocale = 'tr_TR';
  });

  // Küçükten büyüğe telefon ekranları (mantıksal piksel).
  const screens = {
    'iPhone SE (1. nesil)': Size(320, 568),
    'Küçük Android': Size(360, 640),
    'Pixel 7': Size(412, 915),
    'iPhone Pro Max': Size(430, 932),
  };

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    testWidgets('Tüm sekmeler taşmadan açılır: $name', (tester) async {
      tester.view.physicalSize = screen * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      // Sonsuz logo animasyonu pumpAndSettle'ı bekletmesin.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.create();
      final api = ApiService(
        client: MockClient((req) async => http.Response.bytes(
              utf8.encode(jsonEncode(_fakeDays())),
              200,
            )),
      );

      await tester.pumpWidget(KibleApp(
        storage: storage,
        api: api,
        notifications: _NoopNotificationService(),
        widgets: _NoopWidgetService(),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Kalan süre'), findsOneWidget);
      expect(find.text('Trabzon'), findsOneWidget);
      expect(find.text('İkindi'), findsOneWidget);

      await tester.tap(find.text('Namazlar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aylık'));
      await tester.pumpAndSettle();
      expect(find.text('Tarih'), findsOneWidget);

      await tester.tap(find.text('Daha Fazla'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('İbadet Takvimi'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kandili'), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ezan Bildirimleri'));
      await tester.pumpAndSettle();
      expect(find.text('Vakit bildirimleri'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Test bildirimi gönder'), 200);
      expect(find.text('Önceden hatırlat'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tesbihat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('0'));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kıble'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Kıble Yönü'), findsOneWidget);
      expect(find.textContaining('Güney'), findsWidgets);
    });
  }
}
