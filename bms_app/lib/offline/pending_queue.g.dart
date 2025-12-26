// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_queue.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingItemAdapter extends TypeAdapter<PendingItem> {
  @override
  final int typeId = 2;

  @override
  PendingItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingItem(
      action: fields[0] as String,
      beneficiary: fields[1] as Beneficiary,
    );
  }

  @override
  void write(BinaryWriter writer, PendingItem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.action)
      ..writeByte(1)
      ..write(obj.beneficiary);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
