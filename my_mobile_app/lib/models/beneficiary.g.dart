// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'beneficiary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BeneficiaryAdapter extends TypeAdapter<Beneficiary> {
  @override
  final int typeId = 1;

  @override
  Beneficiary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Beneficiary(
      id: fields[0] as int?,
      uuid: fields[1] as String,
      recordId: fields[2] as String?,
      inFormId: fields[3] as String?,
      ipName: fields[4] as String?,
      sector: fields[5] as String?,
      indicator: fields[6] as String?,
      date: fields[7] as String?,
      name: fields[8] as String?,
      idNumber: fields[9] as String?,
      phoneNumber: fields[10] as String?,
      dateOfBirth: fields[11] as String?,
      age: fields[12] as int?,
      gender: fields[13] as String?,
      governorate: fields[14] as String?,
      municipality: fields[15] as String?,
      neighborhood: fields[16] as String?,
      siteName: fields[17] as String?,
      disabilityStatus: fields[18] as bool?,
      deleted: fields[19] as bool,
      createdBy: fields[20] as String?,
      submissionTime: fields[21] as String?,
      synced: fields[22] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Beneficiary obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.uuid)
      ..writeByte(2)
      ..write(obj.recordId)
      ..writeByte(3)
      ..write(obj.inFormId)
      ..writeByte(4)
      ..write(obj.ipName)
      ..writeByte(5)
      ..write(obj.sector)
      ..writeByte(6)
      ..write(obj.indicator)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.name)
      ..writeByte(9)
      ..write(obj.idNumber)
      ..writeByte(10)
      ..write(obj.phoneNumber)
      ..writeByte(11)
      ..write(obj.dateOfBirth)
      ..writeByte(12)
      ..write(obj.age)
      ..writeByte(13)
      ..write(obj.gender)
      ..writeByte(14)
      ..write(obj.governorate)
      ..writeByte(15)
      ..write(obj.municipality)
      ..writeByte(16)
      ..write(obj.neighborhood)
      ..writeByte(17)
      ..write(obj.siteName)
      ..writeByte(18)
      ..write(obj.disabilityStatus)
      ..writeByte(19)
      ..write(obj.deleted)
      ..writeByte(20)
      ..write(obj.createdBy)
      ..writeByte(21)
      ..write(obj.submissionTime)
      ..writeByte(22)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BeneficiaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
