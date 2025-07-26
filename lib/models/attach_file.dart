import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';

part 'attach_file.g.dart';

@HiveType(typeId: ATTACH_FILE_BOX_TYPE)
class AttachFile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String filename;

  @HiveField(2)
  String fileType;

  @HiveField(3)
  String? contentType;

  @HiveField(4)
  String? previewUrl;

  @HiveField(5)
  String? downloadUrl;

  @HiveField(6)
  String? localPath; // if downloaded

  @HiveField(7)
  String? serverId;

  AttachFile({
    required this.id,
    required this.filename,
    required this.fileType,
    this.contentType,
    this.previewUrl,
    this.downloadUrl,
    this.localPath,
    this.serverId,
  });
}
