import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/expense.dart';

class DBExpense {
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(BOX_EXPENSE)) {
      await Hive.openBox<Expense>(BOX_EXPENSE);
    }
  }

  static List<Expense> getAllExpenses() {
    final box = Hive.box<Expense>(BOX_EXPENSE);
    return box.values.toList();
  }

  static List<Expense> getExpensesBySite(String siteId) {
    final box = Hive.box<Expense>(BOX_EXPENSE);
    return box.values.where((e) => e.siteId == siteId).toList();
  }

  static ValueListenable<Box<Expense>> getListenable() {
    return Hive.box<Expense>(BOX_EXPENSE).listenable();
  }

  static Future<void> upsertExpense(Expense expense) async {
    final box = Hive.box<Expense>(BOX_EXPENSE);
    await box.put(expense.id, expense);
  }

  static Future<void> deleteExpense(String id) async {
    final box = Hive.box<Expense>(BOX_EXPENSE);
    await box.delete(id);
  }

  static Future<void> clearAll() async {
    final box = Hive.box<Expense>(BOX_EXPENSE);
    await box.clear();
  }

  static Expense? find(String id) {
    final box = Hive.box<Expense>(BOX_EXPENSE);
    return box.get(id);
  }

  static Expense? byServerId(String serverId) {
    final box = Hive.box<Expense>(BOX_EXPENSE);
    try {
      return box.values.firstWhere(
        (e) => e.serverId == serverId,
      );
    } catch (e) {
      return null;
    }
  }

  static List<Expense> getUnSynced() {
    return getAllExpenses().where((f) => !f.isSynced).toList();
  }
}
