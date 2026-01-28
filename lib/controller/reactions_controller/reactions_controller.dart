import 'dart:convert';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/services/notifications/notification_service.dart';
import 'package:wissal_app/controller/profile_controller/profile_controller.dart';

class ReactionEmoji {
  static const String love = '❤️';
  static const String like = '👍';
  static const String dislike = '👎';
  static const String laugh = '😂';
  static const String wow = '😮';
  static const String sad = '😢';
  static const String angry = '😡';

  static List<String> get all => [love, like, dislike, laugh, wow, sad, angry];
}

class Reaction {
  final String emoji;
  final String odId;
  final DateTime timestamp;

  Reaction({
    required this.emoji,
    required this.odId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'userId': odId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Reaction.fromJson(Map<String, dynamic> json) => Reaction(
        emoji: json['emoji'] ?? '',
        odId: json['userId'] ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
      );

  @override
  String toString() => '$emoji:$odId';

  static Reaction? fromString(String str) {
    final parts = str.split(':');
    if (parts.length >= 2) {
      return Reaction(emoji: parts[0], odId: parts[1]);
    }
    return null;
  }
}

class ReactionsController extends GetxController {
  final db = Supabase.instance.client;
  final auth = Supabase.instance.client.auth;

  // Callback لإعلام ChatController بالتحديث
  Function(String messageId, List<String> reactions)? onReactionUpdated;

  // كاش محلي للتفاعلات للتحديث الفوري
  final Map<String, List<String>> _localReactionsCache = {};

  Future<void> addReaction(String messageId, String emoji) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      print('❌ لا يوجد مستخدم مسجل');
      return;
    }

    print('🎯 بدء إضافة تفاعل: $emoji للرسالة: $messageId');

    try {
      // الخطوة 1: تحديث الكاش المحلي فوراً (UI يتحدث مباشرة)
      List<String> localReactions = List<String>.from(_localReactionsCache[messageId] ?? []);
      localReactions.removeWhere((r) => r.contains(':${currentUser.id}'));
      localReactions.add('$emoji:${currentUser.id}');
      _localReactionsCache[messageId] = localReactions;

      // إعلام الـ UI بالتحديث فوراً قبل الـ API call
      onReactionUpdated?.call(messageId, List<String>.from(localReactions));
      print('⚡ تحديث فوري للـ UI: $emoji');

      // الخطوة 2: جلب التفاعلات الحالية من قاعدة البيانات
      print('📡 جلب الرسالة من قاعدة البيانات...');
      final response = await db
          .from('chats')
          .select('id, reactions, senderId, roomId')
          .eq('id', messageId)
          .maybeSingle();

      print('📡 الرد من قاعدة البيانات: $response');

      // إذا لم توجد الرسالة في السيرفر (pending message)
      if (response == null) {
        print('⚠️ الرسالة غير موجودة في السيرفر - تحديث محلي فقط');
        return;
      }

      // Get sender info for notification
      final messageSenderId = response['senderId'] as String?;
      final roomId = response['roomId'] as String?;

      List<String> reactions = [];
      if (response['reactions'] != null) {
        print('📦 نوع reactions في الرد: ${response['reactions'].runtimeType}');
        print('📦 قيمة reactions: ${response['reactions']}');

        if (response['reactions'] is List) {
          reactions = List<String>.from(response['reactions']);
        } else if (response['reactions'] is String) {
          try {
            final decoded = jsonDecode(response['reactions']);
            if (decoded is List) {
              reactions = List<String>.from(decoded);
            }
          } catch (e) {
            print('❌ خطأ في decode: $e');
          }
        }
      }

      print('📋 التفاعلات الحالية: $reactions');

      // إزالة التفاعل السابق للمستخدم
      reactions.removeWhere((r) => r.contains(':${currentUser.id}'));

      // إضافة التفاعل الجديد
      reactions.add('$emoji:${currentUser.id}');

      print('📋 التفاعلات الجديدة للحفظ: $reactions');

      // الخطوة 3: حفظ في قاعدة البيانات
      // تحويل إلى JSON string للتوافق مع أنواع مختلفة من الأعمدة
      final reactionsJson = jsonEncode(reactions);
      print('💾 جاري حفظ التفاعلات في قاعدة البيانات: $reactionsJson');

      await db.from('chats').update({
        'reactions': reactionsJson,
      }).eq('id', messageId);

      print('💾 تم التحديث!');

      // التحقق من الحفظ
      final verifyResponse = await db
          .from('chats')
          .select('reactions')
          .eq('id', messageId)
          .maybeSingle();

      print('✅ التحقق بعد الحفظ: ${verifyResponse?['reactions']}');

      // تحديث الكاش بالقيمة النهائية
      _localReactionsCache[messageId] = reactions;
      onReactionUpdated?.call(messageId, reactions);

      // Send notification to message sender (if not self)
      if (messageSenderId != null &&
          messageSenderId != currentUser.id &&
          roomId != null) {
        try {
          final profileController = Get.find<ProfileController>();
          final senderName = profileController.currentUser.value.name ?? 'مستخدم';
          final notificationService = NotificationService();

          await notificationService.sendReactionNotification(
            receiverId: messageSenderId,
            senderName: senderName,
            emoji: emoji,
            chatId: roomId,
            isGroup: false,
          );
          print('🔔 تم إرسال إشعار التفاعل');
        } catch (e) {
          print('⚠️ فشل إرسال إشعار التفاعل: $e');
        }
      }

      print('✅ تم إضافة التفاعل: $emoji على الرسالة: $messageId');
    } catch (e) {
      print('❌ خطأ في إضافة التفاعل: $e');
      print('❌ نوع الخطأ: ${e.runtimeType}');
      print('❌ تفاصيل: ${e.toString()}');

      // إذا كان الخطأ متعلق بالعمود غير موجود
      if (e.toString().contains('reactions') || e.toString().contains('column')) {
        print('⚠️ تأكد من وجود عمود reactions في جدول chats في Supabase');
        print('⚠️ قم بتنفيذ: ALTER TABLE chats ADD COLUMN IF NOT EXISTS reactions text;');
      }
    }
  }

