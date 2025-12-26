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
      id: fields[1] as int?,
      recordId: fields[2] as String?,
      inFormId: fields[3] as String?,
      instanceId: fields[4] as String?,
      ipName: fields[5] as String?,
      sector: fields[6] as String?,
      indicator: fields[7] as String?,
      date: fields[8] as String?,
      name: fields[9] as String?,
      idNumber: fields[10] as String?,
      parentId: fields[11] as String?,
      spouseId: fields[12] as String?,
      phoneNumber: fields[13] as String?,
      dateOfBirth: fields[14] as String?,
      age: fields[15] as int?,
      gender: fields[16] as String?,
      governorate: fields[17] as String?,
      municipality: fields[18] as String?,
      neighborhood: fields[19] as String?,
      siteName: fields[20] as String?,
      disabilityStatus: fields[21] as String?,
      submissionTime: fields[22] as String?,
      deleted: fields[23] as bool,
      householdId: fields[24] as String?,
      createdBy: fields[26] as String?,
      synced: fields[25] as String,
    )..uuid = fields[0] as String;
  }

  @override
  void write(BinaryWriter writer, Beneficiary obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.recordId)
      ..writeByte(3)
      ..write(obj.inFormId)
      ..writeByte(4)
      ..write(obj.instanceId)
      ..writeByte(5)
      ..write(obj.ipName)
      ..writeByte(6)
      ..write(obj.sector)
      ..writeByte(7)
      ..write(obj.indicator)
      ..writeByte(8)
      ..write(obj.date)
      ..writeByte(9)
      ..write(obj.name)
      ..writeByte(10)
      ..write(obj.idNumber)
      ..writeByte(11)
      ..write(obj.parentId)
      ..writeByte(12)
      ..write(obj.spouseId)
      ..writeByte(13)
      ..write(obj.phoneNumber)
      ..writeByte(14)
      ..write(obj.dateOfBirth)
      ..writeByte(15)
      ..write(obj.age)
      ..writeByte(16)
      ..write(obj.gender)
      ..writeByte(17)
      ..write(obj.governorate)
      ..writeByte(18)
      ..write(obj.municipality)
      ..writeByte(19)
      ..write(obj.neighborhood)
      ..writeByte(20)
      ..write(obj.siteName)
      ..writeByte(21)
      ..write(obj.disabilityStatus)
      ..writeByte(22)
      ..write(obj.submissionTime)
      ..writeByte(23)
      ..write(obj.deleted)
      ..writeByte(24)
      ..write(obj.householdId)
      ..writeByte(25)
      ..write(obj.synced)
      ..writeByte(26)
      ..write(obj.createdBy);
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
