import 'package:hive/hive.dart';

part 'message_sync_status.g.dart';

@HiveType(typeId: 10)
enum MessageSyncStatus {
  @HiveField(0)
  pending,    // Waiting to send

  @HiveField(1)
  uploading,  // Uploading media

  @HiveField(2)
  sent,       // Sent to server

  @HiveField(3)
  delivered,  // Delivered to recipient

  @HiveField(4)
  read,       // Read by recipient

  @HiveField(5)
  failed,     // Failed to send
}
