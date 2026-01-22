import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wissal_app/controller/contact_controller/contact_controller.dart';
import 'package:wissal_app/controller/profile_controller/profile_controller.dart';
import 'package:wissal_app/model/chat_model.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:record/record.dart';

class ChatController extends GetxController {
  @override
  void onInit() {
    super.onInit();

    auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        print("✅ الجلسة نشطة، بدء الاستماع للرسائل...");
        listenToIncomingMessages();
      }
    });

    if (auth.currentUser != null) {
      listenToIncomingMessages();
    }
  }

  @override
  void onClose() {
    _chatChannels.forEach((key, channel) {
      db.removeChannel(channel);
    });
    _chatChannels.clear();
    super.onClose();
  }

  final auth = Supabase.instance.client.auth;
  bool _isAlreadyListening = false;
  final db = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final isLoading = false.obs;
  final isSending = false.obs;
  final isTyping = false.obs;

  final uuid = Uuid();
  final profileController = Get.put(ProfileController());
  ContactController contactController = Get.put(ContactController());

  RxList<String> selectedImagePaths = <String>[].obs;
  final record = AudioRecorder();
  RxString currentChatRoomId = ''.obs;

  String path = '';
  String url = '';

  final isRecording = false.obs;
  RxString selectedAudioPath = ''.obs;

  Timer? _typingTimer;
  RxString typingUserId = ''.obs;
  RxBool isOtherUserTyping = false.obs;

  final Map<String, RealtimeChannel> _chatChannels = {};
  final Map<String, RealtimeChannel> _typingChannels = {};

  final RxMap<String, RxList<ChatModel>> _messagesCache =
      <String, RxList<ChatModel>>{}.obs;
  String getRoomId(String targetUserId) {
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      print('⚠️ تنبيه: محاولة جلب RoomId بدون تسجيل دخول');
      return "";
    }

    String currentUserId = currentUser.id;
    List<String> ids = [currentUserId, targetUserId];
    ids.sort();
    return ids.join('_');
  }

  UserModel getSender(UserModel currentUser, UserModel targetUser) {
    return currentUser.id == targetUser.id ? currentUser : targetUser;
  }

  UserModel getReciver(UserModel currentUser, UserModel targetUser) {
    return currentUser.id == targetUser.id ? targetUser : currentUser;
  }

  Future<void> sendMessage(
    String targetUserId,
    String message,
    UserModel targetUser, {
    bool isVoice = false,
  }) async {
    isLoading.value = true;
    isSending.value = true;

    final currentUser = auth.currentUser;
    if (currentUser == null) {
      Get.snackbar('خطأ', 'المستخدم غير مسجل الدخول');
      isLoading.value = false;
      isSending.value = false;
      return;
    }

    final chatId = uuid.v6();
    final roomId = getRoomId(targetUserId);
    final currentUserId = currentUser.id;
    final now = DateTime.now().toIso8601String();

    print('📤 sendMessage - targetUserId: $targetUserId');
    print('📤 sendMessage - roomId: $roomId');
    print('📤 sendMessage - currentUserId: $currentUserId');
    print('📤 sendMessage - message: $message');

    UserModel sender =
        getSender(profileController.currentUser.value, targetUser);
    UserModel reciver =
        getReciver(profileController.currentUser.value, targetUser);

    RxString audioUrl = ''.obs;
    List<String> uploadedImageUrls = [];

    if (selectedImagePaths.isNotEmpty) {
      for (String imagePath in selectedImagePaths) {
        String imgUrl =
            await profileController.uploadeFileToSupabase(imagePath);
        if (imgUrl.isNotEmpty) {
          uploadedImageUrls.add(imgUrl);
          print("✅ تم رفع الصورة: $imgUrl");
        }
      }
    }

    if (isVoice && selectedAudioPath.value.isNotEmpty) {
      audioUrl.value = await profileController
          .uploadeFileToSupabase(selectedAudioPath.value);
      print("✅ ملف الصوت: ${audioUrl.value}");
    }

    try {
      String imageUrlValue = '';
      if (uploadedImageUrls.isNotEmpty) {
        if (uploadedImageUrls.length == 1) {
          imageUrlValue = uploadedImageUrls.first;
        } else {
          imageUrlValue = jsonEncode(uploadedImageUrls);
        }
      }

      final newChat = ChatModel(
        id: chatId,
        message: message.isNotEmpty ? message : '',
        imageUrl: imageUrlValue,
        imageUrls: uploadedImageUrls,
        audioUrl: audioUrl.value,
        senderId: currentUserId,
        reciverId: targetUserId,
        senderName: profileController.currentUser.value.name,
        timeStamp: now,
      );

      await db.from('chats').insert({
        'id': chatId,
        'senderId': newChat.senderId,
        'reciverId': targetUserId,
        'senderName': newChat.senderName,
        'message': newChat.message,
        'imageUrl': imageUrlValue,
        'audioUrl': newChat.audioUrl,
        'timeStamp': newChat.timeStamp,
        'roomId': roomId,
      });

      String lastMessage = message.isNotEmpty
          ? message
          : uploadedImageUrls.isNotEmpty
              ? uploadedImageUrls.length > 1
                  ? '📷 ${uploadedImageUrls.length} صور'
                  : '📷 صورة'
              : audioUrl.value.isNotEmpty
                  ? '🎤 رسالة صوتية'
                  : '';

      await db.from('chat_rooms').upsert({
        'id': roomId,
        'senderId': currentUserId,
        'reciverId': targetUserId,
        'last_message': lastMessage,
        'last_message_time_stamp': now,
        'created_at': now,
        'un_read_message_no': 0,
      });
      await contactController.saveContact(targetUser);

      // تحديث قائمة غرف الدردشة لتظهر المحادثة الجديدة فوراً
      await contactController.getChatRoomList();
    } catch (e) {
      print("❌ Error sending message: $e");
      Get.snackbar('خطأ', 'حدث خطأ أثناء إرسال الرسالة');
    }

    selectedImagePaths.clear();
    selectedAudioPath.value = "";
    isLoading.value = false;
    isSending.value = false;
  }

  start_record() async {
    final location = await getApplicationDocumentsDirectory();
    String fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
    path = '${location.path}/$fileName';

    if (await record.hasPermission()) {
      await record.start(
        RecordConfig(),
        path: path,
      );
      isRecording.value = true;
      print('🎤 بدء التسجيل: $path');
    } else {
      print('❌ لا يوجد صلاحية للتسجيل');
    }
  }

  Future<String?> stop_record() async {
    String? finalPath = await record.stop();
    isRecording.value = false;

    if (finalPath != null) {
      selectedAudioPath.value = finalPath;
      print('🛑 توقف التسجيل: $finalPath');
      return finalPath;
    } else {
      print('❌ لم يتم حفظ الملف الصوتي');
      return null;
    }
  }

  Future<String> uploadAudioFile(String filePath) async {
    try {
      final supabase = Supabase.instance.client;
      final file = File(filePath);
      final fileName =
          'voice_${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';

      final fileBytes = await file.readAsBytes();

      await supabase.storage.from('avatars').uploadBinary(
            'audioUrl/$fileName',
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'audio/m4a',
            ),
          );

      final publicUrl =
          supabase.storage.from('avatars').getPublicUrl('audioUrl/$fileName');

      print('✅ تم رفع الملف الصوتي: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ خطأ أثناء رفع التسجيل: $e');
      return '';
    }
  }

  Future<void> sendVoiceMessage(
      String targetUserId, UserModel targetUser) async {
    if (selectedAudioPath.value.isEmpty) {
      Get.snackbar('خطأ', 'لا يوجد تسجيل صوتي');
      return;
    }

    isLoading.value = true;
    isSending.value = true;

    try {
      final audioUrl = await uploadAudioFile(selectedAudioPath.value);

      if (audioUrl.isEmpty) {
        Get.snackbar('خطأ', 'فشل رفع الملف الصوتي');
        return;
      }

      final currentUser = auth.currentUser;
      if (currentUser == null) {
        Get.snackbar('خطأ', 'المستخدم غير مسجل الدخول');
        return;
      }

      final chatId = uuid.v6();
      final roomId = getRoomId(targetUserId);
      final now = DateTime.now().toIso8601String();

      await db.from('chats').insert({
        'id': chatId,
        'senderId': currentUser.id,
        'reciverId': targetUserId,
        'senderName': profileController.currentUser.value.name,
        'message': '',
        'imageUrl': '',
        'audioUrl': audioUrl,
        'timeStamp': now,
        'roomId': roomId,
      });

      await db.from('chat_rooms').upsert({
        'id': roomId,
        'senderId': currentUser.id,
        'reciverId': targetUserId,
        'last_message': '🎤 رسالة صوتية',
        'last_message_time_stamp': now,
        'created_at': now,
        'un_read_message_no': 0,
      });

      await contactController.saveContact(targetUser);

      // تحديث قائمة غرف الدردشة لتظهر المحادثة الجديدة فوراً
      await contactController.getChatRoomList();

      print('✅ تم إرسال الرسالة الصوتية بنجاح');
    } catch (e) {
      print('❌ خطأ في إرسال الرسالة الصوتية: $e');
      Get.snackbar('خطأ', 'فشل إرسال الرسالة الصوتية');
    } finally {
      selectedAudioPath.value = '';
      isLoading.value = false;
      isSending.value = false;
    }
  }

  Future<void> playAudio(String url) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
      print('▶️ بدأ تشغيل الصوت');
    } catch (e) {
      print('❌ خطأ في تشغيل الصوت: $e');
    }
  }

  Future<void> deleteMessage(String messageId, String targetUserId) async {
    try {
      // بدل الحذف الفعلي، نقوم بتحديث الرسالة لتصبح محذوفة
      await db.from('chats').update({
        'isDeleted': true,
        'message': '',
        'imageUrl': '',
        'audioUrl': '',
      }).eq('id', messageId);
      print("✅ تم حذف الرسالة بنجاح");
      update();
    } catch (e) {
      print("❌ فشل في حذف الرسالة: $e");
      Get.snackbar("خطأ", "فشل حذف الرسالة");
    }
  }

  Future<void> editMessage(String messageId, String newMessage, String roomId) async {
    try {
      await db.from('chats').update({
        'message': newMessage,
        'isEdited': true,
      }).eq('id', messageId);
      print("✅ تم تعديل الرسالة بنجاح");
      update();
    } catch (e) {
      print("❌ فشل في تعديل الرسالة: $e");
      Get.snackbar("خطأ", "فشل تعديل الرسالة");
    }
  }

  Stream<List<ChatModel>> getMessages(String targetUserId) {
    final roomId = getRoomId(targetUserId);
    print('📨 getMessages - targetUserId: $targetUserId');
    print('📨 getMessages - roomId: $roomId');

    if (roomId.isEmpty) {
      print('❌ roomId فارغ! لا يمكن جلب الرسائل');
      return Stream.value([]);
    }

    final controller = StreamController<List<ChatModel>>.broadcast();

    if (!_messagesCache.containsKey(roomId)) {
      _messagesCache[roomId] = <ChatModel>[].obs;
    }

    _loadInitialMessages(roomId, controller);

    _setupRealtimeSubscription(roomId, controller);

    return controller.stream;
  }

  Future<void> _loadInitialMessages(
      String roomId, StreamController<List<ChatModel>> controller) async {
    try {
      final response = await db
          .from('chats')
          .select()
          .eq('roomId', roomId)
          .order('timeStamp', ascending: true);

      final messages =
          (response as List).map((row) => ChatModel.fromJson(row)).toList();
      _messagesCache[roomId]?.value = messages;
      controller.add(messages);
      print('📬 تم جلب ${messages.length} رسالة أولية');
    } catch (e) {
      print('❌ خطأ في جلب الرسائل الأولية: $e');
      controller.addError(e);
    }
  }

  void _setupRealtimeSubscription(
      String roomId, StreamController<List<ChatModel>> controller) {
    if (_chatChannels.containsKey(roomId)) {
      db.removeChannel(_chatChannels[roomId]!);
    }

    final channel = db.channel('chat_$roomId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chats',
          callback: (payload) {
            print('📩 رسالة جديدة وردت: ${payload.newRecord}');

            final messageRoomId = payload.newRecord['roomId'];
            if (messageRoomId != roomId) return;

            final newMessage = ChatModel.fromJson(payload.newRecord);

            if (!_messagesCache[roomId]!.any((m) => m.id == newMessage.id)) {
              _messagesCache[roomId]!.add(newMessage);
              controller.add(_messagesCache[roomId]!.toList());
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'chats',
          callback: (payload) {
            print('🗑️ رسالة محذوفة: ${payload.oldRecord}');
            final deletedId = payload.oldRecord['id'];
            if (deletedId == null) return;

            _messagesCache[roomId]!.removeWhere((m) => m.id == deletedId);
            controller.add(_messagesCache[roomId]!.toList());
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chats',
          callback: (payload) {
            print('✏️ رسالة محدثة: ${payload.newRecord}');

            final messageRoomId = payload.newRecord['roomId'];
            if (messageRoomId != roomId) return;

            final updatedMessage = ChatModel.fromJson(payload.newRecord);

            final index = _messagesCache[roomId]!
                .indexWhere((m) => m.id == updatedMessage.id);
            if (index != -1) {
              _messagesCache[roomId]![index] = updatedMessage;
              controller.add(_messagesCache[roomId]!.toList());
            }
          },
        )
        .subscribe((status, [error]) {
      print('📡 حالة الاشتراك: $status');
      if (error != null) {
        print('❌ خطأ في الاشتراك: $error');
      }
    });

    _chatChannels[roomId] = channel;
  }

  Future<List<UserModel>> filterUsers(String keyword) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        print('❌ المستخدم غير مسجل الدخول');
        return [];
      }
      final currentUserId = currentUser.id;

      final response = await db
          .from('users')
          .select()
          .neq('id', currentUserId)
          .ilike('name', '%$keyword%');

      final users = (response as List)
          .map((userData) => UserModel.fromJson(userData))
          .toList();

      return users;
    } catch (e) {
      print('❌ خطأ أثناء فلترة المستخدمين: $e');
      return [];
    }
  }

  void listenToIncomingMessages() {
    final currentUser = auth.currentUser;

    if (currentUser == null || _isAlreadyListening) return;

    _isAlreadyListening = true;
    final currentUserId = currentUser.id;

    db
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('reciverId', currentUserId)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            final message = data.last;
            final sender = message['senderName'] ?? 'مرسل مجهول';
            final text = message['message'] ?? '';
            final imageUrl = message['imageUrl'] ?? '';
            final audioUrl = message['audioUrl'] ?? '';
            final incomingRoomId = message['roomId'] ?? '';

            String messageTitle = '';
            if (audioUrl.isNotEmpty) {
              messageTitle = '🎤 أرسل رسالة صوتية';
            } else if (imageUrl.isNotEmpty) {
              messageTitle = '📷 أرسل صورة';
            } else if (text.isNotEmpty) {
              messageTitle = text;
            } else {
              messageTitle = '📩 رسالة جديدة';
            }

            if (incomingRoomId != currentChatRoomId.value) {}
          }
        }, onError: (error) {
          print("❌ خطأ في Stream الرسائل: $error");
        });
  }

  Stream<UserModel> getStatus(String uid) {
    return db
        .from('save_users')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .limit(1)
        .map((event) {
          if (event.isNotEmpty) {
            return UserModel.fromJson(event.first);
          } else {
            throw Exception("User not found");
          }
        });
  }

  Future<void> setTypingStatus(String targetUserId) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final roomId = getRoomId(targetUserId);
    if (roomId.isEmpty) return;

    _typingTimer?.cancel();

    try {
      await db.from('chat_rooms').upsert({
        'id': roomId,
        'senderId': currentUser.id,
        'reciverId': targetUserId,
        'typing_user_id': currentUser.id,
        'typing_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      print('⌨️ تم تحديث حالة الكتابة');
    } catch (e) {
      print('❌ خطأ في تحديث حالة الكتابة: $e');
    }

    _typingTimer = Timer(const Duration(seconds: 3), () {
      clearTypingStatus(targetUserId);
    });
  }

  Future<void> clearTypingStatus(String targetUserId) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final roomId = getRoomId(targetUserId);
    if (roomId.isEmpty) return;

    _typingTimer?.cancel();

    try {
      await db
          .from('chat_rooms')
          .update({
            'typing_user_id': null,
            'typing_at': null,
          })
          .eq('id', roomId)
          .eq('typing_user_id', currentUser.id);

      print('⌨️ تم إزالة حالة الكتابة');
    } catch (e) {
      print('❌ خطأ في إزالة حالة الكتابة: $e');
    }
  }

  void listenToTypingStatus(String targetUserId) {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final roomId = getRoomId(targetUserId);
    if (roomId.isEmpty) return;

    if (_typingChannels.containsKey(roomId)) {
      db.removeChannel(_typingChannels[roomId]!);
    }

    final channel = db.channel('typing_$roomId');

    channel
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'chat_rooms',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: roomId,
      ),
      callback: (payload) {
        final typingId = payload.newRecord['typing_user_id'];
        final typingAt = payload.newRecord['typing_at'];

        if (typingId != null && typingId != currentUser.id) {
          if (typingAt != null) {
            final typingTime = DateTime.tryParse(typingAt);
            if (typingTime != null) {
              final diff = DateTime.now().difference(typingTime);
              if (diff.inSeconds < 5) {
                isOtherUserTyping.value = true;
                typingUserId.value = typingId;
                print('⌨️ المستخدم الآخر يكتب...');
                return;
              }
            }
          }
        }

        isOtherUserTyping.value = false;
        typingUserId.value = '';
      },
    )
        .subscribe((status, [error]) {
      print('📡 حالة اشتراك Typing: $status');
      if (error != null) {
        print('❌ خطأ في اشتراك Typing: $error');
      }
    });

    _typingChannels[roomId] = channel;
  }

  void stopListeningToTypingStatus(String targetUserId) {
    final roomId = getRoomId(targetUserId);
    if (roomId.isEmpty) return;

    if (_typingChannels.containsKey(roomId)) {
      db.removeChannel(_typingChannels[roomId]!);
      _typingChannels.remove(roomId);
    }

    isOtherUserTyping.value = false;
    typingUserId.value = '';
  }
}
