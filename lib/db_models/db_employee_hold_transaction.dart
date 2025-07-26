import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/employee_hold_transaction.dart';

class DBEmployeeHoldTransaction {
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(BOX_EMPLOYEE_HOLD_TRANSACTION)) {
      await Hive.openBox<EmployeeHoldTransaction>(
          BOX_EMPLOYEE_HOLD_TRANSACTION);
    }
  }

  static List<EmployeeHoldTransaction> getAll() {
    final box =
        Hive.box<EmployeeHoldTransaction>(BOX_EMPLOYEE_HOLD_TRANSACTION);
    return box.values.toList();
  }

  static List<EmployeeHoldTransaction> byEmployee(String employeeId) {
    final box =
        Hive.box<EmployeeHoldTransaction>(BOX_EMPLOYEE_HOLD_TRANSACTION);
    return box.values.where((e) => e.employeeId == employeeId).toList();
  }

  static ValueListenable<Box<EmployeeHoldTransaction>> getListenable() {
    return Hive.box<EmployeeHoldTransaction>(BOX_EMPLOYEE_HOLD_TRANSACTION)
        .listenable();
  }

  static Future<void> upsert(EmployeeHoldTransaction tx) async {
    final box =
        Hive.box<EmployeeHoldTransaction>(BOX_EMPLOYEE_HOLD_TRANSACTION);
    await box.put(tx.id, tx);
  }

  static Future<void> delete(String id) async {
    final box =
        Hive.box<EmployeeHoldTransaction>(BOX_EMPLOYEE_HOLD_TRANSACTION);
    await box.delete(id);
  }

  static Future<void> clearAll() async {
    final box =
        Hive.box<EmployeeHoldTransaction>(BOX_EMPLOYEE_HOLD_TRANSACTION);
    await box.clear();
  }

  static EmployeeHoldTransaction? find(String id) {
    final box =
        Hive.box<EmployeeHoldTransaction>(BOX_EMPLOYEE_HOLD_TRANSACTION);
    return box.get(id);
  }
}
