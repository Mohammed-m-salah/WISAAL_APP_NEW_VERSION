import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/model/pending_message_model.dart';
import 'package:wissal_app/model/message_sync_status.dart';
import 'package:wissal_app/services/local_database/local_database_service.dart';
import 'package:wissal_app/services/connectivity/connectivity_service.dart';
import 'package:wissal_app/controller/profile_controller/profile_controller.dart';

class OfflineQueueService extends GetxService {
  final db = Supabase.instance.client;

  late LocalDatabaseService _localDb;
  late ConnectivityService _connectivity;

  final RxBool isProcessing = false.obs;
  final RxInt pendingCount = 0.obs;

  Timer? _retryTimer;

  Future<OfflineQueueService> init() async {
    _localDb = Get.find<LocalDatabaseService>();
    _connectivity = Get.find<ConnectivityService>();

    // Update pending count
    _updatePendingCount();

    // Register callback for when connection is restored
    _connectivity.onConnected(() {
      print('🔄 Connection restored - Processing pending queue...');
      processQueue();
    });

    // Start periodic retry for failed messages
    _startRetryTimer();

    print('✅ OfflineQueueService initialized - Pending: ${pendingCount.value}');
    return this;
  }

  void _updatePendingCount() {
    pendingCount.value = _localDb.pendingMessageCount;
  }

  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_connectivity.isOnline.value && !isProcessing.value) {
        _retryFailedMessages();
      }
    });
  }

  Future<void> enqueue(PendingMessageModel message) async {
    await _localDb.addPendingMessage(message);
    _updatePendingCount();
    print('📥 Message added to offline queue: ${message.id}');

    if (_connectivity.isOnline.value) {
      processQueue();
    }
  }

  Future<void> processQueue() async {
    if (isProcessing.value || !_connectivity.isOnline.value) {
      return;
    }

    isProcessing.value = true;
    print('🔄 Processing offline queue...');

    try {
      final pendingMessages = _localDb.getAllPendingMessages();

      for (final message in pendingMessages) {
        if (!_connectivity.isOnline.value) {
          print('📴 Connection lost during queue processing');
          break;
        }

        if (message.status == MessageSyncStatus.pending ||
            (message.status == MessageSyncStatus.failed && message.canRetry)) {
          await _sendMessage(message);
        }
      }
    } finally {
      isProcessing.value = false;
      _updatePendingCount();
      print('✅ Queue processing complete - Remaining: ${pendingCount.value}');
    }
  }

  Future<void> _sendMessage(PendingMessageModel message) async {
    try {
      if ((message.localImagePaths?.isNotEmpty ?? false) ||
          (message.localAudioPath?.isNotEmpty ?? false)) {
        await _localDb.updatePendingMessageStatus(
            message.id, MessageSyncStatus.uploading);
      }

      String? uploadedImageUrl;
      String? uploadedAudioUrl;

      final profileController = Get.find<ProfileController>();

      if (message.localImagePaths?.isNotEmpty ?? false) {
        List<String> uploadedUrls = [];
        for (String path in message.localImagePaths!) {
          final url = await profileController.uploadeFileToSupabase(path);
          if (url.isNotEmpty) {
            uploadedUrls.add(url);
          }
        }
        if (uploadedUrls.isNotEmpty) {
          uploadedImageUrl = uploadedUrls.length == 1
              ? uploadedUrls.first
              : jsonEncode(uploadedUrls);
        }
      }

      if (message.localAudioPath?.isNotEmpty ?? false) {
        uploadedAudioUrl = await profileController
            .uploadeFileToSupabase(message.localAudioPath!);
      }

      await db.from('chats').insert({
        'id': message.id,
        'senderId': message.senderId,
        'reciverId': message.receiverId,
        'senderName': message.senderName,
        'message': message.message,
        'imageUrl': uploadedImageUrl ?? message.imageUrl ?? '',
        'audioUrl': uploadedAudioUrl ?? message.audioUrl ?? '',
        'timeStamp': message.timeStamp,
        'roomId': message.roomId,
      });

      String lastMessage = message.message.isNotEmpty
          ? message.message
          : (uploadedImageUrl?.isNotEmpty ?? false)
              ? '📷 صورة'
              : (uploadedAudioUrl?.isNotEmpty ?? false)
                  ? '🎤 رسالة صوتية'
                  : '';

      await db.from('chat_rooms').upsert({
        'id': message.roomId,
        'senderId': message.senderId,
        'reciverId': message.receiverId,
        'last_message': lastMessage,
        'last_message_time_stamp': message.timeStamp,
        'created_at': message.timeStamp,
        'un_read_message_no': 0,
      });

      await _localDb.removePendingMessage(message.id);

      await _localDb.updateMessageSyncStatus(
          message.id, MessageSyncStatus.sent);

      print('✅ Message sent successfully: ${message.id}');
    } catch (e) {
      print('❌ Error sending message ${message.id}: $e');
      await _localDb.updatePendingMessageStatus(
        message.id,
        MessageSyncStatus.failed,
        error: e.toString(),
      );
    }
  }

  Future<void> _retryFailedMessages() async {
    final failedMessages = _localDb
        .getAllPendingMessages()
        .where((m) => m.status == MessageSyncStatus.failed && m.canRetry)
        .toList();

    if (failedMessages.isEmpty) return;

    print('🔄 Retrying ${failedMessages.length} failed messages...');

    for (final message in failedMessages) {
      // Check if enough time has passed for retry (exponential backoff)
      if (message.lastRetryAt != null) {
        final timeSinceLastRetry =
            DateTime.now().difference(message.lastRetryAt!);
        if (timeSinceLastRetry < message.retryDelay) {
          continue;
        }
      }

      await _sendMessage(message);
    }
  }

  Future<void> removeFromQueue(String messageId) async {
    await _localDb.removePendingMessage(messageId);
    await _localDb.deleteMessage(messageId);
    _updatePendingCount();
    print('🗑️ Message removed from queue: $messageId');
  }

  Future<void> retryMessage(String messageId) async {
    final message = _localDb
        .getAllPendingMessages()
        .firstWhereOrNull((m) => m.id == messageId);

    if (message != null && _connectivity.isOnline.value) {
      message.status = MessageSyncStatus.pending;
      message.retryCount = 0;
      await message.save();
      await _sendMessage(message);
    }
  }

  @override
  void onClose() {
    _retryTimer?.cancel();
    super.onClose();
  }
}
