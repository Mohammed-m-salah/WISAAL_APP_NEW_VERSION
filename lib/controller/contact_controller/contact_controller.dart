import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/model/ChatRoomModel.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/controller/chat_controller/chat_controller.dart';
import 'package:wissal_app/widgets/glass_snackbar.dart';

class ContactController extends GetxController {
  final db = Supabase.instance.client;
  final auth = Supabase.instance.client.auth;

  RxBool isLoading = true.obs;
  RxBool hasLoadedInitially = false.obs;
  RxList<UserModel> userList = <UserModel>[].obs;
  RxList<ChatRoomModel> chatRoomList = <ChatRoomModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    getUserList();
    // استمع لتغييرات حالة المصادقة لتحميل غرف الدردشة عندما يكون المستخدم جاهزاً
    _initChatRooms();
  }

  /// تحميل غرف الدردشة مع انتظار جاهزية المصادقة
  Future<void> _initChatRooms() async {
    // إذا كان المستخدم موجود مباشرة
    if (auth.currentUser != null) {
      await getChatRoomList();
      return;
    }

    // انتظر تغيير حالة المصادقة
    auth.onAuthStateChange.listen((data) {
      if (data.session != null && data.event == AuthChangeEvent.signedIn) {
        getChatRoomList();
      }
    });
  }

  /// جلب كل المستخدمين المسجلين
  Future<void> getUserList() async {
    isLoading.value = true;
    try {
      final data = await db.from('save_users').select();
      userList.value =
          (data as List).map((e) => UserModel.fromJson(e)).toList();

      print("✅ عدد المستخدمين: ${userList.length}");
    } catch (error) {
      print("❌ خطأ أثناء جلب المستخدمين: $error");
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب غرف الدردشة الخاصة بالمستخدم الحالي مع بيانات الطرف الآخر
  Future<void> getChatRoomList() async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      // المستخدم غير جاهز بعد، سيتم الاستدعاء لاحقاً عند جاهزيته
      return;
    }

    isLoading.value = true;

    try {

      final userId = currentUser.id;

      final List roomData = await db.from('chat_rooms').select().or(
            'and(senderId.eq.$userId),and(reciverId.eq.$userId)',
          );

      final List<ChatRoomModel> fetchedRooms = [];

      // تحميل بيانات الغرف المثبتة والمؤرشفة من التخزين المحلي
      final pinnedData = await _loadPinnedRoomsFromLocal();
      final archivedIds = await _loadArchivedRoomsFromLocal();

      for (final room in roomData) {
        final chatRoom = ChatRoomModel.fromJson(room);
        print('================== 🧪🧪🧪🧪🧪🧪===================');
        print(
            "🧪 last_message: ${chatRoom.lastMessage}, lastTime: ${chatRoom.lastMessageTimeStamp}");

        // تطبيق بيانات التثبيت من التخزين المحلي
        if (chatRoom.id != null && pinnedData.containsKey(chatRoom.id)) {
          chatRoom.isPinned = true;
          chatRoom.pinOrder = pinnedData[chatRoom.id]!;
        }

        // تطبيق بيانات الأرشفة من التخزين المحلي
        if (chatRoom.id != null && archivedIds.contains(chatRoom.id)) {
          chatRoom.isArchived = true;
        }

        final otherUserId = chatRoom.senderId == userId
            ? chatRoom.reciverId
            : chatRoom.senderId;

        if (otherUserId != null) {
          final userData = await db
              .from('save_users')
              .select()
              .eq('id', otherUserId)
              .maybeSingle();

          if (userData != null) {
            chatRoom.receiver = UserModel.fromJson(userData);
          }
        }

        fetchedRooms.add(chatRoom);
      }

      // فصل الغرف المؤرشفة عن العادية
      final regularRooms = fetchedRooms.where((r) => !r.isArchived).toList();
      final archivedRooms = fetchedRooms.where((r) => r.isArchived).toList();

      // ترتيب الغرف العادية: المثبتة أولاً (حسب pinOrder)، ثم حسب آخر رسالة
      regularRooms.sort((a, b) {
        // المثبتة أولاً
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;

        // إذا كلاهما مثبت، رتب حسب pinOrder
        if (a.isPinned && b.isPinned) {
          return a.pinOrder.compareTo(b.pinOrder);
        }

        // إذا لم يكن أي منهما مثبت، رتب حسب آخر رسالة (الأحدث أولاً)
        final aTime = a.lastMessageTimeStamp ?? DateTime(1970);
        final bTime = b.lastMessageTimeStamp ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      // ترتيب الغرف المؤرشفة حسب آخر رسالة
      archivedRooms.sort((a, b) {
        final aTime = a.lastMessageTimeStamp ?? DateTime(1970);
        final bTime = b.lastMessageTimeStamp ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      chatRoomList.value = regularRooms;
      archivedChatRoomList.value = archivedRooms;

      print("✅ عدد غرف الدردشة: ${chatRoomList.length}");
    } catch (error) {
      print("❌ خطأ أثناء جلب غرف الدردشة: $error");
      chatRoomList.clear();
    } finally {
      isLoading.value = false;
      hasLoadedInitially.value = true;
    }
  }

  Future<void> saveContact(UserModel user) async {
    try {
      await db.from('save_users').insert(user.toJson());
    } catch (error) {
      if (kDebugMode) {
        print(" Error while saving contact: $error");
      }
    }
  }

  /// البحث عن مستخدم بالإيميل وإضافته للدردشة
  Future<void> searchUserByEmail(String email) async {
    try {
      isLoading.value = true;

      final response = await db
          .from('save_users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response != null) {
        final user = UserModel.fromJson(response);

        // التحقق من أن المستخدم ليس نفسه
        if (user.id == auth.currentUser?.id) {
          Get.snackbar(
            'error'.tr,
            'cannot_add_yourself'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        Get.snackbar(
          'success'.tr,
          'user_found'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );

        // تحديث قائمة المستخدمين
        if (!userList.any((u) => u.id == user.id)) {
          userList.add(user);
        }
      } else {
        Get.snackbar(
          'error'.tr,
          'user_not_found'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (error) {
      print("❌ Error searching user: $error");
      Get.snackbar(
        'error'.tr,
        'search_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// تحميل بيانات الغرف المثبتة من التخزين المحلي
  Future<Map<String, int>> _loadPinnedRoomsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? pinnedData = prefs.getString('pinned_chat_rooms');
    if (pinnedData != null) {
      final Map<String, dynamic> decoded = jsonDecode(pinnedData);
      return decoded.map((key, value) => MapEntry(key, value as int));
    }
    return {};
  }

  /// حفظ بيانات الغرف المثبتة في التخزين المحلي
  Future<void> _savePinnedRoomsToLocal(Map<String, int> pinnedRooms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pinned_chat_rooms', jsonEncode(pinnedRooms));
  }

  /// تثبيت غرفة دردشة (تخزين محلي)
  Future<void> pinChatRoom(String roomId) async {
    try {
      // تحميل الغرف المثبتة الحالية
      final pinnedData = await _loadPinnedRoomsFromLocal();

      // احصل على أعلى رقم ترتيب حالي
      final maxOrder = pinnedData.isEmpty
          ? 0
          : pinnedData.values.reduce((a, b) => a > b ? a : b);

      // إضافة الغرفة الجديدة
      pinnedData[roomId] = maxOrder + 1;
      await _savePinnedRoomsToLocal(pinnedData);

      // تحديث القائمة المحلية
      final index = chatRoomList.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        chatRoomList[index].isPinned = true;
        chatRoomList[index].pinOrder = maxOrder + 1;
        _sortChatRooms();
      }
      print("📌 تم تثبيت الغرفة بنجاح");
    } catch (error) {
      print("❌ خطأ في تثبيت الغرفة: $error");
    }
  }

  /// إلغاء تثبيت غرفة دردشة (تخزين محلي)
  Future<void> unpinChatRoom(String roomId) async {
    try {
      // تحميل وإزالة الغرفة
      final pinnedData = await _loadPinnedRoomsFromLocal();
      pinnedData.remove(roomId);
      await _savePinnedRoomsToLocal(pinnedData);

      // تحديث القائمة المحلية
      final index = chatRoomList.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        chatRoomList[index].isPinned = false;
        chatRoomList[index].pinOrder = 0;
        _sortChatRooms();
      }
      print("📌 تم إلغاء تثبيت الغرفة بنجاح");
    } catch (error) {
      print("❌ خطأ في إلغاء تثبيت الغرفة: $error");
    }
  }

  /// حذف غرفة دردشة بالكامل (مع جميع الرسائل) - يعود كأنه لم يتواصل من قبل
  Future<bool> deleteChatRoom(String roomId) async {
    try {
      // 1. حذف جميع الرسائل في الغرفة
      await db.from('chats').delete().eq('roomId', roomId);

      // 2. حذف الغرفة نفسها
      await db.from('chat_rooms').delete().eq('id', roomId);

      // 3. إزالة من بيانات التثبيت المحلية
      final pinnedData = await _loadPinnedRoomsFromLocal();
      pinnedData.remove(roomId);
      await _savePinnedRoomsToLocal(pinnedData);

      // 4. إزالة من الأرشيف المحلي
      final archivedIds = await _loadArchivedRoomsFromLocal();
      archivedIds.remove(roomId);
      await _saveArchivedRoomsToLocal(archivedIds);

      // 5. إزالة من القوائم المحلية
      chatRoomList.removeWhere((r) => r.id == roomId);
      archivedChatRoomList.removeWhere((r) => r.id == roomId);

      // 6. مسح الكاش المحلي للرسائل (إن وجد)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('chat_cache_$roomId');
        await prefs.remove('messages_$roomId');
      } catch (_) {}

      // 7. مسح كاش ChatController
      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().clearRoomCache(roomId);
      }

      GlassSnackbar.deleted(message: 'تم حذف الدردشة');
      print("🗑️ تم حذف الدردشة بالكامل - كأنه لم يتواصل من قبل");
      return true;
    } catch (error) {
      print("❌ خطأ في حذف الدردشة: $error");
      GlassSnackbar.error(title: 'خطأ', message: 'فشل حذف الدردشة');
      return false;
    }
  }

  /// حذف الدردشة مع مستخدم معين بالكامل
  Future<bool> deleteChatWithUser(String otherUserId) async {
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return false;

      // إنشاء roomId (نفس الطريقة المستخدمة في chat_controller)
      final List<String> ids = [currentUserId, otherUserId];
      ids.sort();
      final roomId = ids.join('_');

      return await deleteChatRoom(roomId);
    } catch (error) {
      print("❌ خطأ في حذف الدردشة مع المستخدم: $error");
      return false;
    }
  }

  /// إعادة ترتيب الغرف المثبتة (تخزين محلي)
  Future<void> reorderPinnedRooms(int oldIndex, int newIndex) async {
    try {
      final pinnedRooms = chatRoomList.where((r) => r.isPinned).toList();

      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final item = pinnedRooms.removeAt(oldIndex);
      pinnedRooms.insert(newIndex, item);

      // تحديث pinOrder في التخزين المحلي
      final Map<String, int> pinnedData = {};
      for (int i = 0; i < pinnedRooms.length; i++) {
        pinnedRooms[i].pinOrder = i + 1;
        if (pinnedRooms[i].id != null) {
          pinnedData[pinnedRooms[i].id!] = i + 1;
        }
      }
      await _savePinnedRoomsToLocal(pinnedData);

      _sortChatRooms();
      print("🔄 تم إعادة ترتيب الغرف المثبتة");
    } catch (error) {
      print("❌ خطأ في إعادة ترتيب الغرف: $error");
    }
  }

  /// دالة داخلية لإعادة ترتيب القائمة
  void _sortChatRooms() {
    final rooms = chatRoomList.toList();
    rooms.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      if (a.isPinned && b.isPinned) {
        return a.pinOrder.compareTo(b.pinOrder);
      }

      final aTime = a.lastMessageTimeStamp ?? DateTime(1970);
      final bTime = b.lastMessageTimeStamp ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
    chatRoomList.value = rooms;
  }

  /// الحصول على عدد الغرف المثبتة
  int get pinnedRoomsCount => chatRoomList.where((r) => r.isPinned).length;

  /// قائمة الغرف المؤرشفة
  RxList<ChatRoomModel> archivedChatRoomList = <ChatRoomModel>[].obs;

  /// تحميل بيانات الغرف المؤرشفة من التخزين المحلي
  Future<Set<String>> _loadArchivedRoomsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? archivedIds = prefs.getStringList('archived_chat_rooms');
    return archivedIds?.toSet() ?? {};
  }

  /// حفظ بيانات الغرف المؤرشفة في التخزين المحلي
  Future<void> _saveArchivedRoomsToLocal(Set<String> archivedRooms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('archived_chat_rooms', archivedRooms.toList());
  }

  /// أرشفة غرفة دردشة
  Future<void> archiveChatRoom(String roomId) async {
    try {
      final archivedIds = await _loadArchivedRoomsFromLocal();
      archivedIds.add(roomId);
      await _saveArchivedRoomsToLocal(archivedIds);

      // نقل الغرفة من القائمة العادية إلى المؤرشفة
      final roomIndex = chatRoomList.indexWhere((r) => r.id == roomId);
      if (roomIndex != -1) {
        final room = chatRoomList[roomIndex];
        room.isArchived = true;
        archivedChatRoomList.add(room);
        chatRoomList.removeAt(roomIndex);
      }
      print("📁 تم أرشفة المحادثة بنجاح");
    } catch (error) {
      print("❌ خطأ في أرشفة المحادثة: $error");
    }
  }

  /// إلغاء أرشفة غرفة دردشة
  Future<void> unarchiveChatRoom(String roomId) async {
    try {
      final archivedIds = await _loadArchivedRoomsFromLocal();
      archivedIds.remove(roomId);
      await _saveArchivedRoomsToLocal(archivedIds);

      // نقل الغرفة من المؤرشفة إلى القائمة العادية
      final roomIndex = archivedChatRoomList.indexWhere((r) => r.id == roomId);
      if (roomIndex != -1) {
        final room = archivedChatRoomList[roomIndex];
        room.isArchived = false;
        chatRoomList.add(room);
        archivedChatRoomList.removeAt(roomIndex);
        _sortChatRooms();
      }
      print("📁 تم إلغاء أرشفة المحادثة بنجاح");
    } catch (error) {
      print("❌ خطأ في إلغاء أرشفة المحادثة: $error");
    }
  }

  /// الحصول على عدد المحادثات المؤرشفة
  int get archivedRoomsCount => archivedChatRoomList.length;

  // Stream<List<UserModel>> getContacts() {
  //   return db
  //       .from('save_users')
  //       .stream(primaryKey: ['id'])
  //       .order('createdAt', ascending: false)
  //       .map((data) {
  //         return data.map((row) => UserModel.fromJson(row)).toList();
  //       });
  // }
  Stream<List<UserModel>> getContacts() {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      // إرجاع Stream فارغ إذا لم يكن هناك مستخدم مسجل
      return Stream.value([]);
    }
    final currentUserId = currentUser.id;

    return db
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('timeStamp', ascending: false)
        .map((data) async {
          final userIds = <String>{};

          for (var message in data) {
            // نأخذ فقط الرسائل التي يكون المستخدم طرفًا فيها
            if (message['senderId'] == currentUserId ||
                message['reciverId'] == currentUserId) {
              if (message['senderId'] != currentUserId) {
                userIds.add(message['senderId']);
              }
              if (message['reciverId'] != currentUserId) {
                userIds.add(message['reciverId']);
              }
            }
          }

          // تحميل معلومات المستخدمين الذين تواصلوا معنا
          final users = await Future.wait(userIds.map((userId) async {
            final user = await db
                .from('save_users') // تأكد أنك تجلب من الجدول الصحيح
                .select()
                .eq('id', userId)
                .maybeSingle();

            if (user != null) {
              return UserModel.fromJson(user);
            }
            return null;
          }));

          return users.whereType<UserModel>().toList();
        })
        .asyncExpand((future) => future.asStream());
  }
}
