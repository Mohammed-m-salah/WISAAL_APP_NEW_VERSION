import 'dart:convert';

class ChatModel {
  String? id;
  String? message;
  String? senderName;
  String? senderId;
  String? reciverId;
  String? timeStamp;
  String? readStatus;
  String? imageUrl;
  List<String>? imageUrls;
  String? videoUrl;
  String? audioUrl;
  String? documentUrl;
  List<String>? reactions;
  List<dynamic>? replies;
  bool? isDeleted;
  bool? isEdited;

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
    return ChatModel(
      id: json['id'],
      message: json['message'],
      senderName: json['senderName'],
      senderId: json['senderId'],
      reciverId: json['reciverId'],
      timeStamp: json['timeStamp'],
      readStatus: json['readStatus'],
      imageUrl: json['imageUrl'],
      imageUrls: imageUrls,
      videoUrl: json['videoUrl'],
      audioUrl: json['audioUrl'],
      documentUrl: json['documentUrl'],
      reactions: _parseStringList(json['reactions']),
      replies: _parseDynamicList(json['replies']),
      isDeleted: json['isDeleted'] ?? false,
      isEdited: json['isEdited'] ?? false,
    );
  }

  String? _imageUrlsToString() {
    if (imageUrls == null || imageUrls!.isEmpty) return imageUrl;
    if (imageUrls!.length == 1) return imageUrls!.first;
    return jsonEncode(imageUrls);
  }

  bool get hasImages => imageUrls != null && imageUrls!.isNotEmpty;

  bool get hasMultipleImages => imageUrls != null && imageUrls!.length > 1;

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
    };
  }
}
