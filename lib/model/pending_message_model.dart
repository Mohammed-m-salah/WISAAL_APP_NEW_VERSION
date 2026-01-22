import 'package:hive/hive.dart';
import 'message_sync_status.dart';

part 'pending_message_model.g.dart';

@HiveType(typeId: 11)
class PendingMessageModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String message;

  @HiveField(2)
  String senderId;

  @HiveField(3)
  String receiverId;

  @HiveField(4)
  String senderName;

  @HiveField(5)
  String roomId;

  @HiveField(6)
  String timeStamp;

  @HiveField(7)
  String? imageUrl;

  @HiveField(8)
  List<String>? localImagePaths;

  @HiveField(9)
  String? localAudioPath;

  @HiveField(10)
  String? audioUrl;

  @HiveField(11)
  MessageSyncStatus status;

  @HiveField(12)
  int retryCount;

  @HiveField(13)
  String? lastError;

  @HiveField(14)
  DateTime createdAt;

  @HiveField(15)
  DateTime? lastRetryAt;

  PendingMessageModel({
    required this.id,
    required this.message,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.roomId,
    required this.timeStamp,
    this.imageUrl,
    this.localImagePaths,
    this.localAudioPath,
    this.audioUrl,
    this.status = MessageSyncStatus.pending,
    this.retryCount = 0,
    this.lastError,
    DateTime? createdAt,
    this.lastRetryAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'senderId': senderId,
      'reciverId': receiverId,
      'senderName': senderName,
      'roomId': roomId,
      'timeStamp': timeStamp,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
    };
  }

  bool get canRetry => retryCount < 5;

  Duration get retryDelay {
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
    return Duration(seconds: 1 << retryCount);
  }
}
