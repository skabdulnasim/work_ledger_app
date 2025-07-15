import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';

part 'company.g.dart';

@HiveType(typeId: COMPANY_BOX_TYPE)
class Company extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String address;

  @HiveField(3)
  String mobileNo;

  @HiveField(4)
  String gstin;

  @HiveField(5)
  bool isSynced;

  @HiveField(6)
  String? serverId;

  Company({
    this.id,
    required this.name,
    required this.address,
    required this.mobileNo,
    required this.gstin,
    this.isSynced = false,
    this.serverId,
  });

  factory Company.fromJson(Map<String, dynamic> json) => Company(
    serverId: json['id']?.toString(), // ✅ parse from server
    name: json['name'] ?? '',
    address: json['address'] ?? '',
    mobileNo: json['mobile_no'] ?? '',
    gstin: json['gstin'] ?? '',
    isSynced: true,
  );

  Map<String, dynamic> toJson() => {
    'localId': id,
    'serverId': serverId,
    'name': name,
    'address': address,
    'mobile_no': mobileNo,
    'gstin': gstin,
  };

  /// Validates the model, throws [Exception] if invalid
  Future<void> validate() async {
    final box = Hive.box<Company>(BOX_COMPANY);
    // ✅ ID uniqueness check
    final isDuplicateId = box.values.any(
      (company) => company.id.toString() == id.toString() && company.key != key,
    ); // `key` is the HiveObject's internal key

    if (isDuplicateId) {
      throw Exception('ID must be unique');
    }

    if (name.trim().isEmpty) {
      throw Exception('Name is required');
    }

    if (mobileNo.trim().isEmpty) {
      throw Exception('Mobile number is required');
    }

    String cleanedMobile = mobileNo.replaceAll(RegExp(r'\D'), '');

    if (cleanedMobile.trim().length < 10 || cleanedMobile.trim().length > 13) {
      throw Exception('Valid mobile number is required');
    }

    final normalizedInput = normalize(mobileNo);

    final isDuplicate = box.values.any((company) {
      final normalizedCompany = normalize(company.mobileNo.toString());

      return normalizedInput == normalizedCompany &&
          company.id.toString() != id.toString();
    });

    if (isDuplicate) {
      throw Exception('Mobile number must be unique');
    }
  }

  String normalize(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 6 ? digits.substring(digits.length - 6) : digits;
  }
}
