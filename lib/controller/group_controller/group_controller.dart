import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wissal_app/controller/profile_controller/profile_controller.dart';
import 'package:wissal_app/controller/reactions_controller/reactions_controller.dart';
import 'package:wissal_app/model/Group_model.dart';
import 'package:wissal_app/model/chat_model.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/pages/Homepage/home_page.dart';
import 'package:wissal_app/services/cache/message_cache_service.dart';
import 'package:wissal_app/services/notifications/notification_service.dart';

class GroupController extends GetxController {
  RxList<UserModel> selectedMembers = <UserModel>[].obs; // للتوافق
  RxList<GroupMember> groupMembers = <GroupMember>[].obs;
  final db = Supabase.instance.client;
  final auth = Supabase.instance.client.auth;
  final uuid = Uuid();
  RxBool isLoading = false.obs;
  RxBool isSending = false.obs;
  RxBool isLoadingFromCache = false.obs;
  RxList<GroupModel> groupList = <GroupModel>[].obs;
  ProfileController get profileController => Get.find<ProfileController>();

  // Cache service
  MessageCacheService? get _cacheService {
    try {
      return Get.find<MessageCacheService>();
    } catch (e) {
      return null;
    }
  }

  RxString selectedImagePath = ''.obs;
  RxString selectedAudioPath = ''.obs;

  Rx<GroupModel?> currentGroup = Rx<GroupModel?>(null);

  @override
  void onInit() {
    super.onInit();
    getGroups();
  }

  void selectMember(UserModel user) {
    if (selectedMembers.any((u) => u.id == user.id)) {
      selectedMembers.removeWhere((u) => u.id == user.id);
    } else {
      selectedMembers.add(user);
    }
  }

  void clearSelectedMembers() {
    selectedMembers.clear();
  }

