import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';

part 'employee_salary_generate.g.dart';

@HiveType(typeId: EMPLOYEE_SALARY_GRNERATE_BOX_TYPE)
class EmployeeSalaryGenerate extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? serverId;

  @HiveField(2)
  String title;

  @HiveField(3)
  DateTime fromDate;

  @HiveField(4)
  DateTime toDate;

  @HiveField(5)
  String? remarks;

  @HiveField(6)
  bool isSynced;

  EmployeeSalaryGenerate({
    this.id,
    this.serverId,
    required this.title,
    required this.fromDate,
    required this.toDate,
    this.remarks,
    this.isSynced = false,
  });

  factory EmployeeSalaryGenerate.fromJson(Map<String, dynamic> json) =>
      EmployeeSalaryGenerate(
        serverId: json['id']?.toString(),
        title: json['title'] ?? '',
        fromDate: DateTime.parse(json['from_date']),
        toDate: DateTime.parse(json['to_date']),
        remarks: json['remarks'],
        isSynced: true,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'from_date': fromDate.toIso8601String(),
        'to_date': toDate.toIso8601String(),
        'remarks': remarks,
      };
}
