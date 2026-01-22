import 'package:hive/hive.dart';

part 'sync_metadata_model.g.dart';

@HiveType(typeId: 12)
class SyncMetadataModel extends HiveObject {
  @HiveField(0)
  String roomId;

  @HiveField(1)
  DateTime? lastSyncTimestamp;

  @HiveField(2)
  int messageCount;

  @HiveField(3)
  bool isSyncing;

  @HiveField(4)
  String? lastError;

  SyncMetadataModel({
    required this.roomId,
    this.lastSyncTimestamp,
    this.messageCount = 0,
    this.isSyncing = false,
    this.lastError,
  });
}