  Future<GroupModel?> createGroup({
    required String groupName,
    String? description,
    String? imagePath,
  }) async {
    isLoading.value = true;

    if (groupName.trim().isEmpty) {
      showError("يرجى إدخال اسم المجموعة");
      isLoading.value = false;
      return null;
    }

    final currentUserId = auth.currentUser?.id;
    if (currentUserId == null) {
      showError("لم يتم تسجيل الدخول");
      isLoading.value = false;
      return null;
    }

    try {
      final groupId = uuid.v4();
      String? imgUrl;

      if (imagePath != null &&
          imagePath.isNotEmpty &&
          File(imagePath).existsSync()) {
        imgUrl = await profileController.uploadeFileToSupabase(imagePath);
      }

      final now = DateTime.now().toIso8601String();
      final currentUser = profileController.currentUser.value;

      final members = <GroupMember>[
        GroupMember(
          odId: currentUserId,
          name: currentUser.name ?? 'User',
          profileImage: currentUser.profileimage,
          role: MemberRole.owner,
          joinedAt: DateTime.now(),
        ),
        ...selectedMembers.map((user) => GroupMember(
              odId: user.id ?? '',
              name: user.name ?? '',
              profileImage: user.profileimage,
              role: MemberRole.member,
              joinedAt: DateTime.now(),
            )),
      ];

      final newGroup = GroupModel(
        id: groupId,
        name: groupName,
        description: description,
        profileUrl: imgUrl ?? '',
        groupMembers: members,
        createdAt: now,
        createdBy: currentUserId,
        timestamp: now,
        settings: const GroupSettings(),
      );

      await db.from('groups').insert(newGroup.toJson());

      selectedMembers.clear();
      await getGroups();

      Get.snackbar(
        "تم",
        "تم إنشاء المجموعة بنجاح",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return newGroup;
    } catch (e) {
      showError("حدث خطأ أثناء إنشاء المجموعة: $e");
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> creatGroup(String groupName, String imagePath) async {
    final group = await createGroup(
      groupName: groupName,
      imagePath: imagePath,
    );
    if (group != null) {
      Get.offAll(() => HomePage());
    }
  }

  Future<void> getGroups() async {
    isLoading.value = true;
    final currentUserId = auth.currentUser?.id;

    if (currentUserId == null) {
      isLoading.value = false;
      return;
    }

    try {
      final response = await db.from('groups').select();

      if (response is List) {
        groupList.value = response
            .map((item) => GroupModel.fromJson(item))
            .where((group) => group.isMember(currentUserId))
            .toList();
      } else {
        groupList.clear();
      }

      print("✅ عدد المجموعات: ${groupList.length}");
    } catch (e) {
      print("❌ خطأ في تحميل المجموعات: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final response =
          await db.from('groups').select().eq('id', groupId).maybeSingle();

      if (response != null) {
        return GroupModel.fromJson(response);
      }
    } catch (e) {
      print("❌ خطأ في جلب المجموعة: $e");
    }
    return null;
  }

  void setCurrentGroup(GroupModel group) {
    currentGroup.value = group;
  }

  Future<bool> updateGroupName(String groupId, String newName) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      final group = await getGroupById(groupId);
      if (group == null || !group.canEditInfo(currentUserId)) {
        showError("ليس لديك صلاحية لتعديل المجموعة");
        return false;
      }

      await db.from('groups').update({'name': newName}).eq('id', groupId);
      await getGroups();

      Get.snackbar("تم", "تم تحديث اسم المجموعة");
      return true;
    } catch (e) {
      showError("فشل تحديث الاسم: $e");
      return false;
    }
  }

  Future<bool> updateGroupImage(String groupId, String imagePath) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      final group = await getGroupById(groupId);
      if (group == null || !group.canEditInfo(currentUserId)) {
        showError("ليس لديك صلاحية لتعديل المجموعة");
        return false;
      }

      isLoading.value = true;
      final imgUrl = await profileController.uploadeFileToSupabase(imagePath);
      await db.from('groups').update({'profileUrl': imgUrl}).eq('id', groupId);
      await getGroups();

      Get.snackbar("تم", "تم تحديث صورة المجموعة");
      return true;
    } catch (e) {
      showError("فشل تحديث الصورة: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateGroupDescription(
      String groupId, String description) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      final group = await getGroupById(groupId);
      if (group == null || !group.canEditInfo(currentUserId)) {
        showError("ليس لديك صلاحية لتعديل المجموعة");
        return false;
      }

      await db
          .from('groups')
          .update({'description': description}).eq('id', groupId);
      await getGroups();

      Get.snackbar("تم", "تم تحديث وصف المجموعة");
      return true;
    } catch (e) {
      showError("فشل التحديث: $e");
      return false;
    }
  }

  /// Send a system message to the group
  Future<void> _sendSystemMessage({
    required String groupId,
    required String message,
  }) async {
    try {
      final chatId = uuid.v4();
      final now = DateTime.now().toIso8601String();

      await db.from('group_chats').insert({
        'id': chatId,
        'groupId': groupId,
        'message': message,
        'messageType': 'system',
        'timeStamp': now,
        'senderId': 'system',
        'senderName': 'النظام',
      });
    } catch (e) {
      print("❌ خطأ في إرسال رسالة النظام: $e");
    }
  }

  Future<bool> addMembersToGroup(
      String groupId, List<UserModel> newMembers) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      final group = await getGroupById(groupId);
      if (group == null || !group.canAddMembers(currentUserId)) {
        showError("ليس لديك صلاحية لإضافة أعضاء");
        return false;
      }

      final currentUser = profileController.currentUser.value;
      final updatedMembers = List<GroupMember>.from(group.groupMembers);

      for (final user in newMembers) {
        if (!updatedMembers.any((m) => m.odId == user.id)) {
          updatedMembers.add(GroupMember(
            odId: user.id ?? '',
            name: user.name ?? '',
            profileImage: user.profileimage,
            role: MemberRole.member,
            joinedAt: DateTime.now(),
          ));

          // Send system message for each added member
          await _sendSystemMessage(
            groupId: groupId,
            message: "تم إضافة ${user.name ?? 'عضو'} بواسطة ${currentUser.name ?? 'المشرف'}",
          );
        }
      }

