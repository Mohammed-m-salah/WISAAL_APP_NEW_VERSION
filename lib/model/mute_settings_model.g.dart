// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mute_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MuteSettingsModelAdapter extends TypeAdapter<MuteSettingsModel> {
  @override
  final int typeId = 10;

  @override
  MuteSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MuteSettingsModel(
      id: fields[0] as String?,
      odId: fields[1] as String?,
      targetId: fields[2] as String?,
      targetType: fields[3] as String?,
      isMuted: fields[4] as bool? ?? false,
      mutedUntil: fields[5] as DateTime?,
      allowMentions: fields[6] as bool? ?? true,
      allowPinned: fields[7] as bool? ?? true,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MuteSettingsModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.odId)
      ..writeByte(2)
      ..write(obj.targetId)
      ..writeByte(3)
      ..write(obj.targetType)
      ..writeByte(4)
      ..write(obj.isMuted)
      ..writeByte(5)
      ..write(obj.mutedUntil)
      ..writeByte(6)
      ..write(obj.allowMentions)
      ..writeByte(7)
      ..write(obj.allowPinned)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MuteSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
