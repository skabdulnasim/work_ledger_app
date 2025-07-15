import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_skill.dart';
part 'site_payment_role.g.dart';

@HiveType(typeId: SITE_PAY_ROLE_BOX_TYPE)
class SitePaymentRole extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? serverId;
  @HiveField(2)
  String skillId;
  @HiveField(3)
  bool isSynced;
  @HiveField(4, defaultValue: 0.00)
  double dailyWage;
  @HiveField(5, defaultValue: 0.00)
  double overtimeRate;

  SitePaymentRole({
    this.id,
    this.isSynced = false,
    this.serverId,
    required this.skillId,
    required this.dailyWage,
    required this.overtimeRate,
  });

  factory SitePaymentRole.fromJson(Map<String, dynamic> json) {
    final skillServerId = json['employee_role_id'].toString();

    // Attempt to find the local company by its server ID
    final localEmployeeRole = DBSkill.byServerId(skillServerId);

    if (localEmployeeRole == null) {
      throw Exception('No local skill found with serverId: $skillServerId');
    }

    return SitePaymentRole(
      serverId: json['id']?.toString(),
      isSynced: true,
      skillId: localEmployeeRole.id!,
      dailyWage: double.parse(json['daily_wage']),
      overtimeRate: double.parse(json['overtime_rate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'localId': id,
        'serverId': serverId,
        "skillId": skillId,
        "dailyWage": dailyWage,
        "overtimeRate": overtimeRate,
      };
}
