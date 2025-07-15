import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/site.dart';

class DBSite {
  /// Open box (usually only once in main)
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(BOX_SITE)) {
      await Hive.openBox<Site>(BOX_SITE);
    }
  }

  /// Get all companies
  static List<Site> getAllSites() {
    final box = Hive.box<Site>(BOX_SITE);
    return box.values.toList();
  }

  /// Get listenable for ValueListenableBuilder
  static ValueListenable<Box<Site>> getListenable() {
    return Hive.box<Site>(BOX_SITE).listenable();
  }

  /// Add or update site by ID
  static Future<void> upsertSite(Site site) async {
    final box = Hive.box<Site>(BOX_SITE);
    await box.put(site.id, site);
  }

  /// Delete site by ID
  static Future<void> deleteSite(String id) async {
    final box = Hive.box<Site>(BOX_SITE);
    await box.delete(id);
  }

  /// Delete all companies (if needed for logout/reset)
  static Future<void> clearAll() async {
    final box = Hive.box<Site>(BOX_SITE);
    await box.clear();
  }

  /// Check if a mobile number is duplicate (last 6 digits match)
  static bool isNameAndCompanyDuplicate(
      String name, String companyId, String id) {
    final box = Hive.box<Site>(BOX_SITE);

    return box.values.any((site) {
      return site.id.toString() != id.toString() &&
          site.name == name &&
          site.companyId == companyId;
    });
  }

  static Site? byServerId(String id) {
    final box = Hive.box<Site>(BOX_SITE);

    return box.values.firstWhere(
      (site) => site.serverId.toString() == id.toString(),
    );
  }

  static Site? find(String id) {
    final box = Hive.box<Site>(BOX_SITE);

    return box.values.firstWhere(
      (site) => site.id.toString() == id.toString(),
    );
  }
}
