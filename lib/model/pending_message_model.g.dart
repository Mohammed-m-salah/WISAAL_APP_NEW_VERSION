// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_message_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingMessageModelAdapter extends TypeAdapter<PendingMessageModel> {
  @override
  final int typeId = 11;

  @override
  PendingMessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingMessageModel(
      id: fields[0] as String,
      message: fields[1] as String,
      senderId: fields[2] as String,
      receiverId: fields[3] as String,
      senderName: fields[4] as String,
      roomId: fields[5] as String,
      timeStamp: fields[6] as String,
      imageUrl: fields[7] as String?,
      localImagePaths: (fields[8] as List?)?.cast<String>(),
      localAudioPath: fields[9] as String?,
      audioUrl: fields[10] as String?,
      status: fields[11] as MessageSyncStatus,
      retryCount: fields[12] as int,
      lastError: fields[13] as String?,
      createdAt: fields[14] as DateTime,
      lastRetryAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingMessageModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.receiverId)
      ..writeByte(4)
      ..write(obj.senderName)
      ..writeByte(5)
      ..write(obj.roomId)
      ..writeByte(6)
      ..write(obj.timeStamp)
      ..writeByte(7)
      ..write(obj.imageUrl)
      ..writeByte(8)
      ..write(obj.localImagePaths)
      ..writeByte(9)
      ..write(obj.localAudioPath)
      ..writeByte(10)
      ..write(obj.audioUrl)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.retryCount)
      ..writeByte(13)
      ..write(obj.lastError)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.lastRetryAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingMessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
