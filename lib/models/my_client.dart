import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';

part 'my_client.g.dart';

@HiveType(typeId: CLIENT_BOX_TYPE)
class MyClient extends HiveObject {
  @HiveField(0)
  String serverId;

  @HiveField(1)
  String name;

  @HiveField(2)
  String mobile;

  @HiveField(3)
  String? address;

  @HiveField(4)
  String subdomain;

  MyClient({
    required this.serverId,
    required this.name,
    required this.mobile,
    this.address,
    required this.subdomain,
  });
}
