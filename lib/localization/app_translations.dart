import 'package:get/get.dart';
import 'package:wissal_app/localization/en_us.dart';
import 'package:wissal_app/localization/ar_sa.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUS,
        'ar_SA': arSA,
      };
}
