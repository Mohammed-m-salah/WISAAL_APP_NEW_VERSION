import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
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

      for (final room in roomData) {
        final chatRoom = ChatRoomModel.fromJson(room);
        print('================== 🧪🧪🧪🧪🧪🧪===================');
        print(
            "🧪 last_message: ${chatRoom.lastMessage}, lastTime: ${chatRoom.lastMessageTimeStamp}");

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
