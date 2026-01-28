import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wissal_app/model/chat_model.dart';

class SavedMessagesController extends GetxController {
  final uuid = const Uuid();
  final db = Supabase.instance.client;
  final auth = Supabase.instance.client.auth;

  RxBool isLoading = false.obs;
  RxList<ChatModel> savedMessages = <ChatModel>[].obs;

  // Retry configuration
  int _retryCount = 0;
  static const int _maxRetries = 5;
  Timer? _retryTimer;

  @override
  void onInit() {
    super.onInit();
    loadSavedMessages();
    _subscribeToSavedMessages();
  }

  /// جلب الرسائل المحفوظة
  Future<void> loadSavedMessages({int retryAttempt = 0}) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    isLoading.value = true;
    try {
      final userId = currentUser.id;

      final data = await db
          .from('chats')
          .select()
          .eq('senderId', userId)
          .eq('reciverId', userId)
          .order('timeStamp', ascending: false);

      savedMessages.value = (data as List)
          .map((e) => ChatModel.fromJson(e))
          .where((m) => m.isDeleted != true)
          .toList();

      print('✅ عدد الرسائل المحفوظة: ${savedMessages.length}');
    } catch (e) {
      print('❌ خطأ في جلب الرسائل المحفوظة: $e');

      // Retry on connection errors
      final errorStr = e.toString();
      if ((errorStr.contains('ClientException') ||
              errorStr.contains('Connection closed')) &&
          retryAttempt < 3) {
        print('⚠️ إعادة محاولة جلب الرسائل المحفوظة...');
        await Future.delayed(Duration(seconds: retryAttempt + 1));
        return loadSavedMessages(retryAttempt: retryAttempt + 1);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeToSavedMessages() {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final userId = currentUser.id;

    db
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('senderId', userId)
        .listen(
          (data) {
            // Reset retry count on success
            _retryCount = 0;

            final savedOnly = data
                .where((e) => e['reciverId'] == userId)
                .map((e) => ChatModel.fromJson(e))
                .where((m) => m.isDeleted != true)
                .toList();

            savedOnly.sort((a, b) {
              final aTime = DateTime.tryParse(a.timeStamp ?? '') ?? DateTime(0);
              final bTime = DateTime.tryParse(b.timeStamp ?? '') ?? DateTime(0);
              return bTime.compareTo(aTime);
            });

            savedMessages.value = savedOnly;
          },
          onError: (error) {
            print('❌ خطأ في Stream الرسائل المحفوظة: $error');
            _handleStreamError(error);
          },
        );
  }

  void _handleStreamError(dynamic error) {
    final errorStr = error.toString();
    final isRetryable = errorStr.contains('ClientException') ||
        errorStr.contains('Connection closed') ||
        errorStr.contains('SocketException');

    if (isRetryable && _retryCount < _maxRetries) {
      _retryCount++;
      final delay = Duration(seconds: 2 * _retryCount);

      print('⚠️ إعادة محاولة الاتصال $_retryCount/$_maxRetries بعد ${delay.inSeconds}s');

      _retryTimer?.cancel();
      _retryTimer = Timer(delay, () {
        _subscribeToSavedMessages();
      });
    } else if (_retryCount >= _maxRetries) {
      print('❌ تم الوصول للحد الأقصى من المحاولات');
      // Reset after some time
      Timer(const Duration(seconds: 30), () {
        _retryCount = 0;
      });
    }
  }

  @override
  void onClose() {
    _retryTimer?.cancel();
    super.onClose();
  }

  Future<void> sendSavedMessage({
    String? message,
    String? imageUrl,
    String? audioUrl,
    String? documentUrl,
  }) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    try {
      final userId = currentUser.id;
      final userName = currentUser.userMetadata?['name'] ?? 'User';
      final savedRoomId = '${userId}_${userId}';
      final messageId = uuid.v4();

      // استخدام نفس الحقول المستخدمة في chat_controller.dart
      final newMessage = {
        'id': messageId,
        'senderId': userId,
        'reciverId': userId,
        'senderName': userName,
        'message': message ?? '',
        'imageUrl': imageUrl ?? '',
        'audioUrl': audioUrl ?? '',
        'timeStamp': DateTime.now().toIso8601String(),
        'roomId': savedRoomId,
      };

      await db.from('chats').insert(newMessage);
      print('✅ تم حفظ الرسالة بنجاح');
    } catch (e) {
      print('❌ خطأ في حفظ الرسالة: $e');
      rethrow;
    }
  }

  Future<void> saveMessageFromChat(ChatModel originalMessage) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      print('❌ المستخدم غير مسجل');
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      final userId = currentUser.id;
      final userName = currentUser.userMetadata?['name'] ?? 'User';
      final messageId = uuid.v4(); // استخدام v4 للتوافق

      String savedMessageText = originalMessage.message ?? '';

      // إضافة معلومات المرسل الأصلي
      if (originalMessage.senderId != userId) {
        savedMessageText = '📌 من: ${originalMessage.senderName}\n$savedMessageText';
      }

      // إنشاء roomId للرسائل المحفوظة (المستخدم يرسل لنفسه)
      final savedRoomId = '${userId}_${userId}';

      // استخدام نفس الحقول المستخدمة في chat_controller.dart
      final savedMessage = {
        'id': messageId,
        'senderId': userId,
        'reciverId': userId,
        'senderName': userName,
        'message': savedMessageText,
        'imageUrl': originalMessage.imageUrl ?? '',
        'audioUrl': originalMessage.audioUrl ?? '',
        'timeStamp': DateTime.now().toIso8601String(),
        'roomId': savedRoomId,
      };

      print('📝 حفظ الرسالة: $savedMessage');

      await db.from('chats').insert(savedMessage);

      Get.snackbar(
        'تم',
        'تم حفظ الرسالة',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      print('✅ تم حفظ الرسالة من المحادثة');
    } catch (e) {
      print('❌ خطأ في حفظ الرسالة من المحادثة: $e');

      Get.snackbar(
        'خطأ',
        'فشل حفظ الرسالة',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteSavedMessage(String messageId) async {
    try {
      await db.from('chats').update({'isDeleted': true}).eq('id', messageId);
      savedMessages.removeWhere((m) => m.id == messageId);
      print('✅ تم حذف الرسالة المحفوظة');
    } catch (e) {
      print('❌ خطأ في حذف الرسالة المحفوظة: $e');
    }
  }

  int get savedMessagesCount => savedMessages.length;

  ChatModel? get lastSavedMessage =>
      savedMessages.isNotEmpty ? savedMessages.first : null;

  /// Save a group message to saved messages
  Future<void> saveGroupMessage(ChatModel message, String groupName) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      print('❌ المستخدم غير مسجل');
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      final userId = currentUser.id;
      final userName = currentUser.userMetadata?['name'] ?? 'User';
      final messageId = uuid.v4();

      String savedMessageText = message.message ?? '';

      // Add group and sender info
      savedMessageText = '📌 من مجموعة: $groupName\n👤 المرسل: ${message.senderName ?? 'مجهول'}\n$savedMessageText';

      // Create roomId for saved messages
      final savedRoomId = '${userId}_${userId}';

      final savedMessage = {
        'id': messageId,
        'senderId': userId,
        'reciverId': userId,
        'senderName': userName,
        'message': savedMessageText,
        'imageUrl': message.imageUrl ?? '',
        'audioUrl': message.audioUrl ?? '',
        'timeStamp': DateTime.now().toIso8601String(),
        'roomId': savedRoomId,
      };

      print('📝 حفظ رسالة المجموعة: $savedMessage');

      await db.from('chats').insert(savedMessage);

      Get.snackbar(
        'تم',
        'تم حفظ الرسالة',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      print('✅ تم حفظ رسالة المجموعة');
    } catch (e) {
      print('❌ خطأ في حفظ رسالة المجموعة: $e');

      Get.snackbar(
        'خطأ',
        'فشل حفظ الرسالة',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
