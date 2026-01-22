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
import 'package:wissal_app/model/message_sync_status.dart';
import 'package:wissal_app/model/pending_message_model.dart';
import 'package:record/record.dart';

// Offline services
import 'package:wissal_app/services/local_database/local_database_service.dart';
import 'package:wissal_app/services/connectivity/connectivity_service.dart';
import 'package:wissal_app/services/sync/sync_service.dart';
import 'package:wissal_app/services/offline_queue/offline_queue_service.dart';

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

  // Offline services
  LocalDatabaseService get _localDb => Get.find<LocalDatabaseService>();
  ConnectivityService get _connectivity => Get.find<ConnectivityService>();
  SyncService get _syncService => Get.find<SyncService>();
  OfflineQueueService get _offlineQueue => Get.find<OfflineQueueService>();

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

  // متغيرات الرسائل المثبتة (دعم رسائل متعددة)
  RxList<ChatModel> pinnedMessages = <ChatModel>[].obs;

  final Map<String, RealtimeChannel> _chatChannels = {};
  final Map<String, RealtimeChannel> _typingChannels = {};
  final Set<String> _typingChannelsReady = {}; // لتتبع القنوات الجاهزة للإرسال

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

  /// Send message with offline support
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
    print('📤 sendMessage - isOnline: ${_connectivity.isOnline.value}');

    // Prepare image URLs
    List<String> imagePaths = List.from(selectedImagePaths);
    String imageUrlValue = '';

    // Prepare audio
    String audioPath = selectedAudioPath.value;

    // Create local message immediately for instant UI feedback
    final newChat = ChatModel(
      id: chatId,
      message: message.isNotEmpty ? message : '',
      imageUrl: imageUrlValue,
      imageUrls: [],
      audioUrl: '',
      senderId: currentUserId,
      reciverId: targetUserId,
      senderName: profileController.currentUser.value.name,
      timeStamp: now,
      syncStatus: MessageSyncStatus.pending,
      roomId: roomId,
    );

    // Add to local cache immediately for instant UI feedback
    if (!_messagesCache.containsKey(roomId)) {
      _messagesCache[roomId] = <ChatModel>[].obs;
    }
    _messagesCache[roomId]!.add(newChat);

    // Save to local database
    await _localDb.saveMessage(newChat);

    // Clear selected media
    selectedImagePaths.clear();
    selectedAudioPath.value = "";

    // Check if online
    if (_connectivity.isOnline.value) {
      // Online: send directly
      try {
        RxString audioUrl = ''.obs;
        List<String> uploadedImageUrls = [];

        // Upload images
        if (imagePaths.isNotEmpty) {
          for (String imagePath in imagePaths) {
            String imgUrl =
                await profileController.uploadeFileToSupabase(imagePath);
            if (imgUrl.isNotEmpty) {
              uploadedImageUrls.add(imgUrl);
              print("✅ تم رفع الصورة: $imgUrl");
            }
          }
        }

        // Upload audio
        if (isVoice && audioPath.isNotEmpty) {
          audioUrl.value = await profileController.uploadeFileToSupabase(audioPath);
          print("✅ ملف الصوت: ${audioUrl.value}");
        }

        // Prepare image URL value
        if (uploadedImageUrls.isNotEmpty) {
          if (uploadedImageUrls.length == 1) {
            imageUrlValue = uploadedImageUrls.first;
          } else {
            imageUrlValue = jsonEncode(uploadedImageUrls);
          }
        }

        // Insert to Supabase
        await db.from('chats').insert({
          'id': chatId,
          'senderId': currentUserId,
          'reciverId': targetUserId,
          'senderName': newChat.senderName,
          'message': newChat.message,
          'imageUrl': imageUrlValue,
          'audioUrl': audioUrl.value,
          'timeStamp': newChat.timeStamp,
          'roomId': roomId,
        });

        // Update last message
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
        await contactController.getChatRoomList();

        // Update message status to sent
        newChat.syncStatus = MessageSyncStatus.sent;
        newChat.imageUrl = imageUrlValue;
        newChat.imageUrls = uploadedImageUrls;
        newChat.audioUrl = audioUrl.value;
        await _localDb.saveMessage(newChat);

        // Update cache
        final index = _messagesCache[roomId]!.indexWhere((m) => m.id == chatId);
        if (index != -1) {
          _messagesCache[roomId]![index] = newChat;
        }

        print("✅ Message sent successfully");
      } catch (e) {
        print("❌ Error sending message: $e");
        // Mark as failed
        newChat.syncStatus = MessageSyncStatus.failed;
        await _localDb.saveMessage(newChat);
        Get.snackbar('خطأ', 'حدث خطأ أثناء إرسال الرسالة');
      }
    } else {
      // Offline: add to queue
      print("📴 Offline - Adding message to queue");

      final pendingMessage = PendingMessageModel(
        id: chatId,
        message: message,
        senderId: currentUserId,
        receiverId: targetUserId,
        senderName: profileController.currentUser.value.name ?? '',
        roomId: roomId,
        timeStamp: now,
        localImagePaths: imagePaths.isNotEmpty ? imagePaths : null,
        localAudioPath: audioPath.isNotEmpty ? audioPath : null,
        status: MessageSyncStatus.pending,
      );

      await _offlineQueue.enqueue(pendingMessage);
      Get.snackbar(
        'Offline',
        'Message will be sent when you\'re back online',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }

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

    final currentUser = auth.currentUser;
    if (currentUser == null) {
      Get.snackbar('خطأ', 'المستخدم غير مسجل الدخول');
      isLoading.value = false;
      isSending.value = false;
      return;
    }

    final chatId = uuid.v6();
    final roomId = getRoomId(targetUserId);
    final now = DateTime.now().toIso8601String();
    final audioPath = selectedAudioPath.value;

    // Create local message immediately
    final newChat = ChatModel(
      id: chatId,
      message: '',
      senderId: currentUser.id,
      reciverId: targetUserId,
      senderName: profileController.currentUser.value.name,
      timeStamp: now,
      audioUrl: '',
      syncStatus: MessageSyncStatus.pending,
      roomId: roomId,
    );

    // Add to local cache
    if (!_messagesCache.containsKey(roomId)) {
      _messagesCache[roomId] = <ChatModel>[].obs;
    }
    _messagesCache[roomId]!.add(newChat);
    await _localDb.saveMessage(newChat);

    selectedAudioPath.value = '';

    if (_connectivity.isOnline.value) {
      try {
        final audioUrl = await uploadAudioFile(audioPath);

        if (audioUrl.isEmpty) {
          newChat.syncStatus = MessageSyncStatus.failed;
          await _localDb.saveMessage(newChat);
          Get.snackbar('خطأ', 'فشل رفع الملف الصوتي');
          return;
        }

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
        await contactController.getChatRoomList();

        // Update status
        newChat.syncStatus = MessageSyncStatus.sent;
        newChat.audioUrl = audioUrl;
        await _localDb.saveMessage(newChat);

        // Update cache
        final index = _messagesCache[roomId]!.indexWhere((m) => m.id == chatId);
        if (index != -1) {
          _messagesCache[roomId]![index] = newChat;
        }

        print('✅ تم إرسال الرسالة الصوتية بنجاح');
      } catch (e) {
        print('❌ خطأ في إرسال الرسالة الصوتية: $e');
        newChat.syncStatus = MessageSyncStatus.failed;
        await _localDb.saveMessage(newChat);
        Get.snackbar('خطأ', 'فشل إرسال الرسالة الصوتية');
      }
    } else {
      // Offline
      final pendingMessage = PendingMessageModel(
        id: chatId,
        message: '',
        senderId: currentUser.id,
        receiverId: targetUserId,
        senderName: profileController.currentUser.value.name ?? '',
        roomId: roomId,
        timeStamp: now,
        localAudioPath: audioPath,
        status: MessageSyncStatus.pending,
      );

      await _offlineQueue.enqueue(pendingMessage);
      Get.snackbar(
        'Offline',
        'Voice message will be sent when online',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    isLoading.value = false;
    isSending.value = false;
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

      // Update local cache
      final roomId = getRoomId(targetUserId);
      final message = _localDb.getMessage(messageId);
      if (message != null) {
        message.isDeleted = true;
        message.message = '';
        message.imageUrl = '';
        message.audioUrl = '';
        await _localDb.saveMessage(message);
      }

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

      // Update local cache
      final message = _localDb.getMessage(messageId);
      if (message != null) {
        message.message = newMessage;
        message.isEdited = true;
        await _localDb.saveMessage(message);
      }

      print("✅ تم تعديل الرسالة بنجاح");
      update();
    } catch (e) {
      print("❌ فشل في تعديل الرسالة: $e");
      Get.snackbar("خطأ", "فشل تعديل الرسالة");
    }
  }

  /// Get messages with local-first loading
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

    // Step 1: Load from local database immediately
    _loadLocalMessages(roomId, controller);

    // Step 2: If online, sync with server
    if (_connectivity.isOnline.value) {
      _syncAndLoadMessages(roomId, controller);
    }

    // Step 3: Setup realtime subscription
    _setupRealtimeSubscription(roomId, controller);

    return controller.stream;
  }

  /// Load messages from local database
  Future<void> _loadLocalMessages(
      String roomId, StreamController<List<ChatModel>> controller) async {
    try {
      final localMessages = _localDb.getMessagesByRoom(roomId);

      // Also get pending messages for this room
      final pendingMessages = _localDb.getPendingMessagesByRoom(roomId);

      // Convert pending messages to ChatModel
      final pendingChatModels = pendingMessages.map((pm) => ChatModel(
        id: pm.id,
        message: pm.message,
        senderId: pm.senderId,
        reciverId: pm.receiverId,
        senderName: pm.senderName,
        timeStamp: pm.timeStamp,
        syncStatus: pm.status,
        roomId: pm.roomId,
      )).toList();

      // Merge local and pending, avoiding duplicates
      final allMessages = <ChatModel>[];
      final seenIds = <String>{};

      for (final msg in localMessages) {
        if (msg.id != null && !seenIds.contains(msg.id)) {
          allMessages.add(msg);
          seenIds.add(msg.id!);
        }
      }

      for (final msg in pendingChatModels) {
        if (msg.id != null && !seenIds.contains(msg.id)) {
          allMessages.add(msg);
          seenIds.add(msg.id!);
        }
      }

      // Sort by timestamp
      allMessages.sort((a, b) => (a.timeStamp ?? '').compareTo(b.timeStamp ?? ''));

      _messagesCache[roomId]?.value = allMessages;
      controller.add(allMessages);
      print('📬 Loaded ${localMessages.length} local + ${pendingMessages.length} pending messages');
    } catch (e) {
      print('❌ Error loading local messages: $e');
    }
  }

  /// Sync messages from server and update
  Future<void> _syncAndLoadMessages(
      String roomId, StreamController<List<ChatModel>> controller) async {
    try {
      final messages = await _syncService.syncMessagesForRoom(roomId);

      // Merge with pending messages
      final pendingMessages = _localDb.getPendingMessagesByRoom(roomId);
      final pendingChatModels = pendingMessages.map((pm) => ChatModel(
        id: pm.id,
        message: pm.message,
        senderId: pm.senderId,
        reciverId: pm.receiverId,
        senderName: pm.senderName,
        timeStamp: pm.timeStamp,
        syncStatus: pm.status,
        roomId: pm.roomId,
      )).toList();

      final allMessages = <ChatModel>[];
      final seenIds = <String>{};

      for (final msg in messages) {
        if (msg.id != null && !seenIds.contains(msg.id)) {
          allMessages.add(msg);
          seenIds.add(msg.id!);
        }
      }

      for (final msg in pendingChatModels) {
        if (msg.id != null && !seenIds.contains(msg.id)) {
          allMessages.add(msg);
          seenIds.add(msg.id!);
        }
      }

      allMessages.sort((a, b) => (a.timeStamp ?? '').compareTo(b.timeStamp ?? ''));

      _messagesCache[roomId]?.value = allMessages;
      controller.add(allMessages);
      print('📬 Synced ${messages.length} messages from server');
    } catch (e) {
      print('❌ Error syncing messages: $e');
    }
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

      // Save to local database
      await _localDb.saveMessages(messages);

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
              // Save to local database
              _localDb.saveMessage(newMessage);
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
            _localDb.deleteMessage(deletedId);
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
              _localDb.saveMessage(updatedMessage);
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

  /// إرسال حالة الكتابة عبر Broadcast channel (لا يحتاج أعمدة في قاعدة البيانات)
  Future<void> setTypingStatus(String targetUserId) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final roomId = getRoomId(targetUserId);
    if (roomId.isEmpty) return;

    // التحقق من جاهزية القناة
    if (!_typingChannelsReady.contains(roomId)) {
      print('⏳ القناة غير جاهزة بعد، تخطي إرسال حالة الكتابة');
      return;
    }

    _typingTimer?.cancel();

    try {
      // استخدام Broadcast channel بدلاً من تحديث قاعدة البيانات
      final channel = _typingChannels[roomId];
      if (channel != null) {
        await channel.sendBroadcastMessage(
          event: 'typing',
          payload: {
            'user_id': currentUser.id,
            'is_typing': true,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        print('⌨️ تم إرسال حالة الكتابة عبر Broadcast');
      }
    } catch (e) {
      print('❌ خطأ في إرسال حالة الكتابة: $e');
    }

    // إزالة حالة الكتابة تلقائياً بعد 3 ثواني
    _typingTimer = Timer(const Duration(seconds: 3), () {
      clearTypingStatus(targetUserId);
    });
  }

  /// إزالة حالة الكتابة
  Future<void> clearTypingStatus(String targetUserId) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final roomId = getRoomId(targetUserId);
    if (roomId.isEmpty) return;

    _typingTimer?.cancel();

    // التحقق من جاهزية القناة
    if (!_typingChannelsReady.contains(roomId)) {
      return;
    }

    try {
      final channel = _typingChannels[roomId];
      if (channel != null) {
        await channel.sendBroadcastMessage(
          event: 'typing',
          payload: {
            'user_id': currentUser.id,
            'is_typing': false,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        print('⌨️ تم إزالة حالة الكتابة');
      }
    } catch (e) {
      print('❌ خطأ في إزالة حالة الكتابة: $e');
    }
  }

  /// الاستماع لحالة الكتابة عبر Broadcast channel
  void listenToTypingStatus(String targetUserId) {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final roomId = getRoomId(targetUserId);
    if (roomId.isEmpty) return;

    // إزالة القناة القديمة إن وجدت
    if (_typingChannels.containsKey(roomId)) {
      db.removeChannel(_typingChannels[roomId]!);
      _typingChannelsReady.remove(roomId);
    }

    // إنشاء قناة Broadcast جديدة
    final channel = db.channel('typing_$roomId');

    channel
        .onBroadcast(
      event: 'typing',
      callback: (payload) {
        final userId = payload['user_id'];
        final isTypingNow = payload['is_typing'] ?? false;
        final timestamp = payload['timestamp'];

        print('📡 استقبال حالة كتابة: userId=$userId, isTyping=$isTypingNow');

        // تجاهل حالة الكتابة الخاصة بنا
        if (userId == currentUser.id) return;

        if (isTypingNow == true && timestamp != null) {
          final typingTime = DateTime.tryParse(timestamp);
          if (typingTime != null) {
            final diff = DateTime.now().difference(typingTime);
            // التحقق من أن حالة الكتابة حديثة (أقل من 5 ثواني)
            if (diff.inSeconds < 5) {
              isOtherUserTyping.value = true;
              typingUserId.value = userId;
              print('⌨️ المستخدم الآخر يكتب...');

              // إخفاء حالة الكتابة تلقائياً بعد 4 ثواني إذا لم تأتِ رسالة جديدة
              Future.delayed(const Duration(seconds: 4), () {
                if (isOtherUserTyping.value && typingUserId.value == userId) {
                  isOtherUserTyping.value = false;
                  typingUserId.value = '';
                }
              });
              return;
            }
          }
        }

        isOtherUserTyping.value = false;
        typingUserId.value = '';
      },
    )
        .subscribe((status, [error]) {
      print('📡 حالة اشتراك Typing: $status');
      if (status == RealtimeSubscribeStatus.subscribed) {
        _typingChannelsReady.add(roomId);
        print('✅ قناة الكتابة جاهزة للإرسال: $roomId');
      }
      if (error != null) {
        print('❌ خطأ في اشتراك Typing: $error');
      }
    });

    _typingChannels[roomId] = channel;
  }

  /// إيقاف الاستماع لحالة الكتابة
  void stopListeningToTypingStatus(String targetUserId) {
    final roomId = getRoomId(targetUserId);
    if (roomId.isEmpty) return;

    // إرسال حالة توقف الكتابة قبل إغلاق القناة
    clearTypingStatus(targetUserId);

    if (_typingChannels.containsKey(roomId)) {
      db.removeChannel(_typingChannels[roomId]!);
      _typingChannels.remove(roomId);
      _typingChannelsReady.remove(roomId);
    }

    isOtherUserTyping.value = false;
    typingUserId.value = '';
  }

  // ======================== تثبيت الرسائل ========================

  /// تثبيت رسالة في غرفة الدردشة (دعم رسائل متعددة)
  Future<void> pinMessage(String messageId, String messageText, String roomId) async {
    try {
      // التحقق من عدم تثبيت الرسالة مسبقاً
      if (pinnedMessages.any((m) => m.id == messageId)) {
        Get.snackbar("تنبيه", "هذه الرسالة مثبتة بالفعل", snackPosition: SnackPosition.BOTTOM);
        return;
      }

      // جلب قائمة الرسائل المثبتة الحالية
      final response = await db
          .from('chat_rooms')
          .select('pinned_message_ids')
          .eq('id', roomId)
          .maybeSingle();

      List<String> currentPinnedIds = [];
      if (response != null && response['pinned_message_ids'] != null) {
        currentPinnedIds = List<String>.from(jsonDecode(response['pinned_message_ids']));
      }

      // إضافة الرسالة الجديدة
      currentPinnedIds.add(messageId);

      await db.from('chat_rooms').update({
        'pinned_message_ids': jsonEncode(currentPinnedIds),
      }).eq('id', roomId);

      // إضافة الرسالة للقائمة المحلية
      final message = _messagesCache[roomId]?.firstWhereOrNull((m) => m.id == messageId);
      if (message != null) {
        pinnedMessages.add(message);
      }

      print("📌 تم تثبيت الرسالة بنجاح (${pinnedMessages.length} رسائل مثبتة)");
      Get.snackbar("تم", "تم تثبيت الرسالة", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print("❌ فشل في تثبيت الرسالة: $e");
      Get.snackbar("خطأ", "فشل تثبيت الرسالة");
    }
  }

  /// إلغاء تثبيت رسالة معينة
  Future<void> unpinMessage(String messageId, String roomId) async {
    try {
      // جلب قائمة الرسائل المثبتة الحالية
      final response = await db
          .from('chat_rooms')
          .select('pinned_message_ids')
          .eq('id', roomId)
          .maybeSingle();

      List<String> currentPinnedIds = [];
      if (response != null && response['pinned_message_ids'] != null) {
        currentPinnedIds = List<String>.from(jsonDecode(response['pinned_message_ids']));
      }

      // إزالة الرسالة
      currentPinnedIds.remove(messageId);

      await db.from('chat_rooms').update({
        'pinned_message_ids': currentPinnedIds.isEmpty ? null : jsonEncode(currentPinnedIds),
      }).eq('id', roomId);

      // إزالة من القائمة المحلية
      pinnedMessages.removeWhere((m) => m.id == messageId);

      print("📌 تم إلغاء تثبيت الرسالة (${pinnedMessages.length} رسائل متبقية)");
      Get.snackbar("تم", "تم إلغاء تثبيت الرسالة", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print("❌ فشل في إلغاء تثبيت الرسالة: $e");
      Get.snackbar("خطأ", "فشل إلغاء تثبيت الرسالة");
    }
  }

  /// إلغاء تثبيت جميع الرسائل
  Future<void> unpinAllMessages(String roomId) async {
    try {
      await db.from('chat_rooms').update({
        'pinned_message_ids': null,
      }).eq('id', roomId);

      pinnedMessages.clear();

      print("📌 تم إلغاء تثبيت جميع الرسائل");
      Get.snackbar("تم", "تم إلغاء تثبيت جميع الرسائل", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print("❌ فشل في إلغاء تثبيت الرسائل: $e");
      Get.snackbar("خطأ", "فشل إلغاء تثبيت الرسائل");
    }
  }

  /// تحميل الرسائل المثبتة لغرفة معينة
  Future<void> loadPinnedMessages(String roomId) async {
    try {
      pinnedMessages.clear();

      final response = await db
          .from('chat_rooms')
          .select('pinned_message_ids')
          .eq('id', roomId)
          .maybeSingle();

      if (response != null && response['pinned_message_ids'] != null) {
        List<String> pinnedIds = List<String>.from(jsonDecode(response['pinned_message_ids']));

        // جلب جميع الرسائل المثبتة
        for (String id in pinnedIds) {
          final messageResponse = await db
              .from('chats')
              .select()
              .eq('id', id)
              .maybeSingle();

          if (messageResponse != null) {
            pinnedMessages.add(ChatModel.fromJson(messageResponse));
          }
        }
        print("📌 تم تحميل ${pinnedMessages.length} رسائل مثبتة");
      }
    } catch (e) {
      print("❌ خطأ في تحميل الرسائل المثبتة: $e");
    }
  }

  /// التحقق إذا كانت الرسالة مثبتة
  bool isMessagePinned(String messageId) {
    return pinnedMessages.any((m) => m.id == messageId);
  }

  // ======================== تحويل الرسائل ========================

  /// تحويل رسالة إلى غرفة دردشة أخرى
  Future<void> forwardMessage(ChatModel originalMessage, String targetUserId, UserModel targetUser) async {
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

    // إنشاء نص الرسالة المحولة مع إشارة التحويل واسم المرسل الأصلي
    final senderName = originalMessage.senderName ?? 'مجهول';
    String forwardedMessage = '';
    if (originalMessage.message?.isNotEmpty == true) {
      forwardedMessage = '↪️ Forwarded from $senderName\n${originalMessage.message}';
    } else if (originalMessage.imageUrl?.isNotEmpty == true) {
      forwardedMessage = '↪️ Forwarded from $senderName';
    } else if (originalMessage.audioUrl?.isNotEmpty == true) {
      forwardedMessage = '↪️ Forwarded from $senderName';
    } else {
      forwardedMessage = '↪️ Forwarded from $senderName';
    }

    try {
      await db.from('chats').insert({
        'id': chatId,
        'senderId': currentUserId,
        'reciverId': targetUserId,
        'senderName': profileController.currentUser.value.name,
        'message': forwardedMessage,
        'imageUrl': originalMessage.imageUrl ?? '',
        'audioUrl': originalMessage.audioUrl ?? '',
        'timeStamp': now,
        'roomId': roomId,
      });

      String lastMessage = originalMessage.message?.isNotEmpty == true
          ? '↪️ ${originalMessage.message}'
          : (originalMessage.imageUrl?.isNotEmpty == true)
              ? '↪️ صورة محولة'
              : (originalMessage.audioUrl?.isNotEmpty == true)
                  ? '↪️ رسالة صوتية محولة'
                  : '↪️ رسالة محولة';

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
      await contactController.getChatRoomList();

      print("✅ تم تحويل الرسالة بنجاح");
      Get.snackbar("تم", "تم تحويل الرسالة بنجاح", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print("❌ خطأ في تحويل الرسالة: $e");
      Get.snackbar('خطأ', 'حدث خطأ أثناء تحويل الرسالة');
    }

    isLoading.value = false;
    isSending.value = false;
  }

  /// Retry sending a failed message
  Future<void> retryFailedMessage(String messageId) async {
    await _offlineQueue.retryMessage(messageId);
  }

  /// Remove a failed message
  Future<void> removeFailedMessage(String messageId, String roomId) async {
    await _offlineQueue.removeFromQueue(messageId);
    _messagesCache[roomId]?.removeWhere((m) => m.id == messageId);
  }
}
