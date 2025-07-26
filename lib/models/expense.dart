import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';

part 'expense.g.dart';

@HiveType(typeId: EXPENSE_BOX_TYPE)
class Expense extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? serverId;

  @HiveField(2)
  bool isSynced;

  @HiveField(3)
  DateTime expenseAt;

  @HiveField(4)
  String siteId;

  @HiveField(5)
  String expenseById;

  @HiveField(6)
  String? expenseToId;

  @HiveField(7)
  double amount;

  @HiveField(8)
  String remarks;

  @HiveField(9)
  List<String> attachFileIds;

  Expense({
    required this.id,
    this.isSynced = false,
    this.serverId,
    required this.expenseAt,
    required this.siteId,
    required this.expenseById,
    this.expenseToId,
    required this.amount,
    required this.remarks,
    this.attachFileIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'server_id': serverId,
      'is_synced': isSynced,
      'expense_at': expenseAt.toIso8601String(),
      'site_id': siteId,
      'expense_by_id': expenseById,
      'expense_to_id': expenseToId,
      'amount': amount,
      'remarks': remarks,
      'attachFileIds': attachFileIds,
    };
  }
}
