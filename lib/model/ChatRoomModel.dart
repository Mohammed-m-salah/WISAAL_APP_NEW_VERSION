import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:wissal_app/model/user_model.dart';
import 'chat_model.dart';

part 'ChatRoomModel.g.dart';

@HiveType(typeId: 1)
class ChatRoomModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? senderId;

  @HiveField(2)
  String? reciverId;

  @HiveField(3)
  UserModel? sender;

  @HiveField(4)
  UserModel? receiver;

  @HiveField(5)
  List<ChatModel>? messages;

  @HiveField(6)
  int? unReadMessageNO;

  @HiveField(7)
  String? lastMessage;

  @HiveField(8)
  DateTime? lastMessageTimeStamp;

  @HiveField(9)
  String? timeStamp;

  @HiveField(10)
  bool? isTyping;

  @HiveField(11)
  List<String>? pinnedMessageIds;

  @HiveField(12)
  bool isPinned;

  @HiveField(13)
  int pinOrder;

  ChatRoomModel({
    this.id,
    this.senderId,
    this.reciverId,
    this.sender,
    this.receiver,
    this.messages,
    this.unReadMessageNO,
    this.lastMessage,
    this.lastMessageTimeStamp,
    this.timeStamp,
    this.isTyping = false,
    this.pinnedMessageIds,
    this.isPinned = false,
    this.pinOrder = 0,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    List<ChatModel> messagesList = [];

    final messagesRaw = json['messages'];

    if (messagesRaw != null) {
      if (messagesRaw is String) {
        try {
          final decoded = jsonDecode(messagesRaw);
          if (decoded is List) {
            messagesList = decoded
                .map((e) => e is Map<String, dynamic>
                    ? ChatModel.fromJson(e)
                    : ChatModel.fromJson({}))
                .toList();
          } else if (decoded is Map<String, dynamic>) {
            messagesList = [ChatModel.fromJson(decoded)];
          } else {
            print("❌ البيانات المفكوكة ليست List أو Map: $decoded");
          }
        } catch (e) {
          print("❌ خطأ في فك تشفير الرسائل: $e");
        }
      } else if (messagesRaw is List) {
        messagesList = messagesRaw
            .map((e) => e is Map<String, dynamic>
                ? ChatModel.fromJson(e)
                : ChatModel.fromJson({}))
            .toList();
      } else if (messagesRaw is Map<String, dynamic>) {
        messagesList = [ChatModel.fromJson(messagesRaw)];
      } else {
        print("❌ نوع غير متوقع للرسائل: ${messagesRaw.runtimeType}");
      }
    }

    return ChatRoomModel(
      id: json['id'] ?? '',
      senderId: json['senderId'],
      reciverId: json['reciverId'],
      sender:
          json['sender'] != null ? UserModel.fromJson(json['sender']) : null,
      receiver: json['receiver'] != null
          ? UserModel.fromJson(json['receiver'])
          : null,
      messages: messagesList,
      unReadMessageNO: json['unReadMessageNO'] ?? 0,
      lastMessage: json['last_message'] ?? '',
      lastMessageTimeStamp: json['last_message_time_stamp'] != null
          ? DateTime.tryParse(json['last_message_time_stamp'])
          : null,
      timeStamp: json['timeStamp'] ?? '',
      pinnedMessageIds: json['pinned_message_ids'] != null
          ? List<String>.from(jsonDecode(json['pinned_message_ids']))
          : null,
      isPinned: json['is_pinned'] ?? false,
      pinOrder: json['pin_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'reciverId': reciverId,
      'sender': sender?.toJson(),
      'receiver': receiver?.toJson(),
      'messages': messages?.map((e) => e.toMap()).toList(),
      'un_read_message_no': unReadMessageNO,
      'last_message': lastMessage,
      'last_message_time_stamp': lastMessageTimeStamp?.toIso8601String(),
      'timeStamp': timeStamp,
      'pinned_message_ids': pinnedMessageIds != null ? jsonEncode(pinnedMessageIds) : null,
      'is_pinned': isPinned,
      'pin_order': pinOrder,
    };
  }
}
