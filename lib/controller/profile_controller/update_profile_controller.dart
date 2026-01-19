import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/controller/profile_controller/profile_controller.dart';

class UpdateProfileController extends GetxController {
  final supabase = Supabase.instance.client;
  RxBool isloading = false.obs;
  final getcontroller = Get.find<ProfileController>();

  Future<void> updateProfile(
      String? imgPath, String? name, String? about, String? number) async {
    isloading.value = true;

    try {
      String? imageUrl;

      final isLocalFile =
          imgPath != null && imgPath.isNotEmpty && !imgPath.startsWith('http');

      if (isLocalFile) {
        final file = File(imgPath);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${imgPath.split('/').last}';

        final storageBucket = supabase.storage.from('avatars');

        await storageBucket.upload(
          'profile_images/$fileName',
          file,
          fileOptions: const FileOptions(upsert: true),
        );

        imageUrl = storageBucket.getPublicUrl('profile_images/$fileName');
      }

      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final currentUser = getcontroller.currentUser.value;

        final Map<String, dynamic> updateData = {
          'id': userId,
          'email': supabase.auth.currentUser!.email,
          'name': name ?? currentUser.name,
          'about': about ?? currentUser.about ?? '',
          'profileimage': imageUrl ?? imgPath ?? currentUser.profileimage,
          'phonenumber': number ?? currentUser.phonenumber,
        };

        await supabase.from('save_users').upsert(updateData);

        await getcontroller.getUserDetails();

        Get.snackbar(
          "Success",
          "Profile updated successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // الرجوع للصفحة السابقة بعد النجاح
        Get.back();
      }
    } catch (e, stacktrace) {
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print("==============Caught error===================: $e");
      print("============Stack trace=================: $stacktrace");
    } finally {
      isloading.value = false;
    }
  }
}
