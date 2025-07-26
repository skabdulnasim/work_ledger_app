import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/hold_amount.dart';

class DBHoldAmount {
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(BOX_HOLD_AMOUNT)) {
      await Hive.openBox<HoldAmount>(BOX_HOLD_AMOUNT);
    }
  }

  static List<HoldAmount> getAllHoldAmounts() {
    final box = Hive.box<HoldAmount>(BOX_HOLD_AMOUNT);
    return box.values.toList();
  }

  static List<HoldAmount> getHoldAmountsBySite(String siteId) {
    final box = Hive.box<HoldAmount>(BOX_HOLD_AMOUNT);
    return box.values.where((e) => e.siteId == siteId).toList();
  }

  static ValueListenable<Box<HoldAmount>> getListenable() {
    return Hive.box<HoldAmount>(BOX_HOLD_AMOUNT).listenable();
  }

  static Future<void> upsertHoldAmount(HoldAmount hold) async {
    final box = Hive.box<HoldAmount>(BOX_HOLD_AMOUNT);
    await box.put(hold.id, hold);
  }

  static Future<void> deleteHoldAmount(String id) async {
    final box = Hive.box<HoldAmount>(BOX_HOLD_AMOUNT);
    await box.delete(id);
  }

  static Future<void> clearAll() async {
    final box = Hive.box<HoldAmount>(BOX_HOLD_AMOUNT);
    await box.clear();
  }

  static HoldAmount? find(String id) {
    final box = Hive.box<HoldAmount>(BOX_HOLD_AMOUNT);
    return box.get(id);
  }

  static HoldAmount? byServerId(String serverId) {
    final box = Hive.box<HoldAmount>(BOX_HOLD_AMOUNT);
    try {
      return box.values.firstWhere(
        (e) => e.serverId == serverId,
      );
    } catch (e) {
      return null;
    }
  }
}
