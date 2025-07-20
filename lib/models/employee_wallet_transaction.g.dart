// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_wallet_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmployeeWalletTransactionAdapter
    extends TypeAdapter<EmployeeWalletTransaction> {
  @override
  final int typeId = 9;

  @override
  EmployeeWalletTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmployeeWalletTransaction(
      id: fields[0] as String,
      employeeId: fields[1] as String,
      amount: fields[2] as double,
      transactionAt: fields[3] as DateTime,
      transactionableType: fields[4] as String,
      transactionableId: fields[5] as String,
      transactionType: fields[6] as String,
      remarks: fields[7] as String,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, EmployeeWalletTransaction obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.employeeId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.transactionAt)
      ..writeByte(4)
      ..write(obj.transactionableType)
      ..writeByte(5)
      ..write(obj.transactionableId)
      ..writeByte(6)
      ..write(obj.transactionType)
      ..writeByte(7)
      ..write(obj.remarks)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeWalletTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
