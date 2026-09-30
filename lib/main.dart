import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/notification_provider.dart';
import 'providers/prayer_provider.dart';
import 'providers/qibla_provider.dart';
import 'screens/main_shell.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('tr_TR');
  Intl.defaultLocale = 'tr_TR';

  // Tam ekran (kenardan kenara): içerik durum çubuğu ve gezinme çubuğunun
  // altına kadar uzanır; güvenli alan boşlukları SafeArea ile verilir.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  ));

  final storage = await StorageService.create();
  final notifications = NotificationService();
  await notifications.init();
  final widgets = WidgetService();
  await widgets.init();
  runApp(KibleApp(
    storage: storage,
    api: ApiService(),
    notifications: notifications,
    widgets: widgets,
  ));
}

class KibleApp extends StatelessWidget {
  const KibleApp({
    super.key,
    required this.storage,
    required this.api,
    required this.notifications,
    this.widgets,
  });

  final StorageService storage;
  final ApiService api;
  final NotificationService notifications;
  final WidgetService? widgets;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider(
          create: (_) => PrayerProvider(api: api, storage: storage)..load(),
        ),
        ChangeNotifierProxyProvider<PrayerProvider, NotificationProvider>(
          // Uygulama açılır açılmaz bildirimler yeniden planlansın.
          lazy: false,
          create: (_) => NotificationProvider(
            service: notifications,
            storage: storage,
            widgets: widgets,
          ),
          update: (_, prayer, notification) => notification!..attach(prayer),
        ),
        ChangeNotifierProvider(create: (_) => QiblaProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const MainShell(),
      ),
    );
  }
}