      await db.from('groups').update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
      }).eq('id', groupId);

      // Send notification to added members
      final notificationService = NotificationService();
      final addedMemberIds = newMembers.map((m) => m.id ?? '').toList();
      await notificationService.sendGroupEventNotification(
        receiverIds: addedMemberIds,
        eventType: NotificationType.groupAdd,
        groupId: groupId,
        groupName: group.name ?? 'مجموعة',
        targetUserName: currentUser.name ?? 'المشرف',
        adminName: currentUser.name,
      );

      await getGroups();
      Get.snackbar("تم", "تم إضافة ${newMembers.length} عضو");
      return true;
    } catch (e) {
      showError("فشل إضافة الأعضاء: $e");
      return false;
    }
  }

  Future<bool> removeMemberFromGroup(String groupId, String memberId) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      final group = await getGroupById(groupId);
      if (group == null || !group.canRemoveMember(currentUserId, memberId)) {
        showError("ليس لديك صلاحية لإزالة هذا العضو");
        return false;
      }

      final currentUser = profileController.currentUser.value;
      final removedMember = group.groupMembers.firstWhere(
        (m) => m.odId == memberId,
        orElse: () => GroupMember(odId: '', name: 'عضو', joinedAt: DateTime.now()),
      );

      final updatedMembers =
          group.groupMembers.where((m) => m.odId != memberId).toList();

      await db.from('groups').update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
      }).eq('id', groupId);

      // Send system message
      await _sendSystemMessage(
        groupId: groupId,
        message: "تم إزالة ${removedMember.name} بواسطة ${currentUser.name ?? 'المشرف'}",
      );

      await getGroups();
      Get.snackbar("تم", "تم إزالة العضو من المجموعة");
      return true;
    } catch (e) {
      showError("فشل إزالة العضو: $e");
      return false;
    }
  }

  Future<bool> leaveGroup(String groupId) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      final group = await getGroupById(groupId);
      if (group == null) return false;

      if (group.isOwner(currentUserId)) {
        showError(
            "لا يمكن للمالك مغادرة المجموعة. قم بنقل الملكية أو حذف المجموعة");
        return false;
      }

      final updatedMembers =
          group.groupMembers.where((m) => m.odId != currentUserId).toList();

      await db.from('groups').update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
      }).eq('id', groupId);

      await getGroups();
      Get.snackbar("تم", "تم مغادرة المجموعة");
      return true;
    } catch (e) {
      showError("فشل مغادرة المجموعة: $e");
      return false;
    }
  }

  Future<bool> promoteToAdmin(String groupId, String memberId) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      final group = await getGroupById(groupId);
      if (group == null || !group.canPromoteToAdmin(currentUserId)) {
        showError("فقط مالك المجموعة يمكنه ترقية المشرفين");
        return false;
      }

      final promotedMember = group.groupMembers.firstWhere(
        (m) => m.odId == memberId,
        orElse: () => GroupMember(odId: '', name: 'عضو', joinedAt: DateTime.now()),
      );

      final updatedMembers = group.groupMembers.map((m) {
        if (m.odId == memberId) {
          return m.copyWith(role: MemberRole.admin);
        }
        return m;
      }).toList();

      await db.from('groups').update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
      }).eq('id', groupId);

      // Send system message
      await _sendSystemMessage(
        groupId: groupId,
        message: "${promotedMember.name} أصبح مشرفاً",
      );

      // Send notification to the promoted member
      final notificationService = NotificationService();
      await notificationService.sendGroupEventNotification(
        receiverIds: [memberId],
        eventType: NotificationType.groupPromote,
        groupId: groupId,
        groupName: group.name ?? 'مجموعة',
        targetUserName: promotedMember.name,
      );

      await getGroups();
      Get.snackbar("تم", "تم ترقية العضو إلى مشرف");
      return true;
    } catch (e) {
      showError("فشل الترقية: $e");
      return false;
    }
  }

  Future<bool> demoteFromAdmin(String groupId, String memberId) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      final group = await getGroupById(groupId);
      if (group == null || !group.canDemoteAdmin(currentUserId)) {
        showError("فقط مالك المجموعة يمكنه إزالة صلاحيات المشرف");
        return false;
      }

      if (memberId == group.createdBy) {
        showError("لا يمكن إزالة صلاحيات المالك");
        return false;
      }

      final demotedMember = group.groupMembers.firstWhere(
        (m) => m.odId == memberId,
        orElse: () => GroupMember(odId: '', name: 'عضو', joinedAt: DateTime.now()),
      );

      final updatedMembers = group.groupMembers.map((m) {
        if (m.odId == memberId) {
          return m.copyWith(role: MemberRole.member);
        }
        return m;
      }).toList();

      await db.from('groups').update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
      }).eq('id', groupId);

      // Send system message
      await _sendSystemMessage(
        groupId: groupId,
        message: "تم إزالة صلاحيات المشرف من ${demotedMember.name}",
      );

      await getGroups();
      Get.snackbar("تم", "تم إزالة صلاحيات المشرف");
      return true;
    } catch (e) {
      showError("فشل الإزالة: $e");
      return false;
    }
  }

  Future<bool> toggleGroupLock(String groupId) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      final group = await getGroupById(groupId);
      if (group == null || !group.isAdmin(currentUserId)) {
        showError("فقط المشرفين يمكنهم قفل/فتح المجموعة");
        return false;
      }

      final newSettings =
          group.settings.copyWith(isLocked: !group.settings.isLocked);

      await db.from('groups').update({
        'settings': newSettings.toJson(),
      }).eq('id', groupId);

      await getGroups();
      Get.snackbar(
        "تم",
        newSettings.isLocked ? "تم قفل المجموعة" : "تم فتح المجموعة",
      );
      return true;
    } catch (e) {
      showError("فشل تغيير حالة القفل: $e");
      return false;
    }
  }

  Future<bool> muteMember(String groupId, String memberId,
      {Duration? duration}) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      final group = await getGroupById(groupId);
      if (group == null || !group.isAdmin(currentUserId)) {
        showError("فقط المشرفين يمكنهم كتم الأعضاء");
        return false;
      }

      if (group.isAdmin(memberId)) {
        showError("لا يمكن كتم المشرفين");
        return false;
      }

      final mutedUntil = duration != null ? DateTime.now().add(duration) : null;

      final updatedMembers = group.groupMembers.map((m) {
        if (m.odId == memberId) {
          return m.copyWith(isMuted: true, mutedUntil: mutedUntil);
        }
        return m;
      }).toList();

      await db.from('groups').update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
      }).eq('id', groupId);

      await getGroups();
      Get.snackbar("تم", "تم كتم العضو");
      return true;
    } catch (e) {
      showError("فشل الكتم: $e");
      return false;
    }
  }

  Future<bool> unmuteMember(String groupId, String memberId) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      final group = await getGroupById(groupId);
      if (group == null || !group.isAdmin(currentUserId)) {
        showError("فقط المشرفين يمكنهم إلغاء كتم الأعضاء");
        return false;
      }

      final updatedMembers = group.groupMembers.map((m) {
        if (m.odId == memberId) {
          return m.copyWith(isMuted: false, clearMutedUntil: true);
        }
        return m;
      }).toList();

      await db.from('groups').update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
      }).eq('id', groupId);

      await getGroups();
      Get.snackbar("تم", "تم إلغاء كتم العضو");
      return true;
    } catch (e) {
      showError("فشل إلغاء الكتم: $e");
      return false;
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      final group = await getGroupById(groupId);
      if (group == null || !group.isOwner(currentUserId)) {
        showError("فقط مالك المجموعة يمكنه حذفها");
        return false;
      }

      await db.from('group_chats').delete().eq('groupId', groupId);
      await db.from('groups').delete().eq('id', groupId);

      await getGroups();
      Get.snackbar("تم", "تم حذف المجموعة");
      return true;
    } catch (e) {
      showError("فشل حذف المجموعة: $e");
      return false;
    }
  }

  Future<void> sendGroupMessage(
    String groupId,
    String message, {
    bool isVoice = false,
  }) async {
    print("🚀 بدء إرسال رسالة إلى المجموعة $groupId");

    final currentUserId = auth.currentUser?.id;
    if (currentUserId == null) {
      showError("يرجى تسجيل الدخول");
      return;
    }

    final group = await getGroupById(groupId);
    if (group == null) {
      showError("المجموعة غير موجودة");
      return;
    }

    if (!group.canSendMessage(currentUserId)) {
      if (group.settings.isLocked) {
        showError("المجموعة مقفلة - فقط المشرفين يمكنهم الإرسال");
      } else {
        showError("لا يمكنك الإرسال في هذه المجموعة");
      }
      return;
    }

    isLoading.value = true;
    isSending.value = true;

    final chatId = uuid.v4();
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
        readStatus: 'Sent',
      );

      await db.from('group_chats').insert({
        ...newChat.toMap(),
        'groupId': groupId,
        'deliveredTo': [currentUserId],
        'seenBy': [currentUserId],
      });

      print("✅ تم إرسال الرسالة بنجاح إلى group_chats");

      String lastMsg = message.isNotEmpty
          ? message
          : imageUrl.value.isNotEmpty
              ? '📷 صورة'
              : audioUrl.value.isNotEmpty
                  ? '🎤 صوت'
                  : '';

      await db.from('groups').update({
        'last_message': lastMsg,
        'timeStamp': now,
        'lastMessageSenderId': currentUserId,
      }).eq('id', groupId);

      // تحديث الكاش
      _cacheService?.addGroupMessageToCache(groupId, newChat);

      // Send push notifications to all group members
      final notificationService = NotificationService();
      final memberIds = group.groupMembers.map((m) => m.odId).toList();

      if (message.isNotEmpty) {
        // Text message notification
        await notificationService.sendGroupNotification(
          groupId: groupId,
          memberIds: memberIds,
          senderName: sender.name ?? 'مستخدم',
          messageText: message,
          groupName: group.name ?? 'مجموعة',
          type: NotificationType.message,
        );
      } else if (imageUrl.value.isNotEmpty) {
        // Image notification
        await notificationService.sendGroupNotification(
          groupId: groupId,
          memberIds: memberIds,
          senderName: sender.name ?? 'مستخدم',
          messageText: '',
          groupName: group.name ?? 'مجموعة',
          type: NotificationType.image,
          imageUrl: imageUrl.value,
        );
      } else if (audioUrl.value.isNotEmpty) {
        // Voice notification
        await notificationService.sendGroupNotification(
          groupId: groupId,
          memberIds: memberIds,
          senderName: sender.name ?? 'مستخدم',
          messageText: '',
          groupName: group.name ?? 'مجموعة',
          type: NotificationType.voice,
        );
      }

      print("🆗 تم تحديث بيانات المجموعة بنجاح");
    } catch (e) {
      print("❌ خطأ أثناء إرسال الرسالة: $e");
      showError("حدث خطأ أثناء إرسال الرسالة");
    } finally {
      selectedImagePath.value = "";
      selectedAudioPath.value = "";
      isLoading.value = false;
      isSending.value = false;
    }
  }

  Stream<List<ChatModel>> getGroupMessages(String groupId) {
    // أولاً: تحميل من الكاش بشكل متزامن للعرض الفوري
    isLoadingFromCache.value = true;

    return db
        .from('group_chats')
        .stream(primaryKey: ['id'])
        .eq('groupId', groupId)
        .order('timeStamp')
        .map((data) {
          try {
            final messages = data.map((e) => ChatModel.fromJson(e)).toList();
            // تحديث الكاش بالرسائل الجديدة
            _cacheService?.cacheGroupMessages(groupId, messages);
            isLoadingFromCache.value = false;
            return messages;
          } catch (e) {
            print("❌ خطأ في تحويل الرسائل: $e");
            isLoadingFromCache.value = false;
            return [];
          }
        });
  }

  /// الحصول على رسائل المجموعة من الكاش أولاً
  List<ChatModel> getCachedGroupMessages(String groupId) {
    return _cacheService?.getCachedGroupMessages(groupId) ?? [];
  }

  /// التحقق من وجود كاش للمجموعة
  bool hasCachedGroupMessages(String groupId) {
    return _cacheService?.hasCachedGroupMessages(groupId) ?? false;
  }

  Future<void> markMessageAsDelivered(String messageId, String odId) async {
    try {
      final response = await db
          .from('group_chats')
          .select('deliveredTo')
          .eq('id', messageId)
          .maybeSingle();

      if (response == null) return;

      List<String> deliveredTo = [];
      if (response['deliveredTo'] is List) {
        deliveredTo = List<String>.from(response['deliveredTo']);
      }

      if (!deliveredTo.contains(odId)) {
        deliveredTo.add(odId);
        await db.from('group_chats').update({
          'deliveredTo': deliveredTo,
        }).eq('id', messageId);
      }
    } catch (e) {
      print("❌ خطأ في تحديث حالة التسليم: $e");
    }
  }

  Future<void> markMessageAsSeen(String messageId, String odId) async {
    try {
      final response = await db
          .from('group_chats')
          .select('seenBy')
          .eq('id', messageId)
          .maybeSingle();

      if (response == null) return;

      List<String> seenBy = [];
      if (response['seenBy'] is List) {
        seenBy = List<String>.from(response['seenBy']);
      }

      if (!seenBy.contains(odId)) {
        seenBy.add(odId);
        await db.from('group_chats').update({
          'seenBy': seenBy,
        }).eq('id', messageId);
      }
    } catch (e) {
      print("❌ خطأ في تحديث حالة المشاهدة: $e");
    }
  }

  Future<void> markAllMessagesAsSeenInGroup(String groupId) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return;

      final messages = await db
          .from('group_chats')
          .select('id, seenBy')
          .eq('groupId', groupId);

      for (final msg in messages) {
        List<String> seenBy = [];
        if (msg['seenBy'] is List) {
          seenBy = List<String>.from(msg['seenBy']);
        }

        if (!seenBy.contains(currentUserId)) {
          seenBy.add(currentUserId);
          await db.from('group_chats').update({
            'seenBy': seenBy,
          }).eq('id', msg['id']);
        }
      }
    } catch (e) {
      print("❌ خطأ في تحديث حالة المشاهدة: $e");
    }
  }

  Future<List<String>> getMessageSeenBy(String messageId) async {
    try {
      final response = await db
          .from('group_chats')
          .select('seenBy')
          .eq('id', messageId)
          .maybeSingle();

      if (response != null && response['seenBy'] is List) {
        return List<String>.from(response['seenBy']);
      }
    } catch (e) {
      print("❌ خطأ: $e");
    }
    return [];
  }

  Future<List<String>> getMessageDeliveredTo(String messageId) async {
    try {
      final response = await db
          .from('group_chats')
          .select('deliveredTo')
          .eq('id', messageId)
          .maybeSingle();

      if (response != null && response['deliveredTo'] is List) {
        return List<String>.from(response['deliveredTo']);
      }
    } catch (e) {
      print("❌ خطأ: $e");
    }
    return [];
  }

  void showError(String message) {
    Get.snackbar(
      "خطأ",
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
    isLoading.value = false;
  }

  void showSuccess(String message) {
    Get.snackbar(
      "تم",
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Edit a group message
  Future<bool> editGroupMessage(String messageId, String newText) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      // Verify the message belongs to the current user
      final response = await db
          .from('group_chats')
          .select('senderId')
          .eq('id', messageId)
          .maybeSingle();

      if (response == null || response['senderId'] != currentUserId) {
        showError("لا يمكنك تعديل هذه الرسالة");
        return false;
      }

      await db.from('group_chats').update({
        'message': newText,
        'isEdited': true,
      }).eq('id', messageId);

      showSuccess("تم تعديل الرسالة");
      return true;
    } catch (e) {
      showError("فشل تعديل الرسالة: $e");
      return false;
    }
  }

  /// Delete a group message (soft delete)
  Future<bool> deleteGroupMessage(
    String groupId,
    String messageId, {
    bool isAdmin = false,
  }) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      final group = await getGroupById(groupId);
      if (group == null) return false;

      // Get message info
      final response = await db
          .from('group_chats')
          .select('senderId')
          .eq('id', messageId)
          .maybeSingle();

      if (response == null) return false;

      final isSender = response['senderId'] == currentUserId;
      final isGroupAdmin = group.isAdmin(currentUserId);

      if (!isSender && !isGroupAdmin) {
        showError("ليس لديك صلاحية لحذف هذه الرسالة");
        return false;
      }

      final currentUser = profileController.currentUser.value;

      // Soft delete with admin info if deleted by admin
      if (isGroupAdmin && !isSender) {
        await db.from('group_chats').update({
          'isDeleted': true,
          'deletedBy': currentUserId,
          'deletedByName': currentUser.name ?? 'المشرف',
        }).eq('id', messageId);
      } else {
        await db.from('group_chats').update({
          'isDeleted': true,
        }).eq('id', messageId);
      }

      showSuccess("تم حذف الرسالة");
      return true;
    } catch (e) {
      showError("فشل حذف الرسالة: $e");
      return false;
    }
  }

  /// Add reaction to a group message
  Future<void> addGroupReaction(String messageId, String emoji) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    try {
      // Get current reactions
      final response = await db
          .from('group_chats')
          .select('reactions')
          .eq('id', messageId)
          .maybeSingle();

      if (response == null) return;

      List<String> reactions = [];
      if (response['reactions'] != null) {
        if (response['reactions'] is List) {
          reactions = List<String>.from(response['reactions']);
        } else if (response['reactions'] is String) {
          try {
            final decoded = jsonDecode(response['reactions']);
            if (decoded is List) {
              reactions = List<String>.from(decoded);
            }
          } catch (_) {}
        }
      }

      // Remove previous reaction from this user
      reactions.removeWhere((r) => r.contains(':${currentUser.id}'));

      // Add new reaction if emoji is not empty
      if (emoji.isNotEmpty) {
        reactions.add('$emoji:${currentUser.id}');
      }

      // Save to database
      await db.from('group_chats').update({
        'reactions': jsonEncode(reactions),
      }).eq('id', messageId);

      print('✅ تم إضافة التفاعل: $emoji');
    } catch (e) {
      print('❌ خطأ في إضافة التفاعل: $e');
    }
  }

  /// Remove reaction from a group message
  Future<void> removeGroupReaction(String messageId) async {
    await addGroupReaction(messageId, '');
  }

  /// Forward a message to another group or chat
  Future<bool> forwardGroupMessage({
    required ChatModel message,
    required String toGroupId,
  }) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      final sender = profileController.currentUser.value;
      final chatId = uuid.v4();
      final now = DateTime.now().toIso8601String();

      await db.from('group_chats').insert({
        'id': chatId,
        'groupId': toGroupId,
        'senderId': sender.id,
        'senderName': sender.name,
        'message': message.message ?? '',
        'imageUrl': message.imageUrl ?? '',
        'audioUrl': message.audioUrl ?? '',
        'timeStamp': now,
        'isForwarded': true,
        'forwardedFrom': message.senderName ?? 'مستخدم',
        'readStatus': 'Sent',
      });

      showSuccess("تم تحويل الرسالة");
      return true;
    } catch (e) {
      showError("فشل تحويل الرسالة: $e");
      return false;
    }
  }
}
