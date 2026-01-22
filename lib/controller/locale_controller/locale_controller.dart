import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends GetxController {
  static const String _localeKey = 'locale';

  final Rx<Locale> _locale = const Locale('en', 'US').obs;

  Locale get locale => _locale.value;

  bool get isArabic => _locale.value.languageCode == 'ar';

  bool get isEnglish => _locale.value.languageCode == 'en';

  @override
  void onInit() {
    super.onInit();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeString = prefs.getString(_localeKey);

    if (localeString != null) {
      final parts = localeString.split('_');
      if (parts.length == 2) {
        _locale.value = Locale(parts[0], parts[1]);
      }
    } else {
      // Default to device locale if available
      final deviceLocale = PlatformDispatcher.instance.locale;
      if (deviceLocale.languageCode == 'ar') {
        _locale.value = const Locale('ar', 'SA');
      } else {
        _locale.value = const Locale('en', 'US');
      }
    }

    Get.updateLocale(_locale.value);
  }

  Future<void> setLocale(Locale newLocale) async {
    _locale.value = newLocale;
    Get.updateLocale(newLocale);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _localeKey, '${newLocale.languageCode}_${newLocale.countryCode}');
  }

  Future<void> setArabic() async {
    await setLocale(const Locale('ar', 'SA'));
  }

  Future<void> setEnglish() async {
    await setLocale(const Locale('en', 'US'));
  }

  Future<void> toggleLanguage() async {
    if (isArabic) {
      await setEnglish();
    } else {
      await setArabic();
    }
  }

  String get currentLanguageName {
    if (isArabic) {
      return 'العربية';
    }
    return 'English';
  }

  String get currentLanguageCode {
    return _locale.value.languageCode;
  }
}