  Future<void> removeReaction(String messageId) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    try {
      // الخطوة 1: تحديث الكاش المحلي فوراً
      List<String> localReactions = List<String>.from(_localReactionsCache[messageId] ?? []);
      localReactions.removeWhere((r) => r.contains(':${currentUser.id}'));
      _localReactionsCache[messageId] = localReactions;

      // إعلام الـ UI بالتحديث فوراً
      onReactionUpdated?.call(messageId, List<String>.from(localReactions));
      print('⚡ إزالة فورية من الـ UI');

      // الخطوة 2: جلب التفاعلات من قاعدة البيانات
      final response = await db
          .from('chats')
          .select('reactions')
          .eq('id', messageId)
          .maybeSingle();

      // إذا لم توجد الرسالة في السيرفر
      if (response == null) {
        print('⚠️ الرسالة غير موجودة في السيرفر - تحديث محلي فقط');
        return;
      }

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

      reactions.removeWhere((r) => r.contains(':${currentUser.id}'));

      // الخطوة 3: حفظ في قاعدة البيانات
      final reactionsJson = jsonEncode(reactions);
      await db.from('chats').update({
        'reactions': reactionsJson,
      }).eq('id', messageId);

      // تحديث الكاش بالقيمة النهائية
      _localReactionsCache[messageId] = reactions;
      onReactionUpdated?.call(messageId, reactions);

      print('✅ تم إزالة التفاعل من الرسالة: $messageId');
    } catch (e) {
      print('❌ خطأ في إزالة التفاعل: $e');
    }
  }

  /// تحديث الكاش المحلي من الرسائل الموجودة
  void updateLocalCache(String messageId, List<String>? reactions) {
    if (reactions != null) {
      _localReactionsCache[messageId] = List<String>.from(reactions);
    }
  }

  static Map<String, int> parseReactions(List<String>? reactions) {
    if (reactions == null || reactions.isEmpty) return {};

    final Map<String, int> emojiCount = {};
    for (final reaction in reactions) {
      final emoji = reaction.split(':').first;
      emojiCount[emoji] = (emojiCount[emoji] ?? 0) + 1;
    }
    return emojiCount;
  }

  static String? getCurrentUserReaction(
      List<String>? reactions, String? userId) {
    if (reactions == null || reactions.isEmpty || userId == null) return null;

    for (final reaction in reactions) {
      if (reaction.contains(':$userId')) {
        return reaction.split(':').first;
      }
    }
    return null;
  }

  static int getTotalReactionsCount(List<String>? reactions) {
    return reactions?.length ?? 0;
  }

  static List<String> getUsersForEmoji(List<String>? reactions, String emoji) {
    if (reactions == null || reactions.isEmpty) return [];

    return reactions
        .where((r) => r.startsWith('$emoji:'))
        .map((r) => r.split(':').last)
        .toList();
  }
}
