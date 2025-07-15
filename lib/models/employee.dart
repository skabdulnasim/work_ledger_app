import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';

part 'employee.g.dart';

@HiveType(typeId: EMPLOYEE_BOX_TYPE)
class Employee extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String address;

  @HiveField(3)
  String mobileNo;

  @HiveField(4)
  String skillId; // EMPLOYEE ROLE ID

  @HiveField(5)
  bool isSynced;

  @HiveField(6)
  String? serverId;

  @HiveField(7)
  double walletBalance;

  @HiveField(8)
  double holdAmount;

  Employee({
    this.id,
    required this.name,
    required this.address,
    required this.mobileNo,
    required this.skillId,
    this.holdAmount = 0.00,
    this.walletBalance = 0.00,
    this.isSynced = false,
    this.serverId,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        serverId: json['id']?.toString(), // ✅ parse from server
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        mobileNo: json['mobile_no'] ?? '',
        skillId: json['skill_id'] ?? '',
        isSynced: true,
      );

  Map<String, dynamic> toJson() => {
        'localId': id,
        'serverId': serverId,
        'name': name,
        'address': address,
        'mobile_no': mobileNo,
        'skill_id': skillId,
      };

  /// Validates the model, throws [Exception] if invalid
  Future<void> validate() async {
    final box = Hive.box<Employee>(BOX_EMPLOYEE);
    // ✅ ID uniqueness check
    final isDuplicateId = box.values.any(
      (employee) =>
          employee.id.toString() == id.toString() && employee.key != key,
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

    final isDuplicate = box.values.any((employee) {
      final normalizedEmployee = normalize(employee.mobileNo.toString());

      return normalizedInput == normalizedEmployee &&
          employee.id.toString() != id.toString();
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
