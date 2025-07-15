// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_attendance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmployeeAttendanceAdapter extends TypeAdapter<EmployeeAttendance> {
  @override
  final int typeId = 7;

  @override
  EmployeeAttendance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmployeeAttendance(
      id: fields[0] as String?,
      serverId: fields[2] as String?,
      employeeId: fields[1] as String,
      siteId: fields[3] as String,
      date: fields[4] as DateTime,
      overtimeCount: fields[5] as double,
      isHalfDay: fields[6] as bool,
      isFullDay: fields[7] as bool,
      isAbsence: fields[8] as bool,
      remarks: fields[9] as String?,
      isSynced: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EmployeeAttendance obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.employeeId)
      ..writeByte(2)
      ..write(obj.serverId)
      ..writeByte(3)
      ..write(obj.siteId)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.overtimeCount)
      ..writeByte(6)
      ..write(obj.isHalfDay)
      ..writeByte(7)
      ..write(obj.isFullDay)
      ..writeByte(8)
      ..write(obj.isAbsence)
      ..writeByte(9)
      ..write(obj.remarks)
      ..writeByte(10)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeAttendanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
