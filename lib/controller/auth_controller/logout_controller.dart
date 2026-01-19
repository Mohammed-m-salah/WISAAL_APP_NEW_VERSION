import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogOutController extends GetxController {
  var isLoading = false.obs;
  var loginError = ''.obs;

  Future<void> LogOut() async {
    final supabase = Supabase.instance.client;
    await supabase.auth.signOut();
    Get.offAllNamed('authpage');
  }
}
