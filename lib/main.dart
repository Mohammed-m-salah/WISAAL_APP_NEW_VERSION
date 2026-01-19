import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_links/app_links.dart';

import 'package:wissal_app/config/page_path.dart';
import 'package:wissal_app/config/thems.dart';
import 'package:wissal_app/controller/call_controller/call_controller.dart';
import 'package:wissal_app/pages/splash_page/splash_page.dart';
import 'package:wissal_app/pages/welcom_page/welcom_page.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initNotifications();

  await Supabase.initialize(
    url: 'https://cbygpcbgylipcoxvuogl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNieWdwY2JneWxpcGNveHZ1b2dsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyMDM1NzIsImV4cCI6MjA4Mzc3OTU3Mn0.LfLHMpw1LzjMwG1aFOpGRh9qeqRbRX2NdKjb0Mfz_co',
  );

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
        Get.snackbar("تم التأكيد", "تم تأكيد بريدك الإلكتروني بنجاح!");
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
        Get.offAllNamed('/homepage');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Get.put(CallController());
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightThem,
      darkTheme: darktThem,
      themeMode: ThemeMode.dark,
      getPages: pagePath,
      home: widget.isFirstTime
          ? const WelcomPage()
          : widget.isLoggedIn
              ? const SplashPage()
              : const WelcomPage(),
    );
  }
}
