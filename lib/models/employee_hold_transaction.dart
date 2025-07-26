import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';

part 'employee_hold_transaction.g.dart';

@HiveType(typeId: EMPLOYEE_HOLD_TRANSACTION_BOX_TYPE)
class EmployeeHoldTransaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String employeeId;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime transactionAt;

  @HiveField(4)
  String transactionableType;

  @HiveField(5)
  String transactionableId;

  @HiveField(6)
  String transactionType;

  @HiveField(7)
  String remarks;

  @HiveField(8)
  double balanceAmount;

  EmployeeHoldTransaction({
    required this.id,
    required this.employeeId,
    required this.amount,
    required this.transactionAt,
    required this.transactionableType,
    required this.transactionableId,
    required this.transactionType,
    required this.remarks,
    required this.balanceAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'amount': amount,
      'transaction_at': transactionAt.toIso8601String(),
      'transactionable_type': transactionableType,
      'transactionable_id': transactionableId,
      'transaction_type': transactionType,
      'remarks': remarks,
      'balance_amount': balanceAmount,
    };
  }
}
