// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatModelAdapter extends TypeAdapter<ChatModel> {
  @override
  final int typeId = 0;

  @override
  ChatModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatModel(
      id: fields[0] as String?,
      message: fields[1] as String?,
      senderName: fields[2] as String?,
      senderId: fields[3] as String?,
      reciverId: fields[4] as String?,
      timeStamp: fields[5] as String?,
      readStatus: fields[6] as String?,
      imageUrl: fields[7] as String?,
      imageUrls: (fields[8] as List?)?.cast<String>(),
      videoUrl: fields[9] as String?,
      audioUrl: fields[10] as String?,
      documentUrl: fields[11] as String?,
      reactions: (fields[12] as List?)?.cast<String>(),
      replies: (fields[13] as List?)?.cast<dynamic>(),
      isDeleted: fields[14] as bool?,
      isEdited: fields[15] as bool?,
      isForwarded: fields[16] as bool?,
      forwardedFrom: fields[17] as String?,
      syncStatus: fields[18] as MessageSyncStatus?,
      roomId: fields[19] as String?,
      messageType: fields[20] as String?,
      deletedBy: fields[21] as String?,
      deletedByName: fields[22] as String?,
      seenBy: (fields[23] as List?)?.cast<String>(),
      deliveredTo: (fields[24] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatModel obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.senderName)
      ..writeByte(3)
      ..write(obj.senderId)
      ..writeByte(4)
      ..write(obj.reciverId)
      ..writeByte(5)
      ..write(obj.timeStamp)
      ..writeByte(6)
      ..write(obj.readStatus)
      ..writeByte(7)
      ..write(obj.imageUrl)
      ..writeByte(8)
      ..write(obj.imageUrls)
      ..writeByte(9)
      ..write(obj.videoUrl)
      ..writeByte(10)
      ..write(obj.audioUrl)
      ..writeByte(11)
      ..write(obj.documentUrl)
      ..writeByte(12)
      ..write(obj.reactions)
      ..writeByte(13)
      ..write(obj.replies)
      ..writeByte(14)
      ..write(obj.isDeleted)
      ..writeByte(15)
      ..write(obj.isEdited)
      ..writeByte(16)
      ..write(obj.isForwarded)
      ..writeByte(17)
      ..write(obj.forwardedFrom)
      ..writeByte(18)
      ..write(obj.syncStatus)
      ..writeByte(19)
      ..write(obj.roomId)
      ..writeByte(20)
      ..write(obj.messageType)
      ..writeByte(21)
      ..write(obj.deletedBy)
      ..writeByte(22)
      ..write(obj.deletedByName)
      ..writeByte(23)
      ..write(obj.seenBy)
      ..writeByte(24)
      ..write(obj.deliveredTo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
