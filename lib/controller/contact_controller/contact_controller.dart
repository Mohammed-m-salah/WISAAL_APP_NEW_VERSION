import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/model/ChatRoomModel.dart';
import 'package:wissal_app/model/user_model.dart';

class ContactController extends GetxController {
  final db = Supabase.instance.client;
  final auth = Supabase.instance.client.auth;

  RxBool isLoading = false.obs;
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

      // تحميل بيانات الغرف المثبتة من التخزين المحلي
      final pinnedData = await _loadPinnedRoomsFromLocal();

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

      // ترتيب الغرف: المثبتة أولاً (حسب pinOrder)، ثم حسب آخر رسالة
      fetchedRooms.sort((a, b) {
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

      chatRoomList.value = fetchedRooms;

      print("✅ عدد غرف الدردشة: ${chatRoomList.length}");
    } catch (error) {
      print("❌ خطأ أثناء جلب غرف الدردشة: $error");
      chatRoomList.clear();
    } finally {
      isLoading.value = false;
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

  /// حذف غرفة دردشة بالكامل (مع جميع الرسائل)
  Future<void> deleteChatRoom(String roomId) async {
    try {
      // حذف جميع الرسائل في الغرفة أولاً
      await db.from('chats').delete().eq('roomId', roomId);

      // ثم حذف الغرفة نفسها
      await db.from('chat_rooms').delete().eq('id', roomId);

      // إزالة من بيانات التثبيت المحلية
      final pinnedData = await _loadPinnedRoomsFromLocal();
      pinnedData.remove(roomId);
      await _savePinnedRoomsToLocal(pinnedData);

      // إزالة من القائمة المحلية
      chatRoomList.removeWhere((r) => r.id == roomId);
      print("🗑️ تم حذف الغرفة بنجاح");
    } catch (error) {
      print("❌ خطأ في حذف الغرفة: $error");
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
