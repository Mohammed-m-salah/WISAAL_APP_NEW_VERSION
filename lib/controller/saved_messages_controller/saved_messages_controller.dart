import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/model/chat_model.dart';

class SavedMessagesController extends GetxController {
  final db = Supabase.instance.client;
  final auth = Supabase.instance.client.auth;

  RxBool isLoading = false.obs;
  RxList<ChatModel> savedMessages = <ChatModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedMessages();
    _subscribeToSavedMessages();
  }

  /// جلب الرسائل المحفوظة
  Future<void> loadSavedMessages() async {
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
        .listen((data) {
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
        });
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

      final newMessage = {
        'message': message ?? '',
        'senderId': userId,
        'reciverId': userId, // نفس المستخدم
        'senderName': userName,
        'timeStamp': DateTime.now().toIso8601String(),
        'readStatus': 'Read',
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'documentUrl': documentUrl,
        'isDeleted': false,
        'isEdited': false,
        'isForwarded': false,
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
    if (currentUser == null) return;

    try {
      final userId = currentUser.id;
      final userName = currentUser.userMetadata?['name'] ?? 'User';

      String savedMessageText = originalMessage.message ?? '';

      if (originalMessage.senderId != userId) {
        savedMessageText =
            '📌 من: ${originalMessage.senderName}\n$savedMessageText';
      }

      final savedMessage = {
        'message': savedMessageText,
        'senderId': userId,
        'reciverId': userId,
        'senderName': userName,
        'timeStamp': DateTime.now().toIso8601String(),
        'readStatus': 'Read',
        'imageUrl': originalMessage.imageUrl,
        'audioUrl': originalMessage.audioUrl,
        'documentUrl': originalMessage.documentUrl,
        'isDeleted': false,
        'isEdited': false,
        'isForwarded': true,
        'forwardedFrom': originalMessage.senderName,
      };

      await db.from('chats').insert(savedMessage);

      Get.snackbar(
        'success'.tr,
        'message_saved'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      print('✅ تم حفظ الرسالة من المحادثة');
    } catch (e) {
      print('❌ خطأ في حفظ الرسالة من المحادثة: $e');
      Get.snackbar(
        'error'.tr,
        'something_went_wrong'.tr,
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
}
