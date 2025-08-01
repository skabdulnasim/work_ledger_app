import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/my_client.dart';

class DBMyClient {
  /// Open box (call once on app startup)
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(BOX_CLIENT)) {
      await Hive.openBox<MyClient>(BOX_CLIENT);
    }
  }

  /// Get
  static MyClient? getMyClient() {
    try {
      return Hive.box<MyClient>(BOX_CLIENT).values.first;
    } catch (_) {
      return null;
    }
  }

  /// Add
  static Future<void> upsert(MyClient c) async {
    final box = Hive.box<MyClient>(BOX_CLIENT);
    await box.add(c); // insert
  }

  /// Clear all
  static Future<void> clearAll() async {
    await Hive.box<MyClient>(BOX_CLIENT).clear();
  }
}
