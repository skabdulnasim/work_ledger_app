// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_payment_role.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SitePaymentRoleAdapter extends TypeAdapter<SitePaymentRole> {
  @override
  final int typeId = 4;

  @override
  SitePaymentRole read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SitePaymentRole(
      id: fields[0] as String?,
      isSynced: fields[3] as bool,
      serverId: fields[1] as String?,
      skillId: fields[2] as String,
      dailyWage: fields[4] == null ? 0.0 : fields[4] as double,
      overtimeRate: fields[5] == null ? 0.0 : fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SitePaymentRole obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.serverId)
      ..writeByte(2)
      ..write(obj.skillId)
      ..writeByte(3)
      ..write(obj.isSynced)
      ..writeByte(4)
      ..write(obj.dailyWage)
      ..writeByte(5)
      ..write(obj.overtimeRate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SitePaymentRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
