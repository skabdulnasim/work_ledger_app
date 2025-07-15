// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SiteAdapter extends TypeAdapter<Site> {
  @override
  final int typeId = 3;

  @override
  Site read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Site(
      id: fields[0] as String?,
      name: fields[1] as String,
      address: fields[2] as String,
      isSynced: fields[3] as bool,
      serverId: fields[4] as String?,
      companyId: fields[5] as String,
      sitePaymentRoles: (fields[6] as List?)?.cast<SitePaymentRole>(),
    );
  }

  @override
  void write(BinaryWriter writer, Site obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.isSynced)
      ..writeByte(4)
      ..write(obj.serverId)
      ..writeByte(5)
      ..write(obj.companyId)
      ..writeByte(6)
      ..write(obj.sitePaymentRoles);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
