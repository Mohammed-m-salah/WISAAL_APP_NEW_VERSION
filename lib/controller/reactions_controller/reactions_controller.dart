import 'dart:convert';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> addReaction(String messageId, String emoji) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    try {
      final response = await db
          .from('chats')
          .select('reactions')
          .eq('id', messageId)
          .single();

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

      reactions.add('$emoji:${currentUser.id}');

      await db.from('chats').update({
        'reactions': reactions,
      }).eq('id', messageId);

      print('✅ تم إضافة التفاعل: $emoji على الرسالة: $messageId');
    } catch (e) {
      print('❌ خطأ في إضافة التفاعل: $e');
    }
  }

  Future<void> removeReaction(String messageId) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    try {
      final response = await db
          .from('chats')
          .select('reactions')
          .eq('id', messageId)
          .single();

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

      await db.from('chats').update({
        'reactions': reactions,
      }).eq('id', messageId);

      print('✅ تم إزالة التفاعل من الرسالة: $messageId');
    } catch (e) {
      print('❌ خطأ في إزالة التفاعل: $e');
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
