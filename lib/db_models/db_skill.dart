import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/skill.dart';

class DBSkill {
  /// Open box (usually only once in main)
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(BOX_SKILL)) {
      await Hive.openBox<Skill>(BOX_SKILL);
    }
  }

  /// Get all companies
  static List<Skill> getAllSkills() {
    final box = Hive.box<Skill>(BOX_SKILL);
    return box.values.toList();
  }

  /// Get listenable for ValueListenableBuilder
  static ValueListenable<Box<Skill>> getListenable() {
    return Hive.box<Skill>(BOX_SKILL).listenable();
  }

  /// Add or update company by ID
  static Future<void> upsertSkill(Skill skill) async {
    final box = Hive.box<Skill>(BOX_SKILL);
    await box.put(skill.id, skill);
  }

  /// Delete company by ID
  static Future<void> deleteSkill(String id) async {
    final box = Hive.box<Skill>(BOX_SKILL);
    await box.delete(id);
  }

  /// Delete all companies (if needed for logout/reset)
  static Future<void> clearAll() async {
    final box = Hive.box<Skill>(BOX_SKILL);
    await box.clear();
  }

  static Skill? byServerId(String id) {
    final box = Hive.box<Skill>(BOX_SKILL);

    return box.values.firstWhere(
      (skill) => skill.serverId.toString() == id.toString(),
    );
  }

  static Future<Skill?> findById(String id) async {
    final box = Hive.box<Skill>(BOX_SKILL);

    return box.values.firstWhere(
      (skill) => skill.id.toString() == id.toString(),
    );
  }

  static Skill? find(String id) {
    final box = Hive.box<Skill>(BOX_SKILL);

    return box.values.firstWhere(
      (skill) => skill.id.toString() == id.toString(),
    );
  }
}
