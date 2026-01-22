import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/model/chat_model.dart';
import 'package:wissal_app/model/ChatRoomModel.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/model/sync_metadata_model.dart';
import 'package:wissal_app/model/message_sync_status.dart';
import 'package:wissal_app/services/local_database/local_database_service.dart';
import 'package:wissal_app/services/connectivity/connectivity_service.dart';

class SyncService extends GetxService {
  final db = Supabase.instance.client;
  final auth = Supabase.instance.client.auth;

  late LocalDatabaseService _localDb;
  late ConnectivityService _connectivity;

  final RxBool isSyncing = false.obs;
  final RxString syncStatus = ''.obs;

  Future<SyncService> init() async {
    _localDb = Get.find<LocalDatabaseService>();
    _connectivity = Get.find<ConnectivityService>();

    // Register callback for when connection is restored
    _connectivity.onConnected(() {
      print('🔄 Connection restored - Starting sync...');
      syncAll();
    });

    // Initial sync if online
    if (_connectivity.isOnline.value && auth.currentUser != null) {
      syncAll();
    }

    print('✅ SyncService initialized');
    return this;
  }

  /// Sync all data (chat rooms, messages, users)
  Future<void> syncAll() async {
    if (isSyncing.value || !_connectivity.isOnline.value) {
      return;
    }

    final currentUser = auth.currentUser;
    if (currentUser == null) {
      print('⚠️ Cannot sync - user not logged in');
      return;
    }

    isSyncing.value = true;
    syncStatus.value = 'Syncing...';

    try {
      await syncChatRooms();
      await syncUsers();
      syncStatus.value = 'Synced';
    } catch (e) {
      print('❌ Sync error: $e');
      syncStatus.value = 'Sync failed';
    } finally {
      isSyncing.value = false;
    }
  }

  /// Sync chat rooms from server
  Future<void> syncChatRooms() async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    try {
      final userId = currentUser.id;

      final List roomData = await db.from('chat_rooms').select().or(
        'and(senderId.eq.$userId),and(reciverId.eq.$userId)',
      );

      final List<ChatRoomModel> rooms = roomData
          .map((data) => ChatRoomModel.fromJson(data))
          .toList();

      // Save to local database
      await _localDb.saveChatRooms(rooms);

      print('📥 Synced ${rooms.length} chat rooms');
    } catch (e) {
      print('❌ Error syncing chat rooms: $e');
      rethrow;
    }
  }

  /// Sync messages for a specific room
  Future<List<ChatModel>> syncMessagesForRoom(String roomId, {bool forceFullSync = false}) async {
    if (!_connectivity.isOnline.value) {
      return _localDb.getMessagesByRoom(roomId);
    }

    try {
      // Get sync metadata for incremental sync
      final metadata = _localDb.getSyncMetadata(roomId);
      DateTime? lastSyncTime = forceFullSync ? null : metadata?.lastSyncTimestamp;

      // Fetch messages from server
      var query = db
          .from('chats')
          .select()
          .eq('roomId', roomId);

      // Incremental sync - only fetch new messages
      if (lastSyncTime != null) {
        query = query.gt('timeStamp', lastSyncTime.toIso8601String());
      }

      final response = await query.order('timeStamp', ascending: true);

      final serverMessages = (response as List)
          .map((data) => ChatModel.fromJson(data))
          .toList();

      if (serverMessages.isNotEmpty) {
        // Save to local database
        await _localDb.saveMessages(serverMessages);

        // Update sync metadata
        final latestMessage = serverMessages.last;
        if (latestMessage.timeStamp != null) {
          await _localDb.updateLastSyncTime(
            roomId,
            DateTime.parse(latestMessage.timeStamp!),
          );
        }

        print('📥 Synced ${serverMessages.length} new messages for room $roomId');
      }

      // Return all local messages (including newly synced ones)
      return _localDb.getMessagesByRoom(roomId);
    } catch (e) {
      print('❌ Error syncing messages for room $roomId: $e');
      // Return cached messages on error
      return _localDb.getMessagesByRoom(roomId);
    }
  }

  /// Sync users from server
  Future<void> syncUsers() async {
    try {
      final data = await db.from('save_users').select();

      final users = (data as List)
          .map((userData) => UserModel.fromJson(userData))
          .toList();

      await _localDb.saveUsers(users);

      print('📥 Synced ${users.length} users');
    } catch (e) {
      print('❌ Error syncing users: $e');
    }
  }

  /// Get user (from cache or server)
  Future<UserModel?> getUser(String userId) async {
    // Check local cache first
    var user = _localDb.getUser(userId);
    if (user != null) {
      return user;
    }

    // Fetch from server if online
    if (_connectivity.isOnline.value) {
      try {
        final data = await db
            .from('save_users')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (data != null) {
          user = UserModel.fromJson(data);
          await _localDb.saveUser(user);
          return user;
        }
      } catch (e) {
        print('❌ Error fetching user $userId: $e');
      }
    }

    return null;
  }

  /// Mark message as sent after successful server upload
  Future<void> markMessageAsSent(String messageId) async {
    await _localDb.updateMessageSyncStatus(messageId, MessageSyncStatus.sent);
  }

  /// Mark message as delivered
  Future<void> markMessageAsDelivered(String messageId) async {
    await _localDb.updateMessageSyncStatus(messageId, MessageSyncStatus.delivered);
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    await _localDb.updateMessageSyncStatus(messageId, MessageSyncStatus.read);
  }

  /// Clear all local data and force full sync
  Future<void> resetAndResync() async {
    await _localDb.clearAllData();
    await syncAll();
  }
}
