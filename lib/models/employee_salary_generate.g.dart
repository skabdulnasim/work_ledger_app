// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_salary_generate.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmployeeSalaryGenerateAdapter
    extends TypeAdapter<EmployeeSalaryGenerate> {
  @override
  final int typeId = 8;

  @override
  EmployeeSalaryGenerate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmployeeSalaryGenerate(
      id: fields[0] as String?,
      serverId: fields[1] as String?,
      title: fields[2] as String,
      fromDate: fields[3] as DateTime,
      toDate: fields[4] as DateTime,
      remarks: fields[5] as String?,
      isSynced: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EmployeeSalaryGenerate obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.serverId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.fromDate)
      ..writeByte(4)
      ..write(obj.toDate)
      ..writeByte(5)
      ..write(obj.remarks)
      ..writeByte(6)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeSalaryGenerateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
