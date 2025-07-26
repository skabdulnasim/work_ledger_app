// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hold_amount.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HoldAmountAdapter extends TypeAdapter<HoldAmount> {
  @override
  final int typeId = 12;

  @override
  HoldAmount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HoldAmount(
      id: fields[0] as String,
      isSynced: fields[2] as bool,
      serverId: fields[1] as String?,
      addedAt: fields[3] as DateTime,
      siteId: fields[4] as String,
      employeeId: fields[5] as String,
      amount: fields[6] as double,
      remarks: fields[7] as String,
      attachFileIds: (fields[8] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HoldAmount obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.serverId)
      ..writeByte(2)
      ..write(obj.isSynced)
      ..writeByte(3)
      ..write(obj.addedAt)
      ..writeByte(4)
      ..write(obj.siteId)
      ..writeByte(5)
      ..write(obj.employeeId)
      ..writeByte(6)
      ..write(obj.amount)
      ..writeByte(7)
      ..write(obj.remarks)
      ..writeByte(8)
      ..write(obj.attachFileIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HoldAmountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
