import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/employee_attendance.dart';
import 'package:work_ledger/services/helper.dart';
import 'package:work_ledger/services/sync_manager.dart';

class DBEmployeeAttendance {
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(BOX_EMPLOYEE_ATTENDANCE)) {
      await Hive.openBox<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE);
    }
  }

  // static List<EmployeeAttendance> getAll() {
  //   final box = Hive.box<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE);
  //   return box.values.toList();
  // }

  static List<EmployeeAttendance> getAll({
    String? employeeId,
    DateTime? fromDate,
    DateTime? toDate,
    int? page = 1,
    int? pageSize = 20,
  }) {
    final all = Hive.box<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE)
        .values
        .where((txn) {
      final matchesEmployee =
          employeeId == null || txn.employeeId == employeeId;
      final matchesDate = (fromDate == null ||
              txn.date.isAtSameMomentAs(fromDate) ||
              txn.date.isAfter(Helper.beginningOfDay(fromDate))) &&
          (toDate == null ||
              txn.date.isAtSameMomentAs(toDate) ||
              txn.date.isBefore(Helper.endOfDay(toDate)));
      final matchesPresencs = txn.isFullDay || txn.isHalfDay;
      return matchesEmployee && matchesDate && matchesPresencs;
    }).toList();

    // Apply pagination
    if (page != null && pageSize != null) {
      final start = (page - 1) * pageSize;
      // final end = start + pageSize;
      return all.skip(start).take(pageSize).toList();
    }

    return all;
  }

  static List<EmployeeAttendance> getEmployeeAttendances(
      String employeeId, DateTime fromDate, DateTime toDate) {
    final box = Hive.box<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE);
    final attendances = box.values
        .where((att) =>
            att.employeeId == employeeId &&
            (att.date.isAtSameMomentAs(Helper.beginningOfDay(fromDate)) ||
                att.date.isAtSameMomentAs(Helper.endOfDay(toDate)) ||
                (att.date.isAfter(Helper.beginningOfDay(fromDate)) &&
                    att.date.isBefore(Helper.endOfDay(toDate)))))
        .toList();
    return attendances;
  }

  static EmployeeAttendance? findByEmployeeForDateOfSite(
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

  static EmployeeAttendance? findByEmployeeForDate(
      String employeeId, DateTime date) {
    return Hive.box<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE)
        .values
        .firstWhereOrNull((e) =>
            e.employeeId == employeeId &&
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
  static Future<void> upsert(EmployeeAttendance attendance,
      {bool sync = true}) async {
    final box = Hive.box<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE);

    await box.put(attendance.id, attendance);

    // Start silent sync in background
    final conn = await Connectivity().checkConnectivity();
    if (conn != ConnectivityResult.none &&
        !attendance.isSynced &&
        sync == true) {
      print("======= SYNCING ======>>>${attendance.toJson()}");
      SyncManager().syncEmployeeAttendanceToServer(attendance);
    }
  }

  static List<EmployeeAttendance> getUnsynced() {
    final box = Hive.box<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE);
    return box.values.where((e) => e.isSynced == false).toList();
  }

  static Future<void> clearAll() async {
    await Hive.box<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE).clear();
  }
}
