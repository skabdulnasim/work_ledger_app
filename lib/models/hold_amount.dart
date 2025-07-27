import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';

part 'hold_amount.g.dart';

@HiveType(typeId: HOLD_AMOUNT_BOX_TYPE)
class HoldAmount extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? serverId;

  @HiveField(2)
  bool isSynced;

  @HiveField(3)
  DateTime addedAt;

  @HiveField(4)
  String siteId;

  @HiveField(5)
  String employeeId;

  @HiveField(6)
  double amount;

  @HiveField(7)
  String remarks;

  @HiveField(8)
  List<String> attachFileIds;

  HoldAmount({
    required this.id,
    this.isSynced = false,
    this.serverId,
    required this.addedAt,
    required this.siteId,
    required this.employeeId,
    required this.amount,
    required this.remarks,
    this.attachFileIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'server_id': serverId,
      'is_synced': isSynced,
      'added_at': addedAt.toIso8601String(),
      'site_id': siteId,
      'employee_id': employeeId,
      'amount': amount,
      'remarks': remarks,
      'attachFileIds': attachFileIds,
    };
  }

  List<String> validate() {
    List<String> errors = [];

    if (id.trim().isEmpty) {
      errors.add("ID is required.");
    }

    if (employeeId.trim().isEmpty) {
      errors.add("Employee must required.");
    }

    if (amount <= 0) {
      errors.add("Expense amount must be greater than 0.00");
    }

    if (siteId.trim().isEmpty) {
      errors.add("Site must be required.");
    }

    if (addedAt.isAfter(DateTime.now())) {
      errors.add("Money add time must me now or before.");
    }

    return errors;
  }
}
