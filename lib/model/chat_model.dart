import 'dart:convert';
import 'package:hive/hive.dart';
import 'message_sync_status.dart';

part 'chat_model.g.dart';

@HiveType(typeId: 0)
class ChatModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? message;

  @HiveField(2)
  String? senderName;

  @HiveField(3)
  String? senderId;

  @HiveField(4)
  String? reciverId;

  @HiveField(5)
  String? timeStamp;

  @HiveField(6)
  String? readStatus;

  @HiveField(7)
  String? imageUrl;

  @HiveField(8)
  List<String>? imageUrls;

  @HiveField(9)
  String? videoUrl;

  @HiveField(10)
  String? audioUrl;

  @HiveField(11)
  String? documentUrl;

  @HiveField(12)
  List<String>? reactions;

  @HiveField(13)
  List<dynamic>? replies;

  @HiveField(14)
  bool? isDeleted;

  @HiveField(15)
  bool? isEdited;

  @HiveField(16)
  bool? isForwarded;

  @HiveField(17)
  String? forwardedFrom;

  @HiveField(18)
  MessageSyncStatus? syncStatus;

  @HiveField(19)
  String? roomId;

  ChatModel({
    this.id,
    this.message,
    this.senderName,
    this.senderId,
    this.reciverId,
    this.timeStamp,
    this.readStatus,
    this.imageUrl,
    this.imageUrls,
    this.videoUrl,
    this.audioUrl = '',
    this.documentUrl,
    this.reactions,
    this.replies,
    this.isDeleted = false,
    this.isEdited = false,
    this.isForwarded = false,
    this.forwardedFrom,
    this.syncStatus,
    this.roomId,
  });

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return List<String>.from(decoded);
      } catch (_) {}
    }
    return [];
  }

  static List<dynamic> _parseDynamicList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return [];
  }

  static List<String> _parseImageUrls(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return [];
    final str = value.toString().trim();
    if (str.startsWith('[')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          return List<String>.from(
              decoded.where((e) => e != null && e.toString().isNotEmpty));
        }
      } catch (_) {}
    }
    return [str];
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final imageUrls = _parseImageUrls(json['imageUrl']);

    // تحويل readStatus من boolean إلى نص
    String readStatusText = 'Sent';
    final rawReadStatus = json['readStatus'];
    if (rawReadStatus is bool) {
      readStatusText = rawReadStatus ? 'Read' : 'Sent';
    } else if (rawReadStatus is String) {
      readStatusText = rawReadStatus;
    }

    // تحديد syncStatus بناءً على readStatus
    MessageSyncStatus syncStatus = MessageSyncStatus.sent;
    if (readStatusText == 'Read') {
      syncStatus = MessageSyncStatus.read;
    } else if (readStatusText == 'Delivered') {
      syncStatus = MessageSyncStatus.delivered;
    }

    return ChatModel(
      id: json['id'],
      message: json['message'],
      senderName: json['senderName'],
      senderId: json['senderId'],
      reciverId: json['reciverId'],
      timeStamp: json['timeStamp'],
      readStatus: readStatusText,
      imageUrl: json['imageUrl'],
      imageUrls: imageUrls,
      videoUrl: json['videoUrl'],
      audioUrl: json['audioUrl'],
      documentUrl: json['documentUrl'],
      reactions: _parseStringList(json['reactions']),
      replies: _parseDynamicList(json['replies']),
      isDeleted: json['isDeleted'] ?? false,
      isEdited: json['isEdited'] ?? false,
      isForwarded: json['isForwarded'] ?? false,
      forwardedFrom: json['forwardedFrom'],
      syncStatus: syncStatus,
      roomId: json['roomId'],
    );
  }

  String? _imageUrlsToString() {
    if (imageUrls == null || imageUrls!.isEmpty) return imageUrl;
    if (imageUrls!.length == 1) return imageUrls!.first;
    return jsonEncode(imageUrls);
  }

  bool get hasImages => imageUrls != null && imageUrls!.isNotEmpty;

  bool get hasMultipleImages => imageUrls != null && imageUrls!.length > 1;

  bool get isPending => syncStatus == MessageSyncStatus.pending;

  bool get isFailed => syncStatus == MessageSyncStatus.failed;

  bool get isSent => syncStatus == MessageSyncStatus.sent ||
      syncStatus == MessageSyncStatus.delivered ||
      syncStatus == MessageSyncStatus.read;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'senderName': senderName,
      'senderId': senderId,
      'reciverId': reciverId,
      'timeStamp': timeStamp,
      'readStatus': readStatus,
      'imageUrl': _imageUrlsToString(),
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'documentUrl': documentUrl,
      'reactions': reactions ?? [],
      'replies': replies ?? [],
      'isDeleted': isDeleted ?? false,
      'isEdited': isEdited ?? false,
      'isForwarded': isForwarded ?? false,
      'forwardedFrom': forwardedFrom,
      'roomId': roomId,
    };
  }

  ChatModel copyWith({
    String? id,
    String? message,
    String? senderName,
    String? senderId,
    String? reciverId,
    String? timeStamp,
    String? readStatus,
    String? imageUrl,
    List<String>? imageUrls,
    String? videoUrl,
    String? audioUrl,
    String? documentUrl,
    List<String>? reactions,
    List<dynamic>? replies,
    bool? isDeleted,
    bool? isEdited,
    bool? isForwarded,
    String? forwardedFrom,
    MessageSyncStatus? syncStatus,
    String? roomId,
  }) {
    return ChatModel(
      id: id ?? this.id,
      message: message ?? this.message,
      senderName: senderName ?? this.senderName,
      senderId: senderId ?? this.senderId,
      reciverId: reciverId ?? this.reciverId,
      timeStamp: timeStamp ?? this.timeStamp,
      readStatus: readStatus ?? this.readStatus,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      documentUrl: documentUrl ?? this.documentUrl,
      reactions: reactions ?? this.reactions,
      replies: replies ?? this.replies,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      isForwarded: isForwarded ?? this.isForwarded,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
      syncStatus: syncStatus ?? this.syncStatus,
      roomId: roomId ?? this.roomId,
    );
  }
}
