import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:work_ledger/db_models/db_skill.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/skill.dart';
import 'package:work_ledger/services/sync_manager.dart';
import 'package:work_ledger/widgets/employee_attendance_tab.dart';
import 'package:work_ledger/widgets/employee_wallet_tab.dart';

class EmployeeScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeScreen({super.key, required this.employee});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController mobileNoController;
  bool isEditing = false;
  Skill? selectedSkill;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.employee.name);
    addressController = TextEditingController(text: widget.employee.address);
    mobileNoController = TextEditingController(text: widget.employee.mobileNo);
    // Load selected company (if editing)
    if (widget.employee.skillId.isNotEmpty) {
      selectedSkill = DBSkill.find(widget.employee.skillId);
    }

    if (widget.employee.name.isEmpty) {
      isEditing = true;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    mobileNoController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    final updated = widget.employee
      ..name = nameController.text.trim()
      ..address = addressController.text.trim()
      ..mobileNo = mobileNoController.text.trim()
      ..skillId = selectedSkill!.id!;
    try {
      final box = Hive.box<Employee>(BOX_EMPLOYEE);
      if (!updated.isInBox) {
        await box.add(updated);
      } else {
        await updated.save();
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Saved!")));

      // Start silent sync in background
      final conn = await Connectivity().checkConnectivity();
      if (conn != ConnectivityResult.none && !updated.isSynced) {
        SyncManager().syncEmployeeToServer(updated);
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee.name),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _saveEmployee();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isEditing ? _buildEditForm() : _buildViewMode(),
      ),
    );
  }

  Widget _buildEditForm() {
    final skills = DBSkill.getAllSkills();
    return ListView(
      children: [
        _buildTextField("Name", nameController),
        _buildTextField("Address", addressController),
        _buildTextField("Mobile No", mobileNoController),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white, // Optional background color
          ),
          child: DropdownButtonFormField<Skill>(
            value: skills.contains(selectedSkill) ? selectedSkill : null,
            decoration: const InputDecoration(
              labelText: 'Skill',
              border: InputBorder.none, // Important to avoid double border
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem<Skill>(
                value: null,
                child: Text('-- Select Skill --',
                    style: TextStyle(color: Colors.grey)),
              ),
              ...skills.map((skill) {
                return DropdownMenuItem<Skill>(
                  value: skill,
                  child: Text(skill.name),
                );
              }).toList(),
            ],
            onChanged: (Skill? value) {
              setState(() {
                selectedSkill = value;
              });
            },
            validator: (value) {
              if (value == null) return 'Please select a skill';
              return null;
            },
          ),
        ),

        const SizedBox(height: 16),

        ///////////////////////////////////////////////
      ],
    );
  }

  Widget _buildViewMode() {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name", style: labelStyle),
              Text(widget.employee.name, style: valueStyle),
              const SizedBox(height: 16),
              Text("Address", style: labelStyle),
              Text(widget.employee.address, style: valueStyle),
              const SizedBox(height: 16),
              Text("Skill", style: labelStyle),
              Text(selectedSkill?.name ?? "-", style: valueStyle),
              const SizedBox(height: 16),
            ],
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Attendance'),
              Tab(text: 'Wallet Tran.'),
            ],
          ),
          const SizedBox(height: 8),
          // Make sure the TabBarView is inside a fixed-height container
          Expanded(
            child: TabBarView(
              children: [
                EmployeeAttendanceTab(
                  employee: widget.employee,
                ),
                EmployeeWalletTab(
                  employee: widget.employee,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  TextStyle get labelStyle => const TextStyle(
      fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold);

  TextStyle get valueStyle =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
}
