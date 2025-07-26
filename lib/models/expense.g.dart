// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 13;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String,
      isSynced: fields[2] as bool,
      serverId: fields[1] as String?,
      expenseAt: fields[3] as DateTime,
      siteId: fields[4] as String,
      expenseById: fields[5] as String,
      expenseToId: fields[6] as String?,
      amount: fields[7] as double,
      remarks: fields[8] as String,
      attachFileIds: (fields[9] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.serverId)
      ..writeByte(2)
      ..write(obj.isSynced)
      ..writeByte(3)
      ..write(obj.expenseAt)
      ..writeByte(4)
      ..write(obj.siteId)
      ..writeByte(5)
      ..write(obj.expenseById)
      ..writeByte(6)
      ..write(obj.expenseToId)
      ..writeByte(7)
      ..write(obj.amount)
      ..writeByte(8)
      ..write(obj.remarks)
      ..writeByte(9)
      ..write(obj.attachFileIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
