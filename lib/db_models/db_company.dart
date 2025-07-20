import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/company.dart';

class DBCompany {
  /// Open box (usually only once in main)
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(BOX_COMPANY)) {
      await Hive.openBox<Company>(BOX_COMPANY);
    }
  }

  /// Get all companies
  static List<Company> getAllCompanies() {
    final box = Hive.box<Company>(BOX_COMPANY);
    return box.values.toList();
  }

  /// Get listenable for ValueListenableBuilder
  static ValueListenable<Box<Company>> getListenable() {
    return Hive.box<Company>(BOX_COMPANY).listenable();
  }

  /// Add or update company by ID
  static Future<void> upsertCompany(Company company) async {
    final box = Hive.box<Company>(BOX_COMPANY);
    await box.put(company.id, company);
  }

  /// Delete company by ID
  static Future<void> deleteCompany(String id) async {
    final box = Hive.box<Company>(BOX_COMPANY);
    await box.delete(id);
  }

  /// Delete all companies (if needed for logout/reset)
  static Future<void> clearAll() async {
    final box = Hive.box<Company>(BOX_COMPANY);
    await box.clear();
  }

  /// Check if a mobile number is duplicate (last 6 digits match)
  static bool isMobileDuplicate(String mobileNo, String id) {
    String normalize(String number) {
      final digits = number.replaceAll(RegExp(r'\D'), '');
      return digits.length >= 6 ? digits.substring(digits.length - 6) : digits;
    }

    final inputLast6 = normalize(mobileNo);
    final box = Hive.box<Company>(BOX_COMPANY);

    return box.values.any((company) {
      final last6 = normalize(company.mobileNo);
      return company.id.toString() != id.toString() && last6 == inputLast6;
    });
  }

  static Company? byServerId(String id) {
    final box = Hive.box<Company>(BOX_COMPANY);
    try {
      return box.values.firstWhere(
        (company) => company.serverId == id,
      );
    } catch (e) {
      return null;
    }
  }

  static Company? find(String id) {
    final box = Hive.box<Company>(BOX_COMPANY);
    try {
      return box.values.firstWhere(
        (company) => company.id.toString() == id.toString(),
      );
    } catch (e) {
      return null;
    }
  }
}
