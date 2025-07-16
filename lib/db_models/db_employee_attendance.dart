import 'package:collection/collection.dart';
import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/employee_attendance.dart';

class DBEmployeeAttendance {
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(BOX_EMPLOYEE_ATTENDANCE)) {
      await Hive.openBox<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE);
    }
  }

  static List<EmployeeAttendance> getAll() {
    final box = Hive.box<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE);
    return box.values.toList();
  }

  static EmployeeAttendance? findByEmployeeForDate(
      String employeeId, String siteId, DateTime date) {
    return Hive.box<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE)
        .values
        .firstWhereOrNull((e) =>
            e.employeeId == employeeId &&
            e.siteId == siteId &&
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day);
  }

  static EmployeeAttendance? find(String id) {
    final box = Hive.box<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE);

    return box.values.firstWhere(
      (attendance) => attendance.id.toString() == id.toString(),
    );
  }

  /// Add or update company by ID
  static Future<void> upsert(EmployeeAttendance attendance) async {
    final box = Hive.box<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE);
    await box.put(attendance.id, attendance);
  }

  static List<EmployeeAttendance> getUnsynced() {
    final box = Hive.box<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE);
    return box.values.where((e) => e.isSynced == false).toList();
  }

  static Future<void> clearAll() async {
    await Hive.box<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE).clear();
  }
}
