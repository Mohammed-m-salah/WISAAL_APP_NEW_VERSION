// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_metadata_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncMetadataModelAdapter extends TypeAdapter<SyncMetadataModel> {
  @override
  final int typeId = 12;

  @override
  SyncMetadataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncMetadataModel(
      roomId: fields[0] as String,
      lastSyncTimestamp: fields[1] as DateTime?,
      messageCount: fields[2] as int,
      isSyncing: fields[3] as bool,
      lastError: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncMetadataModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.roomId)
      ..writeByte(1)
      ..write(obj.lastSyncTimestamp)
      ..writeByte(2)
      ..write(obj.messageCount)
      ..writeByte(3)
      ..write(obj.isSyncing)
      ..writeByte(4)
      ..write(obj.lastError);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncMetadataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
