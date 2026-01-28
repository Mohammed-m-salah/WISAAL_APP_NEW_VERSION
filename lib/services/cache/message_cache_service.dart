import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wissal_app/model/chat_model.dart';

class MessageCacheService extends GetxService {
  static const String _messagesBoxName = 'cached_messages';
  static const String _groupMessagesBoxName = 'cached_group_messages';
  static const String _metadataBoxName = 'cache_metadata';
  static const int _maxCachedMessages = 100;
  static const Duration _cacheExpiry = Duration(days: 7);

  late Box<Map> _messagesBox;
  late Box<Map> _groupMessagesBox;
  late Box<Map> _metadataBox;

  final RxBool isInitialized = false.obs;

  Future<MessageCacheService> init() async {
    try {
      _messagesBox = await Hive.openBox<Map>(_messagesBoxName);
      _groupMessagesBox = await Hive.openBox<Map>(_groupMessagesBoxName);
      _metadataBox = await Hive.openBox<Map>(_metadataBoxName);
      isInitialized.value = true;
      print('✅ MessageCacheService initialized');
    } catch (e) {
      print('❌ MessageCacheService init error: $e');
    }
    return this;
  }

  Future<void> cacheMessages(String roomId, List<ChatModel> messages) async {
    if (!isInitialized.value) return;

    try {
      final messagesToCache = messages.length > _maxCachedMessages
          ? messages.sublist(messages.length - _maxCachedMessages)
          : messages;

      final messagesList = messagesToCache.map((m) => m.toMap()).toList();

      await _messagesBox.put(roomId, {'messages': messagesList});

      await _metadataBox.put('chat_$roomId', {
        'lastUpdated': DateTime.now().toIso8601String(),
        'count': messagesToCache.length,
      });

      print('💾 Cached ${messagesToCache.length} messages for room: $roomId');
    } catch (e) {
      print('❌ Error caching messages: $e');
    }
  }

