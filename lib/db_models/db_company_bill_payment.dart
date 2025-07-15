import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/company_bill_payment.dart';

class DBCompanyBillPayment {
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(BOX_COMPANY_BILL_PAYMENT)) {
      await Hive.openBox<CompanyBillPayment>(BOX_COMPANY_BILL_PAYMENT);
    }
  }

  /// Get all company_bill_payments
  static List<CompanyBillPayment> getAllCompanyBillPayments() {
    final box = Hive.box<CompanyBillPayment>(BOX_COMPANY_BILL_PAYMENT);
    return box.values.toList();
  }

  /// Get all payments by site ID
  static List<CompanyBillPayment> getAllCompanyBillPaymentsBySite(
      String siteId) {
    final box = Hive.box<CompanyBillPayment>(BOX_COMPANY_BILL_PAYMENT);
    return box.values.where((payment) => payment.siteId == siteId).toList();
  }

  /// Get listenable for ValueListenableBuilder
  static ValueListenable<Box<CompanyBillPayment>> getListenable() {
    return Hive.box<CompanyBillPayment>(BOX_COMPANY_BILL_PAYMENT).listenable();
  }

  /// Add or update site by ID
  static Future<void> upsertCompanyBillPayment(CompanyBillPayment site) async {
    final box = Hive.box<CompanyBillPayment>(BOX_COMPANY_BILL_PAYMENT);
    await box.put(site.id, site);
  }

  /// Delete site by ID
  static Future<void> deleteCompanyBillPayment(String id) async {
    final box = Hive.box<CompanyBillPayment>(BOX_COMPANY_BILL_PAYMENT);
    await box.delete(id);
  }

  /// Delete all company_bill_payments (if needed for logout/reset)
  static Future<void> clearAll() async {
    final box = Hive.box<CompanyBillPayment>(BOX_COMPANY_BILL_PAYMENT);
    await box.clear();
  }

  /// Check if a mobile number is duplicate (last 6 digits match)
  static bool isNameAndCompanyDuplicate(
      String billNo, String siteId, String id) {
    final box = Hive.box<CompanyBillPayment>(BOX_COMPANY_BILL_PAYMENT);

    return box.values.any((cbp) {
      return cbp.id.toString() != id.toString() &&
          cbp.billNo == billNo &&
          cbp.siteId == siteId;
    });
  }

  static CompanyBillPayment? byServerId(String id) {
    final box = Hive.box<CompanyBillPayment>(BOX_COMPANY_BILL_PAYMENT);

    return box.values.firstWhere(
      (site) => site.serverId.toString() == id.toString(),
    );
  }

  static CompanyBillPayment? find(String id) {
    final box = Hive.box<CompanyBillPayment>(BOX_COMPANY_BILL_PAYMENT);

    return box.values.firstWhere(
      (site) => site.id.toString() == id.toString(),
    );
  }
}
