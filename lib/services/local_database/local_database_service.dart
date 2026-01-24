import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wissal_app/model/chat_model.dart';
import 'package:wissal_app/model/ChatRoomModel.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/model/pending_message_model.dart';
import 'package:wissal_app/model/sync_metadata_model.dart';
import 'package:wissal_app/model/message_sync_status.dart';

class LocalDatabaseService extends GetxService {
  static const String messagesBoxName = 'messages';
  static const String chatRoomsBoxName = 'chatRooms';
  static const String usersBoxName = 'users';
  static const String pendingMessagesBoxName = 'pendingMessages';
  static const String syncMetadataBoxName = 'syncMetadata';

  late Box<ChatModel> _messagesBox;
  late Box<ChatRoomModel> _chatRoomsBox;
  late Box<UserModel> _usersBox;
  late Box<PendingMessageModel> _pendingMessagesBox;
  late Box<SyncMetadataModel> _syncMetadataBox;

  final RxBool isInitialized = false.obs;

  Future<LocalDatabaseService> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ChatRoomModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(MessageSyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(PendingMessageModelAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SyncMetadataModelAdapter());
    }

    _messagesBox = await Hive.openBox<ChatModel>(messagesBoxName);
    _chatRoomsBox = await Hive.openBox<ChatRoomModel>(chatRoomsBoxName);
    _usersBox = await Hive.openBox<UserModel>(usersBoxName);
    _pendingMessagesBox =
        await Hive.openBox<PendingMessageModel>(pendingMessagesBoxName);
    _syncMetadataBox =
        await Hive.openBox<SyncMetadataModel>(syncMetadataBoxName);

    isInitialized.value = true;
    print('✅ LocalDatabaseService initialized');
    return this;
  }

  Future<void> saveMessage(ChatModel message) async {
    if (message.id == null) return;
    await _messagesBox.put(message.id, message);
  }

  Future<void> saveMessages(List<ChatModel> messages) async {
    final Map<String, ChatModel> entries = {};
    for (final msg in messages) {
      if (msg.id != null) {
        entries[msg.id!] = msg;
      }
    }
    await _messagesBox.putAll(entries);
  }

  List<ChatModel> getMessagesByRoom(String roomId) {
    return _messagesBox.values.where((msg) => msg.roomId == roomId).toList()
      ..sort((a, b) => (a.timeStamp ?? '').compareTo(b.timeStamp ?? ''));
  }

  ChatModel? getMessage(String id) {
    return _messagesBox.get(id);
  }

  Future<void> deleteMessage(String id) async {
    await _messagesBox.delete(id);
  }

  Future<void> updateMessageSyncStatus(
      String id, MessageSyncStatus status) async {
    final message = _messagesBox.get(id);
    if (message != null) {
      message.syncStatus = status;
      await message.save();
    }
  }

  Future<void> saveChatRoom(ChatRoomModel room) async {
    if (room.id == null) return;
    await _chatRoomsBox.put(room.id, room);
  }

  Future<void> saveChatRooms(List<ChatRoomModel> rooms) async {
    final Map<String, ChatRoomModel> entries = {};
    for (final room in rooms) {
      if (room.id != null) {
        entries[room.id!] = room;
      }
    }
    await _chatRoomsBox.putAll(entries);
  }

  List<ChatRoomModel> getAllChatRooms() {
    return _chatRoomsBox.values.toList();
  }

  ChatRoomModel? getChatRoom(String id) {
    return _chatRoomsBox.get(id);
  }

  Future<void> deleteChatRoom(String id) async {
    await _chatRoomsBox.delete(id);
    final messagesToDelete = _messagesBox.values
        .where((msg) => msg.roomId == id)
        .map((msg) => msg.id)
        .whereType<String>()
        .toList();
    for (final msgId in messagesToDelete) {
      await _messagesBox.delete(msgId);
    }
  }

  Future<void> saveUser(UserModel user) async {
    if (user.id == null) return;
    await _usersBox.put(user.id, user);
  }

  Future<void> saveUsers(List<UserModel> users) async {
    final Map<String, UserModel> entries = {};
    for (final user in users) {
      if (user.id != null) {
        entries[user.id!] = user;
      }
    }
    await _usersBox.putAll(entries);
  }

  UserModel? getUser(String id) {
    return _usersBox.get(id);
  }

  List<UserModel> getAllUsers() {
    return _usersBox.values.toList();
  }

  Future<void> addPendingMessage(PendingMessageModel message) async {
    await _pendingMessagesBox.put(message.id, message);
  }

  Future<void> removePendingMessage(String id) async {
    await _pendingMessagesBox.delete(id);
  }

  List<PendingMessageModel> getAllPendingMessages() {
    return _pendingMessagesBox.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<PendingMessageModel> getPendingMessagesByRoom(String roomId) {
    return _pendingMessagesBox.values
        .where((msg) => msg.roomId == roomId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> updatePendingMessageStatus(String id, MessageSyncStatus status,
      {String? error}) async {
    final message = _pendingMessagesBox.get(id);
    if (message != null) {
      message.status = status;
      if (error != null) {
        message.lastError = error;
      }
      if (status == MessageSyncStatus.failed) {
        message.retryCount++;
        message.lastRetryAt = DateTime.now();
      }
      await message.save();
    }
  }

  int get pendingMessageCount => _pendingMessagesBox.length;

  Future<void> saveSyncMetadata(SyncMetadataModel metadata) async {
    await _syncMetadataBox.put(metadata.roomId, metadata);
  }

  SyncMetadataModel? getSyncMetadata(String roomId) {
    return _syncMetadataBox.get(roomId);
  }

  Future<void> updateLastSyncTime(String roomId, DateTime timestamp) async {
    var metadata = _syncMetadataBox.get(roomId);
    if (metadata == null) {
      metadata =
          SyncMetadataModel(roomId: roomId, lastSyncTimestamp: timestamp);
      await _syncMetadataBox.put(roomId, metadata);
    } else {
      metadata.lastSyncTimestamp = timestamp;
      await metadata.save();
    }
  }

  Future<void> clearAllData() async {
    await _messagesBox.clear();
    await _chatRoomsBox.clear();
    await _usersBox.clear();
    await _pendingMessagesBox.clear();
    await _syncMetadataBox.clear();
    print('🗑️ All local data cleared');
  }

  Future<void> clearMessagesForRoom(String roomId) async {
    final keysToDelete = _messagesBox.values
        .where((msg) => msg.roomId == roomId)
        .map((msg) => msg.id)
        .whereType<String>()
        .toList();
    for (final key in keysToDelete) {
      await _messagesBox.delete(key);
    }
  }
}
