// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_sync_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageSyncStatusAdapter extends TypeAdapter<MessageSyncStatus> {
  @override
  final int typeId = 10;

  @override
  MessageSyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageSyncStatus.pending;
      case 1:
        return MessageSyncStatus.uploading;
      case 2:
        return MessageSyncStatus.sent;
      case 3:
        return MessageSyncStatus.delivered;
      case 4:
        return MessageSyncStatus.read;
      case 5:
        return MessageSyncStatus.failed;
      default:
        return MessageSyncStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, MessageSyncStatus obj) {
    switch (obj) {
      case MessageSyncStatus.pending:
        writer.writeByte(0);
        break;
      case MessageSyncStatus.uploading:
        writer.writeByte(1);
        break;
      case MessageSyncStatus.sent:
        writer.writeByte(2);
        break;
      case MessageSyncStatus.delivered:
        writer.writeByte(3);
        break;
      case MessageSyncStatus.read:
        writer.writeByte(4);
        break;
      case MessageSyncStatus.failed:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageSyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
