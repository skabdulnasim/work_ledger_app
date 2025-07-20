import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_employee.dart';
import 'package:work_ledger/db_models/db_employee_attendance.dart';
import 'package:work_ledger/db_models/db_site.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:work_ledger/models/employee_attendance.dart';
import 'package:work_ledger/models/employee_salary_generate.dart';
import 'package:work_ledger/models/employee_wallet_transaction.dart';
import 'package:work_ledger/models/site.dart';
import 'package:work_ledger/models/site_payment_role.dart';
import 'package:work_ledger/models/skill.dart';

class DBEmployeeSalaryGenerate {
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(BOX_EMPLOYEE_SALARY_GENERATE)) {
      await Hive.openBox<EmployeeSalaryGenerate>(BOX_EMPLOYEE_SALARY_GENERATE);
    }
  }

  static List<EmployeeSalaryGenerate> getAll() {
    return Hive.box<EmployeeSalaryGenerate>(BOX_EMPLOYEE_SALARY_GENERATE)
        .values
        .toList();
  }

  static List<EmployeeSalaryGenerate> getUnSynced() {
    return getAll().where((e) => !e.isSynced).toList();
  }

  static EmployeeSalaryGenerate? getRecent() {
    final all = getAll();
    if (all.isEmpty) return null;

    all.sort((a, b) => b.id!.compareTo(a.id!));

    return all.first;
  }

  static Future<void> upsert(EmployeeSalaryGenerate salary) async {
    final box = Hive.box<EmployeeSalaryGenerate>(BOX_EMPLOYEE_SALARY_GENERATE);
    await box.put(salary.id, salary);
  }

  static Future<void> markAsSynced(
      EmployeeSalaryGenerate salary, String serverId) async {
    salary
      ..serverId = serverId
      ..isSynced = true;
    await salary.save();
  }

  static Future<void> clear() async {
    await Hive.box<EmployeeSalaryGenerate>(BOX_EMPLOYEE_SALARY_GENERATE)
        .clear();
  }
}
