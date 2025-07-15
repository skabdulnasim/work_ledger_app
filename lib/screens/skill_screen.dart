import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/skill.dart';

import 'package:work_ledger/services/secure_api_service.dart';

class SkillScreen extends StatefulWidget {
  final Skill skill;

  const SkillScreen({super.key, required this.skill});

  @override
  State<SkillScreen> createState() => _SkillScreenState();
}

class _SkillScreenState extends State<SkillScreen> {
  bool isEditing = false;
  String? idController;
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    idController = widget.skill.id;
    nameController = TextEditingController(text: widget.skill.name);

    // Automatically go into editing mode if name and mobileNo are empty
    if (widget.skill.name.isEmpty) {
      isEditing = true;
    }
  }

  @override
  void dispose() {
    idController = null;
    nameController.dispose();

    super.dispose();
  }

  Future<void> _saveSkill() async {
    final updatedSkill = widget.skill..name = nameController.text.trim();

    try {
      await updatedSkill.validate();

      final skillBox = Hive.box<Skill>(BOX_SKILL);

      // Save offline (initially)
      if (!updatedSkill.isInBox) {
        await skillBox.add(updatedSkill);
      } else {
        updatedSkill.isSynced = false;
        await updatedSkill.save();
      }

      _showMessage('Saved!.');

      // Start silent sync in background
      final conn = await Connectivity().checkConnectivity();
      if (conn != ConnectivityResult.none && !updatedSkill.isSynced) {
        _syncToServer(updatedSkill);
      }

      Navigator.pop(context, true); // Close screen after save
    } catch (e) {
      print(e.toString());
      _showMessage(e.toString());
    }
  }

  Future<void> _syncToServer(Skill skill) async {
    try {
      final payload = {"employee_role": skill.toJson()};

      if (skill.serverId != null) {
        final response = await SecureApiService.updateSkill(skill);

        if (response != null && response['id'] != null) {
          // Update company with server ID and mark as synced
          skill.isSynced = true;

          await skill.save(); // Save updated info to Hive
        }
      } else {
        final response = await SecureApiService.createSkill(skill);

        if (response != null && response['id'] != null) {
          // Update company with server ID and mark as synced
          skill
            ..serverId = response['id'].toString()
            ..isSynced = true;

          await skill.save(); // Save updated info to Hive
        }
      }
    } catch (e) {
      print("Background sync failed: $e");
      debugPrint("Background sync failed: $e");
      // Optional: queue for retry later
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Skill Details"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _saveSkill();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isEditing ? _buildEditForm() : _buildViewMode(),
      ),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Name", style: labelStyle),
        Text(widget.skill.name, style: valueStyle),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEditForm() {
    return ListView(children: [_buildTextField("Name", nameController)]);
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  TextStyle get labelStyle => const TextStyle(
    fontSize: 14,
    color: Colors.grey,
    fontWeight: FontWeight.bold,
  );

  TextStyle get valueStyle =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
}
