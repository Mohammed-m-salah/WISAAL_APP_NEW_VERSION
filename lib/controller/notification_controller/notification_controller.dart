import 'package:get/get.dart';
import 'package:wissal_app/model/mute_settings_model.dart';
import 'package:wissal_app/services/notifications/notification_service.dart';

class NotificationController extends GetxController {
  final NotificationService _notificationService = NotificationService();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxMap<String, MuteSettingsModel?> muteSettingsCache =
      <String, MuteSettingsModel?>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _notificationService.initialize();
  }

  // ==================== MUTE SETTINGS ====================

  /// Get cache key for mute settings
  String _getCacheKey(String targetId, String targetType) {
    return '${targetType}_$targetId';
  }

  /// Check if target is muted
  Future<bool> isMuted({
    required String targetId,
    required String targetType,
  }) async {
    final cacheKey = _getCacheKey(targetId, targetType);

    // Check cache first
    if (muteSettingsCache.containsKey(cacheKey)) {
      return muteSettingsCache[cacheKey]?.isCurrentlyMuted ?? false;
    }

    // Fetch from service
    final settings = await _notificationService.getCurrentUserMuteSettings(
      targetId: targetId,
      targetType: targetType,
    );

    // Cache result
    muteSettingsCache[cacheKey] = settings;

    return settings?.isCurrentlyMuted ?? false;
  }

  /// Get mute settings
  Future<MuteSettingsModel?> getMuteSettings({
    required String targetId,
    required String targetType,
  }) async {
    final cacheKey = _getCacheKey(targetId, targetType);

    if (muteSettingsCache.containsKey(cacheKey)) {
      return muteSettingsCache[cacheKey];
    }

    final settings = await _notificationService.getCurrentUserMuteSettings(
      targetId: targetId,
      targetType: targetType,
    );

    muteSettingsCache[cacheKey] = settings;
    return settings;
  }

  /// Mute target (chat or group)
  Future<bool> mute({
    required String targetId,
    required String targetType,
    required MuteDuration duration,
    bool allowMentions = true,
    bool allowPinned = true,
  }) async {
    isLoading.value = true;

    try {
      final success = await _notificationService.setMuteSettings(
        targetId: targetId,
        targetType: targetType,
        duration: duration,
        allowMentions: allowMentions,
        allowPinned: allowPinned,
      );

      if (success) {
        // Update cache
        final cacheKey = _getCacheKey(targetId, targetType);
        muteSettingsCache[cacheKey] = MuteSettingsModel(
          targetId: targetId,
          targetType: targetType,
          isMuted: true,
          mutedUntil: duration.getMutedUntil(),
          allowMentions: allowMentions,
          allowPinned: allowPinned,
        );

        Get.snackbar(
          'تم',
          'تم كتم الإشعارات',
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      return success;
    } finally {
      isLoading.value = false;
    }
  }

  /// Unmute target
  Future<bool> unmute({
    required String targetId,
    required String targetType,
  }) async {
    isLoading.value = true;

    try {
      final success = await _notificationService.unmute(
        targetId: targetId,
        targetType: targetType,
      );

      if (success) {
        // Update cache
        final cacheKey = _getCacheKey(targetId, targetType);
        muteSettingsCache[cacheKey] = null;

        Get.snackbar(
          'تم',
          'تم إلغاء كتم الإشعارات',
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      return success;
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear cache for a target
  void clearCache(String targetId, String targetType) {
    final cacheKey = _getCacheKey(targetId, targetType);
    muteSettingsCache.remove(cacheKey);
  }

  /// Clear all cache
  void clearAllCache() {
    muteSettingsCache.clear();
  }

  // ==================== SEND NOTIFICATIONS ====================

  /// Send message notification
  Future<void> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String chatId,
    bool isGroup = false,
    String? groupName,
  }) async {
    await _notificationService.sendMessageNotification(
      receiverId: receiverId,
      senderName: senderName,
      messageText: messageText,
      chatId: chatId,
      isGroup: isGroup,
      groupName: groupName,
    );
  }

  /// Send reaction notification
  Future<void> sendReactionNotification({
    required String receiverId,
    required String senderName,
    required String emoji,
    required String chatId,
    bool isGroup = false,
    String? groupName,
  }) async {
    await _notificationService.sendReactionNotification(
      receiverId: receiverId,
      senderName: senderName,
      emoji: emoji,
      chatId: chatId,
      isGroup: isGroup,
      groupName: groupName,
    );
  }

  /// Send media notification
  Future<void> sendMediaNotification({
    required String receiverId,
    required String senderName,
    required NotificationType mediaType,
    required String chatId,
    bool isGroup = false,
    String? groupName,
    String? imageUrl,
  }) async {
    await _notificationService.sendMediaNotification(
      receiverId: receiverId,
      senderName: senderName,
      mediaType: mediaType,
      chatId: chatId,
      isGroup: isGroup,
      groupName: groupName,
      imageUrl: imageUrl,
    );
  }

  /// Send mention notification
  Future<void> sendMentionNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String groupId,
    required String groupName,
  }) async {
    await _notificationService.sendMentionNotification(
      receiverId: receiverId,
      senderName: senderName,
      messageText: messageText,
      groupId: groupId,
      groupName: groupName,
    );
  }

  /// Send notification to all group members
  Future<void> sendGroupNotification({
    required String groupId,
    required List<String> memberIds,
    required String senderName,
    required String messageText,
    required String groupName,
    NotificationType type = NotificationType.message,
    String? imageUrl,
  }) async {
    await _notificationService.sendGroupNotification(
      groupId: groupId,
      memberIds: memberIds,
      senderName: senderName,
      messageText: messageText,
      groupName: groupName,
      type: type,
      imageUrl: imageUrl,
    );
  }

  /// Send pin notification
  Future<void> sendPinNotification({
    required List<String> receiverIds,
    required String senderName,
    required String messageText,
    required String targetId,
    required bool isGroup,
    String? groupName,
  }) async {
    await _notificationService.sendPinNotification(
      receiverIds: receiverIds,
      senderName: senderName,
      messageText: messageText,
      targetId: targetId,
      isGroup: isGroup,
      groupName: groupName,
    );
  }

  /// On logout - clean up
  Future<void> onLogout() async {
    clearAllCache();
    await _notificationService.onLogout();
  }
}
