import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/model/mute_settings_model.dart';
import 'package:wissal_app/services/notifications/fcm_service.dart';

enum NotificationType {
  message,
  reaction,
  image,
  voice,
  video,
  file,
  mention,
  pin,
  groupAdd,
  groupRemove,
  groupPromote,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FCMService _fcmService = FCMService();
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  Future<void> initialize() async {
    await _fcmService.initialize();
  }

  Future<void> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String chatId,
    bool isGroup = false,
    String? groupName,
  }) async {
    final canSend = await _canSendNotification(
      receiverId: receiverId,
      targetId: chatId,
      targetType: isGroup ? 'group' : 'chat',
      notificationType: NotificationType.message,
    );

    if (!canSend) {
      debugPrint('Notification blocked by mute settings');
      return;
    }

    final title = isGroup ? groupName ?? 'مجموعة' : senderName;
    final body = isGroup ? '$senderName: $messageText' : messageText;

    await _fcmService.sendNotificationToUser(
      receiverUserId: receiverId,
      title: title,
      body: _truncateText(body, 100),
      data: {
        'type': 'message',
        'target_id': chatId,
        'target_type': isGroup ? 'group' : 'chat',
        'sender_id': _currentUserId,
      },
    );

    await _logNotification(
      receiverId: receiverId,
      type: NotificationType.message,
      title: title,
      body: body,
    );
  }

  Future<void> sendReactionNotification({
    required String receiverId,
    required String senderName,
    required String emoji,
    required String chatId,
    bool isGroup = false,
    String? groupName,
  }) async {
    final canSend = await _canSendNotification(
      receiverId: receiverId,
      targetId: chatId,
      targetType: isGroup ? 'group' : 'chat',
      notificationType: NotificationType.reaction,
    );

    if (!canSend) return;

    final title = isGroup ? groupName ?? 'مجموعة' : senderName;
    final body = '$senderName تفاعل $emoji على رسالتك';

    await _fcmService.sendNotificationToUser(
      receiverUserId: receiverId,
      title: title,
      body: body,
      data: {
        'type': 'reaction',
        'target_id': chatId,
        'target_type': isGroup ? 'group' : 'chat',
        'sender_id': _currentUserId,
      },
    );

    await _logNotification(
      receiverId: receiverId,
      type: NotificationType.reaction,
      title: title,
      body: body,
    );
  }

  Future<void> sendMediaNotification({
    required String receiverId,
    required String senderName,
    required NotificationType mediaType,
    required String chatId,
    bool isGroup = false,
    String? groupName,
    String? imageUrl,
  }) async {
    final canSend = await _canSendNotification(
      receiverId: receiverId,
      targetId: chatId,
      targetType: isGroup ? 'group' : 'chat',
      notificationType: mediaType,
    );

    if (!canSend) return;

    final title = isGroup ? groupName ?? 'مجموعة' : senderName;
    String body;

    switch (mediaType) {
      case NotificationType.image:
        body = isGroup ? '$senderName أرسل صورة 📷' : 'أرسل صورة 📷';
        break;
      case NotificationType.voice:
        body =
            isGroup ? '$senderName أرسل رسالة صوتية 🎤' : 'أرسل رسالة صوتية 🎤';
        break;
      case NotificationType.video:
        body = isGroup ? '$senderName أرسل فيديو 🎬' : 'أرسل فيديو 🎬';
        break;
      case NotificationType.file:
        body = isGroup ? '$senderName أرسل ملف 📎' : 'أرسل ملف 📎';
        break;
      default:
        body = isGroup ? '$senderName أرسل رسالة' : 'أرسل رسالة';
    }

    await _fcmService.sendNotificationToUser(
      receiverUserId: receiverId,
      title: title,
      body: body,
      data: {
        'type': mediaType.name,
        'target_id': chatId,
        'target_type': isGroup ? 'group' : 'chat',
        'sender_id': _currentUserId,
      },
      imageUrl: imageUrl,
    );

    await _logNotification(
      receiverId: receiverId,
      type: mediaType,
      title: title,
      body: body,
    );
  }

  Future<void> sendMentionNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String groupId,
    required String groupName,
  }) async {
    final canSend = await _canSendNotification(
      receiverId: receiverId,
      targetId: groupId,
      targetType: 'group',
      notificationType: NotificationType.mention,
      isMention: true,
    );

    if (!canSend) return;

    final title = groupName;
    final body = '$senderName أشار إليك: ${_truncateText(messageText, 50)}';

    await _fcmService.sendNotificationToUser(
      receiverUserId: receiverId,
      title: title,
      body: body,
      data: {
        'type': 'mention',
        'target_id': groupId,
        'target_type': 'group',
        'sender_id': _currentUserId,
      },
    );

    await _logNotification(
      receiverId: receiverId,
      type: NotificationType.mention,
      title: title,
      body: body,
    );
  }

  Future<void> sendPinNotification({
    required List<String> receiverIds,
    required String senderName,
    required String messageText,
    required String targetId,
    required bool isGroup,
    String? groupName,
  }) async {
    for (final receiverId in receiverIds) {
      if (receiverId == _currentUserId) continue;

      final canSend = await _canSendNotification(
        receiverId: receiverId,
        targetId: targetId,
        targetType: isGroup ? 'group' : 'chat',
        notificationType: NotificationType.pin,
        isPinned: true,
      );

      if (!canSend) continue;

      final title = isGroup ? groupName ?? 'مجموعة' : senderName;
      final body =
          '📌 $senderName ثبّت رسالة: ${_truncateText(messageText, 40)}';

      await _fcmService.sendNotificationToUser(
        receiverUserId: receiverId,
        title: title,
        body: body,
        data: {
          'type': 'pin',
          'target_id': targetId,
          'target_type': isGroup ? 'group' : 'chat',
          'sender_id': _currentUserId,
        },
      );
    }
  }

  Future<void> sendGroupEventNotification({
    required List<String> receiverIds,
    required NotificationType eventType,
    required String groupId,
    required String groupName,
    required String targetUserName,
    String? adminName,
  }) async {
    String body;
    switch (eventType) {
      case NotificationType.groupAdd:
        body = 'تمت إضافة $targetUserName للمجموعة';
        break;
      case NotificationType.groupRemove:
        body = 'تم إزالة $targetUserName من المجموعة';
        break;
      case NotificationType.groupPromote:
        body = '$targetUserName أصبح مشرفاً';
        break;
      default:
        body = 'تحديث في المجموعة';
    }

    for (final receiverId in receiverIds) {
      if (receiverId == _currentUserId) continue;

      await _fcmService.sendNotificationToUser(
        receiverUserId: receiverId,
        title: groupName,
        body: body,
        data: {
          'type': eventType.name,
          'target_id': groupId,
          'target_type': 'group',
        },
      );
    }
  }

  Future<void> sendGroupNotification({
    required String groupId,
    required List<String> memberIds,
    required String senderName,
    required String messageText,
    required String groupName,
    NotificationType type = NotificationType.message,
    String? imageUrl,
  }) async {
    for (final memberId in memberIds) {
      // Don't send to sender
      if (memberId == _currentUserId) continue;

      if (type == NotificationType.message) {
        await sendMessageNotification(
          receiverId: memberId,
          senderName: senderName,
          messageText: messageText,
          chatId: groupId,
          isGroup: true,
          groupName: groupName,
        );
      } else {
        await sendMediaNotification(
          receiverId: memberId,
          senderName: senderName,
          mediaType: type,
          chatId: groupId,
          isGroup: true,
          groupName: groupName,
          imageUrl: imageUrl,
        );
      }
    }
  }

  Future<bool> _canSendNotification({
    required String receiverId,
    required String targetId,
    required String targetType,
    required NotificationType notificationType,
    bool isMention = false,
    bool isPinned = false,
  }) async {
    try {
      if (receiverId == _currentUserId) return false;

      final settings = await getMuteSettings(
        odId: receiverId,
        targetId: targetId,
        targetType: targetType,
      );

      if (settings == null) return true;

      if (!settings.isCurrentlyMuted) return true;

      if (isMention && settings.allowMentions) return true;
      if (isPinned && settings.allowPinned) return true;

      return false;
    } catch (e) {
      debugPrint('Error checking mute settings: $e');
      return true;
    }
  }

  Future<MuteSettingsModel?> getMuteSettings({
    required String odId,
    required String targetId,
    required String targetType,
  }) async {
    try {
      final response = await _supabase
          .from('mute_settings')
          .select()
          .eq('user_id', odId)
          .eq('target_id', targetId)
          .eq('target_type', targetType)
          .maybeSingle();

      if (response == null) return null;
      return MuteSettingsModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting mute settings: $e');
      return null;
    }
  }

  Future<bool> setMuteSettings({
    required String targetId,
    required String targetType,
    required MuteDuration duration,
    bool allowMentions = true,
    bool allowPinned = true,
  }) async {
    try {
      final mutedUntil = duration.getMutedUntil();

      await _supabase.from('mute_settings').upsert({
        'user_id': _currentUserId,
        'target_id': targetId,
        'target_type': targetType,
        'is_muted': true,
        'muted_until': mutedUntil?.toIso8601String(),
        'allow_mentions': allowMentions,
        'allow_pinned': allowPinned,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,target_id,target_type');

      return true;
    } catch (e) {
      debugPrint('Error setting mute: $e');
      return false;
    }
  }

  Future<bool> unmute({
    required String targetId,
    required String targetType,
  }) async {
    try {
      await _supabase
          .from('mute_settings')
          .update({
            'is_muted': false,
            'muted_until': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', _currentUserId)
          .eq('target_id', targetId)
          .eq('target_type', targetType);

      return true;
    } catch (e) {
      debugPrint('Error unmuting: $e');
      return false;
    }
  }

  Future<bool> isMuted({
    required String targetId,
    required String targetType,
  }) async {
    final settings = await getMuteSettings(
      odId: _currentUserId,
      targetId: targetId,
      targetType: targetType,
    );
    return settings?.isCurrentlyMuted ?? false;
  }

  Future<MuteSettingsModel?> getCurrentUserMuteSettings({
    required String targetId,
    required String targetType,
  }) async {
    return getMuteSettings(
      odId: _currentUserId,
      targetId: targetId,
      targetType: targetType,
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Future<void> _logNotification({
    required String receiverId,
    required NotificationType type,
    required String title,
    required String body,
  }) async {
    try {
      await _supabase.from('notification_logs').insert({
        'sender_id': _currentUserId,
        'receiver_id': receiverId,
        'notification_type': type.name,
        'title': title,
        'body': body,
        'is_sent': true,
        'sent_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging notification: $e');
    }
  }

  Future<void> onLogout() async {
    await _fcmService.deleteToken();
  }
}
