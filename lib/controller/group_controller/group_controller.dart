import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wissal_app/controller/profile_controller/profile_controller.dart';
import 'package:wissal_app/model/Group_model.dart';
import 'package:wissal_app/model/chat_model.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/pages/Homepage/home_page.dart';

class GroupController extends GetxController {
  RxList<UserModel> groupMembers = <UserModel>[].obs;
  final db = Supabase.instance.client;
  final auth = Supabase.instance.client.auth;
  final uuid = Uuid();
  RxBool isLoading = false.obs;
  RxBool isSending = false.obs;
  RxList<GroupModel> groupList = <GroupModel>[].obs;
  final ProfileController profileController = Get.find<ProfileController>();

  RxString selectedImagePath = ''.obs;
  RxString selectedAudioPath = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getGroups();
  }

  void selectMember(UserModel user) {
    if (groupMembers.any((u) => u.id == user.id)) {
      groupMembers.removeWhere((u) => u.id == user.id);
    } else {
      groupMembers.add(user);
    }
  }

  Future<void> creatGroup(String groupName, String imagePath) async {
    isLoading.value = true;

    if (groupName.trim().isEmpty) {
      showError("يرجى إدخال اسم المجموعة");
      isLoading.value = false;
      return;
    }

    if (groupMembers.isEmpty) {
      showError("يرجى اختيار أعضاء للمجموعة");
      isLoading.value = false;
      return;
    }

    final currentUserId = auth.currentUser?.id;
    if (currentUserId == null) {
      showError("لم يتم تسجيل الدخول");
      isLoading.value = false;
      return;
    }

    try {
      final groupId = uuid.v4();
      String? imgUrl;

      if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
        imgUrl = await profileController.uploadeFileToSupabase(imagePath);
      }

      groupMembers.addIf(
        !groupMembers.any((u) => u.id == currentUserId),
        UserModel(
          id: currentUserId,
          name: profileController.currentUser.value.name,
          email: profileController.currentUser.value.email,
          role: 'Admin',
        ),
      );

      final now = DateTime.now().toIso8601String();

      final newGroup = GroupModel(
        id: groupId,
        name: groupName,
        profileUrl: imgUrl ?? '',
        members: groupMembers.toList(),
        createdAt: now,
        createdBy: currentUserId,
        timestamp: now,
      );

      final response =
          await db.from('groups').insert(newGroup.toJson()).select().single();

      if (response == null) throw Exception("فشل في إنشاء المجموعة");

      groupMembers.clear();
      Get.offAll(() => HomePage());
      Get.snackbar("تم", "تم إنشاء المجموعة بنجاح");
    } catch (e) {
      showError("حدث خطأ أثناء إنشاء المجموعة: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getGroups() async {
    isLoading.value = true;
    final currentUserId = auth.currentUser?.id;

    if (currentUserId == null) {
      showError("لم يتم تسجيل الدخول");
      isLoading.value = false;
      return;
    }

    try {
      final response = await db.from('groups').select();

      if (response is List) {
        groupList.value = response
            .map((item) => GroupModel.fromJson(item))
            .where((group) => group.members.any((m) => m.id == currentUserId))
            .toList();
      } else {
        groupList.clear();
      }

      print("✅ عدد المجموعات: ${groupList.length}");
    } catch (e) {
      showError("حدث خطأ أثناء تحميل المجموعات: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendGroupMessage(
    String groupId,
    String message, {
    bool isVoice = false,
  }) async {
    print("🚀 بدء إرسال رسالة إلى المجموعة $groupId");
    isLoading.value = true;
    isSending.value = true;

    final chatId = uuid.v6();
    final now = DateTime.now().toIso8601String();
    final sender = profileController.currentUser.value;

    RxString imageUrl = ''.obs;
    RxString audioUrl = ''.obs;

    try {
      if (selectedImagePath.value.isNotEmpty) {
        print("📁 جاري رفع صورة من المسار: ${selectedImagePath.value}");
        imageUrl.value = await profileController
            .uploadeFileToSupabase(selectedImagePath.value);
        print("✅ تم رفع الصورة: ${imageUrl.value}");
      }

      if (isVoice && selectedAudioPath.value.isNotEmpty) {
        print("🎙️ جاري رفع ملف صوتي من المسار: ${selectedAudioPath.value}");
        audioUrl.value = await profileController
            .uploadeFileToSupabase(selectedAudioPath.value);
        print("✅ تم رفع الصوت: ${audioUrl.value}");
      }

      final newChat = ChatModel(
        id: chatId,
        senderId: sender.id,
        senderName: sender.name,
        message: message.isNotEmpty ? message : '',
        imageUrl: imageUrl.value,
        audioUrl: audioUrl.value,
        timeStamp: now,
      );

      print("🧾 محتوى الرسالة المُرسلة: ${newChat.toMap()}");

      await db.from('group_chats').insert({
        ...newChat.toMap(),
        'groupId': groupId,
      });

      print("✅ تم إرسال الرسالة بنجاح إلى group_chats");

      String type = message.isNotEmpty
          ? "نص"
          : imageUrl.value.isNotEmpty
              ? "📷 صورة"
              : audioUrl.value.isNotEmpty
                  ? "🎤 صوت"
                  : "غير محدد";

      print("📤 نوع الرسالة: $type");

      await db.from('groups').update({
        'last_message': message.isNotEmpty
            ? message
            : imageUrl.value.isNotEmpty
                ? '📷 صورة'
                : audioUrl.value.isNotEmpty
                    ? '🎤 صوت'
                    : '',
        'timeStamp': now,
      }).eq('id', groupId);

      print("🆗 تم تحديث بيانات المجموعة بنجاح");
    } catch (e) {
      print("❌ خطأ أثناء إرسال الرسالة: $e");
      showError("حدث خطأ أثناء إرسال الرسالة: $e");
    } finally {
      selectedImagePath.value = "";
      selectedAudioPath.value = "";
      isLoading.value = false;
      isSending.value = false;
      print("🏁 انتهت عملية إرسال الرسالة");
    }
  }

  Stream<List<ChatModel>> getGroupMessages(String groupId) {
    return db
        .from('group_chats')
        .stream(primaryKey: ['id'])
        .eq('groupId', groupId)
        .order('timeStamp')
        .map((data) {
          print("📥 بيانات خام: $data");
          try {
            return data.map((e) {
              print("🧾 صف مفرد: $e");
              return ChatModel.fromJson(e);
            }).toList();
          } catch (e) {
            print("❌ خطأ في تحويل الرسائل: $e");
            return [];
          }
        });
  }

  void showError(String message) {
    Get.snackbar("خطأ", message,
        backgroundColor: Colors.red, colorText: Colors.white);
    isLoading.value = false;
  }
}
