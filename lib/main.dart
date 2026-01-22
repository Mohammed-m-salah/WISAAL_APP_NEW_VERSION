import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_links/app_links.dart';

import 'package:wissal_app/config/page_path.dart';
import 'package:wissal_app/config/thems.dart';
import 'package:wissal_app/controller/call_controller/call_controller.dart';
import 'package:wissal_app/controller/theme_controller/theme_controller.dart';
import 'package:wissal_app/controller/locale_controller/locale_controller.dart';
import 'package:wissal_app/localization/app_translations.dart';
import 'package:wissal_app/pages/splash_page/splash_page.dart';
import 'package:wissal_app/pages/welcom_page/welcom_page.dart';

// Offline mode services
import 'package:wissal_app/services/local_database/local_database_service.dart';
import 'package:wissal_app/services/connectivity/connectivity_service.dart';
import 'package:wissal_app/services/sync/sync_service.dart';
import 'package:wissal_app/services/offline_queue/offline_queue_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> initOfflineServices() async {
  // Initialize local database first
  await Get.putAsync(() => LocalDatabaseService().init(), permanent: true);

  // Initialize connectivity service
  await Get.putAsync(() => ConnectivityService().init(), permanent: true);

  // Initialize offline queue service
  await Get.putAsync(() => OfflineQueueService().init(), permanent: true);

  // Initialize sync service
  await Get.putAsync(() => SyncService().init(), permanent: true);

  print('✅ All offline services initialized');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initNotifications();

  await Supabase.initialize(
    url: 'https://cbygpcbgylipcoxvuogl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNieWdwY2JneWxpcGNveHZ1b2dsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyMDM1NzIsImV4cCI6MjA4Mzc3OTU3Mn0.LfLHMpw1LzjMwG1aFOpGRh9qeqRbRX2NdKjb0Mfz_co',
  );

  // Initialize offline mode services
  await initOfflineServices();

  // Initialize controllers
  Get.put(ThemeController(), permanent: true);
  Get.put(LocaleController(), permanent: true);

  final prefs = await SharedPreferences.getInstance();
  final bool isFirstTime = prefs.getBool('is_first_time') ?? true;
  final bool isLoggedIn = Supabase.instance.client.auth.currentUser != null;

  if (isFirstTime) {
    await prefs.setBool('is_first_time', false);
  }

  runApp(MyApp(
    isFirstTime: isFirstTime,
    isLoggedIn: isLoggedIn,
  ));
}

class MyApp extends StatefulWidget {
  final bool isFirstTime;
  final bool isLoggedIn;

  const MyApp({
    super.key,
    required this.isFirstTime,
    required this.isLoggedIn,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  final ThemeController _themeController = Get.find<ThemeController>();
  final LocaleController _localeController = Get.find<LocaleController>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _setupAuthListener();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // الاستماع للروابط الواردة
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
  }

  void _handleDeepLink(Uri uri) async {
    print("📱 Deep link received: $uri");

    // معالجة رابط تأكيد البريد من Supabase
    if (uri.scheme == 'com.example.wissal_app' &&
        uri.host == 'login-callback') {
      // Supabase سيتعامل مع الجلسة تلقائياً
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        Get.snackbar('email_verified'.tr, 'login_success'.tr);
        Get.offAllNamed('/homepage');
      }
    }
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      print("🔐 Auth state changed: $event");

      if (event == AuthChangeEvent.signedIn && session != null) {
        // المستخدم سجل دخوله بنجاح
        // Trigger sync when user signs in
        if (Get.isRegistered<SyncService>()) {
          Get.find<SyncService>().syncAll();
        }
        Get.offAllNamed('/homepage');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Get.put(CallController());
    return Obx(() => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: lightThem,
          darkTheme: darktThem,
          themeMode: _themeController.themeMode,
          translations: AppTranslations(),
          locale: _localeController.locale,
          fallbackLocale: const Locale('en', 'US'),
          getPages: pagePath,
          home: widget.isFirstTime
              ? const WelcomPage()
              : widget.isLoggedIn
                  ? const SplashPage()
                  : const WelcomPage(),
        ));
  }
}
