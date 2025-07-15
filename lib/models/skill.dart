import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';
part 'skill.g.dart';

@HiveType(typeId: SKILL_BOX_TYPE)
class Skill extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? serverId;

  @HiveField(2)
  String name;

  @HiveField(3)
  bool isSynced;

  Skill({this.id, required this.name, this.isSynced = false, this.serverId});

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
    serverId: json['id']?.toString(), // ✅ parse from server
    name: json['name'] ?? '',
    isSynced: true,
  );

  Map<String, dynamic> toJson() => {
    'localId': id,
    'serverId': serverId,
    'name': name,
    'slog': normalizeName(name),
  };

  /// Validates the model, throws [Exception] if invalid
  Future<void> validate() async {
    final box = Hive.box<Skill>(BOX_SKILL);
    // ✅ ID uniqueness check
    final isDuplicateId = box.values.any(
      (skill) => skill.id.toString() == id.toString() && skill.key != key,
    ); // `key` is the HiveObject's internal key

    if (isDuplicateId) {
      throw Exception('ID must be unique');
    }

    if (name.trim().isEmpty) {
      throw Exception('Name is required');
    }

    final normalizedName = normalizeName(name);

    final isNameDuplicate = box.values.any((skill) {
      final normalizedSlug = normalizeName(skill.name);
      return normalizedName == normalizedSlug &&
          skill.id.toString() != id.toString();
    });

    if (isNameDuplicate) {
      throw Exception('Name slug must be unique');
    }
  }

  String normalizeName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }
}
