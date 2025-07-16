import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/employee.dart';

class DBEmployee {
  /// Open box (usually only once in main)
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(BOX_EMPLOYEE)) {
      await Hive.openBox<Employee>(BOX_EMPLOYEE);
    }
  }

  /// Get all employees
  static List<Employee> getAllEmployees() {
    final box = Hive.box<Employee>(BOX_EMPLOYEE);
    return box.values.toList();
  }

  /// Get listenable for ValueListenableBuilder
  static ValueListenable<Box<Employee>> getListenable() {
    return Hive.box<Employee>(BOX_EMPLOYEE).listenable();
  }

  /// Get paginated employees
  static List<Employee> getEmployees(
      {int offset = 0, int limit = 10, String qry = ''}) {
    final box = Hive.box<Employee>(BOX_EMPLOYEE);
    var allEmployees = box.values.toList();
    if (qry.isNotEmpty) {
      allEmployees = allEmployees
          .where((e) =>
              e.name.toLowerCase().contains(qry.toLowerCase()) ||
              e.mobileNo.contains(qry))
          .toList();
    }
    final end = (offset + limit) > allEmployees.length
        ? allEmployees.length
        : (offset + limit);
    return allEmployees.sublist(offset, end);
  }

  /// Add or update employee by ID
  static Future<void> upsertEmployee(Employee employee) async {
    final box = Hive.box<Employee>(BOX_EMPLOYEE);
    await box.put(employee.id, employee);
  }

  /// Delete employee by ID
  static Future<void> deleteEmployee(String id) async {
    final box = Hive.box<Employee>(BOX_EMPLOYEE);
    await box.delete(id);
  }

  /// Delete all employees (if needed for logout/reset)
  static Future<void> clearAll() async {
    final box = Hive.box<Employee>(BOX_EMPLOYEE);
    await box.clear();
  }

  /// Check if a mobile number is duplicate (last 6 digits match)
  static bool isMobileDuplicate(String mobileNo, String id) {
    String normalize(String number) {
      final digits = number.replaceAll(RegExp(r'\D'), '');
      return digits.length >= 6 ? digits.substring(digits.length - 6) : digits;
    }

    final inputLast6 = normalize(mobileNo);
    final box = Hive.box<Employee>(BOX_EMPLOYEE);

    return box.values.any((employee) {
      final last6 = normalize(employee.mobileNo);
      return employee.id.toString() != id.toString() && last6 == inputLast6;
    });
  }

  static Employee? byServerId(String id) {
    final box = Hive.box<Employee>(BOX_EMPLOYEE);

    return box.values.firstWhere(
      (employee) => employee.serverId.toString() == id.toString(),
    );
  }

  static Employee? find(String id) {
    final box = Hive.box<Employee>(BOX_EMPLOYEE);

    return box.values.firstWhere(
      (employee) => employee.id.toString() == id.toString(),
    );
  }
}
