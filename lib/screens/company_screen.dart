import 'package:flutter/material.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/company.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:work_ledger/services/secure_api_service.dart';

class CompanyScreen extends StatefulWidget {
  final Company company;

  const CompanyScreen({super.key, required this.company});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  bool isEditing = false;
  String? idController;
  late TextEditingController nameController;
  late TextEditingController mobileNoController;
  late TextEditingController addressController;
  late TextEditingController gstinController;

  @override
  void initState() {
    super.initState();
    idController = widget.company.id;
    nameController = TextEditingController(text: widget.company.name);
    mobileNoController = TextEditingController(text: widget.company.mobileNo);
    addressController = TextEditingController(text: widget.company.address);
    gstinController = TextEditingController(text: widget.company.gstin);

    // Automatically go into editing mode if name and mobileNo are empty
    if (widget.company.name.isEmpty && widget.company.mobileNo.isEmpty) {
      isEditing = true;
    }
  }

  @override
  void dispose() {
    idController = null;
    nameController.dispose();
    mobileNoController.dispose();
    addressController.dispose();
    gstinController.dispose();
    super.dispose();
  }

  Future<void> _saveCompany() async {
    final updatedCompany =
        widget.company
          ..name = nameController.text.trim()
          ..mobileNo = mobileNoController.text.trim()
          ..address = addressController.text.trim()
          ..gstin = gstinController.text.trim();

    try {
      await updatedCompany.validate();

      final companyBox = Hive.box<Company>(BOX_COMPANY);

      // Save offline (initially)
      if (!updatedCompany.isInBox) {
        await companyBox.add(updatedCompany);
      } else {
        updatedCompany.isSynced = false;
        await updatedCompany.save();
      }

      _showMessage('Saved!.');

      // Start silent sync in background
      final conn = await Connectivity().checkConnectivity();
      if (conn != ConnectivityResult.none && !updatedCompany.isSynced) {
        _syncToServer(updatedCompany);
      }

      Navigator.pop(context, true); // Close screen after save
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _syncToServer(Company company) async {
    try {
      final payload = {
        "company": {
          "name": company.name,
          "address": company.address,
          "mobile_no": company.mobileNo,
          "gstin": company.gstin,
        },
      };

      if (company.serverId != null) {
        final response = await SecureApiService.updateCompany(company);

        if (response != null && response['id'] != null) {
          // Update company with server ID and mark as synced
          company.isSynced = true;

          await company.save(); // Save updated info to Hive
        }
      } else {
        final response = await SecureApiService.createCompany(company);

        if (response != null && response['id'] != null) {
          // Update company with server ID and mark as synced
          company
            ..serverId = response['id'].toString()
            ..isSynced = true;

          await company.save(); // Save updated info to Hive
        }
      }
    } catch (e) {
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
        title: const Text("Company Details"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _saveCompany();
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
        Text(widget.company.name, style: valueStyle),
        const SizedBox(height: 16),

        Text("Mobile No", style: labelStyle),
        Text(widget.company.mobileNo, style: valueStyle),
        const SizedBox(height: 16),

        Text("Address", style: labelStyle),
        Text(widget.company.address, style: valueStyle),
        const SizedBox(height: 16),

        Text("GSTIN", style: labelStyle),
        Text(widget.company.gstin, style: valueStyle),
      ],
    );
  }

  Widget _buildEditForm() {
    return ListView(
      children: [
        _buildTextField("Name", nameController),
        _buildTextField(
          "Mobile No",
          mobileNoController,
          keyboard: TextInputType.phone,
        ),
        _buildTextField("Address", addressController),
        _buildTextField("GSTIN", gstinController),
      ],
    );
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
