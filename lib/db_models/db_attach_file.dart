import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/attach_file.dart';

class DBAttachFile {
  /// Open box (call once on app startup)
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(BOX_ATTACH_FILE)) {
      await Hive.openBox<AttachFile>(BOX_ATTACH_FILE);
    }
  }

  /// Get all attach files
  static List<AttachFile> getAll() {
    return Hive.box<AttachFile>(BOX_ATTACH_FILE).values.toList();
  }

  /// Get files by file type (e.g. image, pdf)
  static List<AttachFile> getByType(String type) {
    return getAll().where((f) => f.fileType == type).toList();
  }

  /// Get file by ID
  static AttachFile? find(String id) {
    try {
      return Hive.box<AttachFile>(BOX_ATTACH_FILE)
          .values
          .firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get by serverId
  static AttachFile? byServerId(String serverId) {
    try {
      return Hive.box<AttachFile>(BOX_ATTACH_FILE)
          .values
          .firstWhere((f) => f.serverId == serverId);
    } catch (_) {
      return null;
    }
  }

  /// Get files that are not synced (if needed for upload)
  static List<AttachFile> getUnSynced() {
    return getAll().where((f) => f.serverId == null).toList();
  }

  /// Add or update a file by local id
  static Future<void> upsert(AttachFile file) async {
    final box = Hive.box<AttachFile>(BOX_ATTACH_FILE);
    final existingKey = box.keys.firstWhere(
      (key) => (box.get(key) as AttachFile).id == file.id,
      orElse: () => null,
    );

    if (existingKey != null) {
      await box.put(existingKey, file); // update
    } else {
      await box.add(file); // insert
    }
  }

  /// Delete file by ID
  static Future<void> delete(String id) async {
    final box = Hive.box<AttachFile>(BOX_ATTACH_FILE);
    final key = box.keys.firstWhere(
      (k) => (box.get(k) as AttachFile).id == id,
      orElse: () => null,
    );

    if (key != null) {
      await box.delete(key);
    }
  }

  /// Clear all files (optional use)
  static Future<void> clearAll() async {
    await Hive.box<AttachFile>(BOX_ATTACH_FILE).clear();
  }

  /// ValueListenable for UI updates
  static ValueListenable<Box<AttachFile>> getListenable() {
    return Hive.box<AttachFile>(BOX_ATTACH_FILE).listenable();
  }
}
