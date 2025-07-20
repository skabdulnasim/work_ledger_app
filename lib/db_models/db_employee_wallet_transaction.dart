import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/employee_wallet_transaction.dart';
import 'package:work_ledger/services/helper.dart';

class DBEmployeeWalletTransaction {
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(BOX_EMPLOYEE_WALLET_TRANSACTION)) {
      await Hive.openBox<EmployeeWalletTransaction>(
          BOX_EMPLOYEE_WALLET_TRANSACTION);
    }
  }

  static List<EmployeeWalletTransaction> getAll({
    String? employeeId,
    DateTime? fromDate,
    DateTime? toDate,
    String? transactionType,
    int? page = 1,
    int? pageSize = 20,
  }) {
    final all =
        Hive.box<EmployeeWalletTransaction>(BOX_EMPLOYEE_WALLET_TRANSACTION)
            .values
            .where((txn) {
      final matchesEmployee =
          employeeId == null || txn.employeeId == employeeId;
      final matchesDate = (fromDate == null ||
              txn.transactionAt.isAtSameMomentAs(fromDate) ||
              txn.transactionAt.isAfter(Helper.beginningOfDay(fromDate))) &&
          (toDate == null ||
              txn.transactionAt.isAtSameMomentAs(toDate) ||
              txn.transactionAt.isBefore(Helper.endOfDay(toDate)));
      final matchesType =
          transactionType == null || txn.transactionType == transactionType;
      return matchesEmployee && matchesDate && matchesType;
    }).toList();

    // Apply pagination
    if (page != null && pageSize != null) {
      final start = (page - 1) * pageSize;
      // final end = start + pageSize;
      return all.skip(start).take(pageSize).toList();
    }

    return all;
  }

  static Future<void> upsert(EmployeeWalletTransaction tran) async {
    final box =
        Hive.box<EmployeeWalletTransaction>(BOX_EMPLOYEE_WALLET_TRANSACTION);
    await box.put(tran.id, tran);
  }
}
