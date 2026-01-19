import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wissal_app/model/user_model.dart';

class ProfileController extends GetxController {
  final supabase = Supabase.instance.client;
  final db = Supabase.instance.client;

  Rx<UserModel> currentUser = UserModel().obs;
  RxBool isloading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 1. الاستماع لتغيرات الحالة لضمان جلب البيانات فور استقرار الجلسة (حل مشكلة السباق الزمني)
    supabase.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        print("✅ الجلسة نشطة في ProfileController، جاري جلب البيانات...");
        getUserDetails();
      }
    });

    // 2. محاولة جلب أولية في حال كان المستخدم مسجلاً مسبقاً
    if (supabase.auth.currentUser != null) {
      getUserDetails();
    }
  }

  /// ✅ جلب بيانات المستخدم الحالي من جدول save_users
  Future<UserModel?> getUserDetails() async {
    isloading.value = true;
    try {
      final authUser = supabase.auth.currentUser;

      if (authUser == null) {
        print("❌ المستخدم غير مسجل الدخول");
        return null;
      }

      final userId = authUser.id;

      final data = await supabase
          .from('save_users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        print("⚠️ لم يتم العثور على بيانات، جاري إنشاء المستخدم...");
        // إنشاء المستخدم من بيانات Auth إذا لم يوجد
        final newUser = UserModel(
          id: userId,
          email: authUser.email ?? '',
          name: authUser.userMetadata?['name'] ?? authUser.email?.split('@').first ?? 'User',
          status: true,
        );

        await supabase.from('save_users').upsert(newUser.toJson());
        currentUser.value = newUser;
        print("✅ تم إنشاء المستخدم بنجاح");
        return newUser;
      }

      final user = UserModel.fromJson(data);
      currentUser.value = user;
      return user;
    } catch (e) {
      print("❌ خطأ أثناء جلب بيانات المستخدم: $e");
      return null;
    } finally {
      isloading.value = false;
    }
  }

  /// ✅ رفع ملف إلى الباكت 'avatars' (تأكد من إنشاء الباكت في Supabase)
  Future<String> uploadeFileToSupabase(String imagePath) async {
    final fileName = "${const Uuid().v4()}_${imagePath.split('/').last}";
    final file = File(imagePath);
    final bucket = supabase.storage.from('avatars');

    try {
      await bucket.upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final publicUrl = bucket.getPublicUrl(fileName);
      print("✅ تم رفع الصورة بنجاح: $publicUrl");
      return publicUrl;
    } catch (e) {
      print("❌ خطأ أثناء رفع الصورة: $e");
      return "";
    }
  }

  /// ✅ إضافة عضو لمجموعة
  Future<void> addMemberToGroup(String groupId, UserModel user) async {
    try {
      isloading.value = true;

      final response =
          await db.from('groups').select('members').eq('id', groupId).single();

      dynamic membersData = response['members'];
      List<dynamic> membersJson;

      if (membersData == null) {
        membersJson = [];
      } else if (membersData is String) {
        membersJson = jsonDecode(membersData);
      } else if (membersData is List) {
        membersJson = membersData;
      } else {
        membersJson = [];
      }

      bool isAlreadyMember =
          membersJson.any((member) => member['id'] == user.id);

      if (isAlreadyMember) {
        print("العضو موجود مسبقاً في المجموعة");
        return;
      }

      membersJson.add(user.toJson());

      await db
          .from('groups')
          .update({'members': membersJson}).eq('id', groupId);

      print("تمت إضافة العضو ${user.name} بنجاح إلى المجموعة $groupId");
    } catch (e) {
      print("خطأ أثناء إضافة العضو: $e");
      showError("حدث خطأ أثناء إضافة العضو: $e");
    } finally {
      isloading.value = false;
    }
  }

  void showError(String message) {
    Get.snackbar("خطأ", message,
        backgroundColor: Colors.red, colorText: Colors.white);
    isloading.value = false;
  }
}
