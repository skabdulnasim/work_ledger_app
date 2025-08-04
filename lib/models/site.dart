import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_company.dart';
import 'package:work_ledger/models/site_payment_role.dart';
part 'site.g.dart';

@HiveType(typeId: SITE_BOX_TYPE)
class Site extends HiveObject {
  @HiveField(0)
  String? id; // uuid for offline
  @HiveField(1)
  String name;
  @HiveField(2)
  String address;
  @HiveField(3)
  bool isSynced;
  @HiveField(4)
  String? serverId;
  @HiveField(5)
  String companyId;
  @HiveField(6)
  List<SitePaymentRole> sitePaymentRoles;

  Site({
    this.id,
    required this.name,
    required this.address,
    this.isSynced = false,
    this.serverId,
    required this.companyId,
    this.sitePaymentRoles = const [],
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    final companyServerId = json['company_id'].toString();

    // Attempt to find the local company by its server ID
    final localCompany = DBCompany.byServerId(companyServerId);

    if (localCompany == null) {
      throw Exception('No local company found with serverId: $companyServerId');
    }

    return Site(
      serverId: json['id']?.toString(),
      name: json['name'],
      address: json['address'],
      isSynced: true,
      companyId: localCompany.id!,
      sitePaymentRoles: List<SitePaymentRole>.from(
        json['site_payment_roles']?.map(
          (x) => SitePaymentRole.fromJson(x),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'localId': id,
        'serverId': serverId,
        "name": name,
        "address": address,
        "companyId": companyId,
        'site_payment_roles': sitePaymentRoles!.map((x) => x.toJson()).toList(),
      };

  String toString() => json.encode(toJson());
}