  List<ChatModel> getCachedMessages(String roomId) {
    if (!isInitialized.value) return [];

    try {
      final data = _messagesBox.get(roomId);
      if (data == null) return [];

      final messagesList = data['messages'] as List?;
      if (messagesList == null) return [];

      return messagesList
          .map((m) => ChatModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      print('❌ Error getting cached messages: $e');
      return [];
    }
  }

  Future<void> addMessageToCache(String roomId, ChatModel message) async {
    if (!isInitialized.value) return;

    try {
      final messages = getCachedMessages(roomId);

      final existingIndex = messages.indexWhere((m) => m.id == message.id);
      if (existingIndex != -1) {
        messages[existingIndex] = message;
      } else {
        messages.add(message);
      }

      if (messages.length > _maxCachedMessages) {
        messages.removeRange(0, messages.length - _maxCachedMessages);
      }

      await cacheMessages(roomId, messages);
    } catch (e) {
      print('❌ Error adding message to cache: $e');
    }
  }

  Future<void> updateMessageInCache(String roomId, ChatModel message) async {
    await addMessageToCache(roomId, message);
  }

  Future<void> removeMessageFromCache(String roomId, String messageId) async {
    if (!isInitialized.value) return;

    try {
      final messages = getCachedMessages(roomId);
      messages.removeWhere((m) => m.id == messageId);
      await cacheMessages(roomId, messages);
    } catch (e) {
      print('❌ Error removing message from cache: $e');
    }
  }

  bool hasCachedMessages(String roomId) {
    if (!isInitialized.value) return false;
    return _messagesBox.containsKey(roomId);
  }

  Map<String, dynamic>? getCacheMetadata(String roomId) {
    if (!isInitialized.value) return null;
    final data = _metadataBox.get('chat_$roomId');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  bool isCacheExpired(String roomId) {
    final metadata = getCacheMetadata(roomId);
    if (metadata == null) return true;

    final lastUpdated = DateTime.tryParse(metadata['lastUpdated'] ?? '');
    if (lastUpdated == null) return true;

    return DateTime.now().difference(lastUpdated) > _cacheExpiry;
  }

  Future<void> cacheGroupMessages(
      String groupId, List<ChatModel> messages) async {
    if (!isInitialized.value) return;

    try {
      final messagesToCache = messages.length > _maxCachedMessages
          ? messages.sublist(messages.length - _maxCachedMessages)
          : messages;

      final messagesList = messagesToCache.map((m) => m.toMap()).toList();

      await _groupMessagesBox.put(groupId, {'messages': messagesList});

      await _metadataBox.put('group_$groupId', {
        'lastUpdated': DateTime.now().toIso8601String(),
        'count': messagesToCache.length,
      });

      print('💾 Cached ${messagesToCache.length} group messages for: $groupId');
    } catch (e) {
      print('❌ Error caching group messages: $e');
    }
  }

  List<ChatModel> getCachedGroupMessages(String groupId) {
    if (!isInitialized.value) return [];

    try {
      final data = _groupMessagesBox.get(groupId);
      if (data == null) return [];

      final messagesList = data['messages'] as List?;
      if (messagesList == null) return [];

      return messagesList
          .map((m) => ChatModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      print('❌ Error getting cached group messages: $e');
      return [];
    }
  }

  Future<void> addGroupMessageToCache(String groupId, ChatModel message) async {
    if (!isInitialized.value) return;

    try {
      final messages = getCachedGroupMessages(groupId);

      final existingIndex = messages.indexWhere((m) => m.id == message.id);
      if (existingIndex != -1) {
        messages[existingIndex] = message;
      } else {
        messages.add(message);
      }

      if (messages.length > _maxCachedMessages) {
        messages.removeRange(0, messages.length - _maxCachedMessages);
      }

      await cacheGroupMessages(groupId, messages);
    } catch (e) {
      print('❌ Error adding group message to cache: $e');
    }
  }

  bool hasCachedGroupMessages(String groupId) {
    if (!isInitialized.value) return false;
    return _groupMessagesBox.containsKey(groupId);
  }

  bool isGroupCacheExpired(String groupId) {
    final metadata = _metadataBox.get('group_$groupId');
    if (metadata == null) return true;

    final lastUpdated =
        DateTime.tryParse(metadata['lastUpdated']?.toString() ?? '');
    if (lastUpdated == null) return true;

    return DateTime.now().difference(lastUpdated) > _cacheExpiry;
  }

  Future<void> clearRoomCache(String roomId) async {
    if (!isInitialized.value) return;

    try {
      await _messagesBox.delete(roomId);
      await _metadataBox.delete('chat_$roomId');
      print('🗑️ Cleared cache for room: $roomId');
    } catch (e) {
      print('❌ Error clearing room cache: $e');
    }
  }

  Future<void> clearGroupCache(String groupId) async {
    if (!isInitialized.value) return;

    try {
      await _groupMessagesBox.delete(groupId);
      await _metadataBox.delete('group_$groupId');
      print('🗑️ Cleared cache for group: $groupId');
    } catch (e) {
      print('❌ Error clearing group cache: $e');
    }
  }

  Future<void> clearAllCaches() async {
    if (!isInitialized.value) return;

    try {
      await _messagesBox.clear();
      await _groupMessagesBox.clear();
      await _metadataBox.clear();
      print('🗑️ Cleared all message caches');
    } catch (e) {
      print('❌ Error clearing all caches: $e');
    }
  }

  Future<void> clearExpiredCaches() async {
    if (!isInitialized.value) return;

    try {
      final keysToDelete = <String>[];

      for (final key in _messagesBox.keys) {
        if (isCacheExpired(key.toString())) {
          keysToDelete.add(key.toString());
        }
      }

      for (final key in _groupMessagesBox.keys) {
        if (isGroupCacheExpired(key.toString())) {
          await clearGroupCache(key.toString());
        }
      }

      for (final key in keysToDelete) {
        await clearRoomCache(key);
      }

      print('🧹 Cleared ${keysToDelete.length} expired caches');
    } catch (e) {
      print('❌ Error clearing expired caches: $e');
    }
  }

  Map<String, dynamic> getCacheStats() {
    if (!isInitialized.value) {
      return {'initialized': false};
    }

    return {
      'initialized': true,
      'chatRooms': _messagesBox.length,
      'groups': _groupMessagesBox.length,
      'totalMetadata': _metadataBox.length,
    };
  }
}
