import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/employee_salary_generate.dart';
import 'package:work_ledger/services/helper.dart';

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

  static Future<void> clear() async {
    await Hive.box<EmployeeSalaryGenerate>(BOX_EMPLOYEE_SALARY_GENERATE)
        .clear();
  }

  static bool isValidDate(DateTime dated) {
    final box = Hive.box<EmployeeSalaryGenerate>(BOX_EMPLOYEE_SALARY_GENERATE);

    final values = box.values
        .where(
          (data) =>
              (Helper.beginningOfDay(dated)
                      .isAtSameMomentAs(Helper.beginningOfDay(data.fromDate)) ||
                  Helper.beginningOfDay(dated)
                      .isAtSameMomentAs(Helper.beginningOfDay(data.toDate))) ||
              ((Helper.beginningOfDay(dated)
                          .isAfter(Helper.beginningOfDay(data.fromDate)) &&
                      Helper.beginningOfDay(dated)
                          .isBefore(Helper.beginningOfDay(data.toDate))) ||
                  Helper.beginningOfDay(dated)
                      .isBefore(Helper.beginningOfDay(data.toDate))),
        )
        .toList();
    if (values.isNotEmpty) {
      return false;
    } else {
      return true;
    }
  }
}
