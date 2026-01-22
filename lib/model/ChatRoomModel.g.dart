// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ChatRoomModel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatRoomModelAdapter extends TypeAdapter<ChatRoomModel> {
  @override
  final int typeId = 1;

  @override
  ChatRoomModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatRoomModel(
      id: fields[0] as String?,
      senderId: fields[1] as String?,
      reciverId: fields[2] as String?,
      sender: fields[3] as UserModel?,
      receiver: fields[4] as UserModel?,
      messages: (fields[5] as List?)?.cast<ChatModel>(),
      unReadMessageNO: fields[6] as int?,
      lastMessage: fields[7] as String?,
      lastMessageTimeStamp: fields[8] as DateTime?,
      timeStamp: fields[9] as String?,
      isTyping: fields[10] as bool?,
      pinnedMessageIds: (fields[11] as List?)?.cast<String>(),
      isPinned: fields[12] as bool? ?? false,
      pinOrder: fields[13] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, ChatRoomModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.senderId)
      ..writeByte(2)
      ..write(obj.reciverId)
      ..writeByte(3)
      ..write(obj.sender)
      ..writeByte(4)
      ..write(obj.receiver)
      ..writeByte(5)
      ..write(obj.messages)
      ..writeByte(6)
      ..write(obj.unReadMessageNO)
      ..writeByte(7)
      ..write(obj.lastMessage)
      ..writeByte(8)
      ..write(obj.lastMessageTimeStamp)
      ..writeByte(9)
      ..write(obj.timeStamp)
      ..writeByte(10)
      ..write(obj.isTyping)
      ..writeByte(11)
      ..write(obj.pinnedMessageIds)
      ..writeByte(12)
      ..write(obj.isPinned)
      ..writeByte(13)
      ..write(obj.pinOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatRoomModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
