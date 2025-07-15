import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';

part 'employee_attendance.g.dart';

@HiveType(typeId: EMPLOYEE_ATTENDANCE_BOX_TYPE)
class EmployeeAttendance extends HiveObject {
  @HiveField(0)
  String? id; // Local ID (Hive)

  @HiveField(1)
  String employeeId; // Local Employee Hive ID

  @HiveField(2)
  String? serverId;

  @HiveField(3)
  String siteId; // Local Site Hive ID

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  double overtimeCount;

  @HiveField(6)
  bool isHalfDay;

  @HiveField(7)
  bool isFullDay;

  @HiveField(8)
  bool isAbsence;

  @HiveField(9)
  String? remarks;

  @HiveField(10)
  bool isSynced;

  EmployeeAttendance({
    this.id,
    this.serverId,
    required this.employeeId,
    required this.siteId,
    required this.date,
    this.overtimeCount = 0,
    this.isHalfDay = false,
    this.isFullDay = false,
    this.isAbsence = false,
    this.remarks,
    this.isSynced = false,
  });

  factory EmployeeAttendance.fromJson(Map<String, dynamic> json) =>
      EmployeeAttendance(
        serverId: json['id'].toString(),
        employeeId: json['employee_id'].toString(),
        siteId: json['site_id'].toString(),
        date: DateTime.parse(json['date']),
        overtimeCount:
            double.tryParse(json['overtime_count']?.toString() ?? '0') ?? 0,
        isHalfDay: json['is_half_day'] ?? false,
        isFullDay: json['is_full_day'] ?? false,
        isAbsence: json['is_absence'] ?? false,
        remarks: json['remarks'],
        isSynced: true,
      );

  Map<String, dynamic> toJson() => {
        'id': serverId,
        'employee_id': employeeId,
        'site_id': siteId,
        'date': date.toIso8601String(),
        'overtime_count': overtimeCount,
        'is_half_day': isHalfDay,
        'is_full_day': isFullDay,
        'is_absence': isAbsence,
        'remarks': remarks,
      };
}
