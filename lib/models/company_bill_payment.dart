import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';

part 'company_bill_payment.g.dart';

@HiveType(typeId: COMPANY_BILL_PAYMENT_BOX_TYPE)
class CompanyBillPayment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? serverId;

  @HiveField(2)
  String billNo;

  @HiveField(3)
  double amount;

  @HiveField(4)
  String paymentMode;

  @HiveField(5)
  String transactionType;

  @HiveField(6)
  String remarks;

  @HiveField(7)
  String siteId;

  @HiveField(8)
  DateTime transactionAt;

  @HiveField(9, defaultValue: false)
  bool isSynced;

  @HiveField(10)
  List<String> attachFileIds;

  CompanyBillPayment({
    required this.id,
    this.serverId,
    required this.billNo,
    required this.amount,
    required this.paymentMode,
    required this.transactionType,
    required this.remarks,
    required this.siteId,
    required this.transactionAt,
    this.isSynced = false,
    this.attachFileIds = const [],
  });

  factory CompanyBillPayment.fromJson(Map<String, dynamic> json) {
    return CompanyBillPayment(
      id: 'LOCAL-${DateTime.now().microsecondsSinceEpoch}',
      serverId: json['id']?.toString(),
      billNo: json['bill_no'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      paymentMode: json['payment_mode'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      remarks: json['remarks'] ?? '',
      siteId: json['site_id'].toString(), // Must map to local Site
      transactionAt: DateTime.parse(json['transaction_at']),
      isSynced: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverId': serverId,
        'bill_no': billNo,
        'amount': amount,
        'payment_mode': paymentMode,
        'transaction_type': transactionType,
        'remarks': remarks,
        'site_id': siteId,
        'transaction_at': transactionAt.toIso8601String(),
        'attachFileIds': attachFileIds,
      };

  List<String> validate() {
    List<String> errors = [];

    if (id.trim().isEmpty) {
      errors.add("ID is required.");
    }

    if (billNo.trim().isEmpty) {
      errors.add("Invoice number can't be blank.");
    }

    if (siteId.trim().isEmpty) {
      errors.add("Site must be required.");
    }

    if (amount <= 0) {
      errors.add("Amount must be greater than 0.00");
    }

    return errors;
  }
}
