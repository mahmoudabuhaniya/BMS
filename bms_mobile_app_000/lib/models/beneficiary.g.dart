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
      id: fields[29] as int?,
      uuid: fields[0] as String?,
      recordId: fields[1] as String?,
      inFormId: fields[2] as String?,
      instanceId: fields[3] as String?,
      ipName: fields[4] as String?,
      sector: fields[5] as String?,
      indicator: fields[6] as String?,
      date: fields[7] as String?,
      name: fields[8] as String?,
      idNumber: fields[9] as String?,
      parentId: fields[10] as String?,
      spouseId: fields[11] as String?,
      phoneNumber: fields[12] as String?,
      dateOfBirth: fields[13] as String?,
      age: fields[14] as String?,
      gender: fields[15] as String?,
      governorate: fields[16] as String?,
      municipality: fields[17] as String?,
      neighborhood: fields[18] as String?,
      siteName: fields[19] as String?,
      disabilityStatus: fields[20] as String?,
      submissionTime: fields[21] as String?,
      householdId: fields[22] as String?,
      deleted: fields[23] as bool,
      deletedAt: fields[24] as String?,
      undeletedAt: fields[25] as String?,
      createdBy: fields[26] as String?,
      createdAt: fields[27] as String?,
      synced: fields[28] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Beneficiary obj) {
    writer
      ..writeByte(30)
      ..writeByte(29)
      ..write(obj.id)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.recordId)
      ..writeByte(2)
      ..write(obj.inFormId)
      ..writeByte(3)
      ..write(obj.instanceId)
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
      ..write(obj.parentId)
      ..writeByte(11)
      ..write(obj.spouseId)
      ..writeByte(12)
      ..write(obj.phoneNumber)
      ..writeByte(13)
      ..write(obj.dateOfBirth)
      ..writeByte(14)
      ..write(obj.age)
      ..writeByte(15)
      ..write(obj.gender)
      ..writeByte(16)
      ..write(obj.governorate)
      ..writeByte(17)
      ..write(obj.municipality)
      ..writeByte(18)
      ..write(obj.neighborhood)
      ..writeByte(19)
      ..write(obj.siteName)
      ..writeByte(20)
      ..write(obj.disabilityStatus)
      ..writeByte(21)
      ..write(obj.submissionTime)
      ..writeByte(22)
      ..write(obj.householdId)
      ..writeByte(23)
      ..write(obj.deleted)
      ..writeByte(24)
      ..write(obj.deletedAt)
      ..writeByte(25)
      ..write(obj.undeletedAt)
      ..writeByte(26)
      ..write(obj.createdBy)
      ..writeByte(27)
      ..write(obj.createdAt)
      ..writeByte(28)
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
