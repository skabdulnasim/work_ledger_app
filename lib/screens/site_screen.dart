import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:work_ledger/db_models/db_company.dart';
import 'package:work_ledger/db_models/db_site.dart';
import 'package:work_ledger/db_models/db_skill.dart';
import 'package:work_ledger/models/company.dart';
import 'package:work_ledger/models/site.dart';
import 'package:work_ledger/models/site_payment_role.dart';
import 'package:hive/hive.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/skill.dart';
import 'package:work_ledger/services/sync_manager.dart';

class SiteScreen extends StatefulWidget {
  final Site site;

  const SiteScreen({super.key, required this.site});

  @override
  State<SiteScreen> createState() => _SiteScreenState();
}

class _SiteScreenState extends State<SiteScreen> {
  late TextEditingController nameController;
  late TextEditingController addressController;
  late List<SitePaymentRole> sitePaymentRoles = [];
  bool isEditing = false;
  Company? selectedCompany;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.site.name);
    addressController = TextEditingController(text: widget.site.address);

    // Load selected company (if editing)
    if (widget.site.companyId.isNotEmpty) {
      selectedCompany = DBCompany.find(widget.site.companyId);
    }

    if (widget.site.sitePaymentRoles != null) {
      if (widget.site.sitePaymentRoles!.isNotEmpty) {
        sitePaymentRoles = widget.site.sitePaymentRoles!.map((tier) {
          return SitePaymentRole(
              id: tier.id,
              skillId: tier.skillId,
              dailyWage: tier.dailyWage,
              overtimeRate: tier.overtimeRate);
        }).toList();
      } else {
        sitePaymentRoles = [];
      }
    } else {
      sitePaymentRoles = [];
    }

    if (widget.site.name.isEmpty) {
      isEditing = true;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void _addSitePayRole() {
    setState(() {
      sitePaymentRoles.add(SitePaymentRole(
          id: null, skillId: '1', dailyWage: 0, overtimeRate: 0));
    });
  }

  void _removeSitePayRole(int index) {
    setState(() {
      sitePaymentRoles.removeAt(index);
    });
  }

  Future<void> _saveSite() async {
    final updated = widget.site
      ..name = nameController.text.trim()
      ..address = addressController.text.trim()
      ..companyId = selectedCompany!.id!
      ..sitePaymentRoles = sitePaymentRoles;
    try {
      DBSite.upsertSite(updated);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Saved!")));

      // Start silent sync in background
      final conn = await Connectivity().checkConnectivity();
      if (conn != ConnectivityResult.none && !updated.isSynced) {
        SyncManager().syncSiteToServer(updated);
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
        title: const Text("Site Details"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _saveSite();
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
    final companies = DBCompany.getAllCompanies(); // Load from Hive
    final skills = DBSkill.getAllSkills();
    return ListView(
      children: [
        _buildTextField("Name", nameController),
        _buildTextField("Address", addressController),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white, // Optional background color
          ),
          child: DropdownButtonFormField<Company>(
            value: companies.contains(selectedCompany) ? selectedCompany : null,
            decoration: const InputDecoration(
              labelText: 'Company',
              border: InputBorder.none, // Important to avoid double border
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem<Company>(
                value: null,
                child: Text('-- Select Company --',
                    style: TextStyle(color: Colors.grey)),
              ),
              ...companies.map((company) {
                return DropdownMenuItem<Company>(
                  value: company,
                  child: Text(company.name),
                );
              }).toList(),
            ],
            onChanged: (Company? value) {
              setState(() {
                selectedCompany = value;
              });
            },
            validator: (value) {
              if (value == null) return 'Please select a company';
              return null;
            },
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          "Pay Role",
        ),
        SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: sitePaymentRoles.length,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Minimum Quantity
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: skills.any(
                                (s) => s.id == sitePaymentRoles[index].skillId)
                            ? sitePaymentRoles[index].skillId
                            : null, // fallback to null if skillId is not valid
                        decoration: const InputDecoration(labelText: "Skill"),
                        isExpanded: true,
                        items: skills.map((skill) {
                          return DropdownMenuItem<String>(
                            value: skill.id,
                            child: Text(skill.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              sitePaymentRoles[index].skillId = val;
                            });
                          }
                        },
                        validator: (val) =>
                            val == null ? 'Please select a skill' : null,
                      ),
                    ),
                    SizedBox(width: 8),
                    // Price
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Daily Wage",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        initialValue:
                            sitePaymentRoles[index].dailyWage.toString(),
                        onChanged: (value) {
                          sitePaymentRoles[index].dailyWage =
                              double.parse(value);
                        },
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              double.tryParse(value) == null) {
                            return "Enter a daily wage!";
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    // Price
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Overtime Rate/Hr",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        initialValue:
                            sitePaymentRoles[index].overtimeRate.toString(),
                        onChanged: (value) {
                          sitePaymentRoles[index].overtimeRate =
                              double.tryParse(value)!;
                        },
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              double.tryParse(value) == null) {
                            return "Enter a OT rate!";
                          }
                          return null;
                        },
                      ),
                    ),
                    // Remove button
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeSitePayRole(index),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _addSitePayRole,
          icon: const Icon(
            Icons.add,
            color: Colors.black,
          ),
          label: const Text(
            "Add Pay Role",
            style: TextStyle(color: Colors.black),
          ),
        ),

        SizedBox(height: 16),

        ///////////////////////////////////////////////
      ],
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Name", style: labelStyle),
        Text(widget.site.name, style: valueStyle),
        const SizedBox(height: 16),
        Text("Address", style: labelStyle),
        Text(widget.site.address, style: valueStyle),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                color: Colors.blueGrey,
                width: double.infinity,
                // decoration: BoxDecoration(
                //   border: Border.all(width: 1, color: Colors.black),
                // ),
                child: Text(
                  "SKILL",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.blueGrey,
                child: Text(
                  "WAGE",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.blueGrey,
                child: Text(
                  "OT",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        ...(widget.site.sitePaymentRoles ?? []).map(
          (e) => FutureBuilder<Skill?>(
            future: DBSkill.findById(e.skillId),
            builder: (context, snapshot) {
              final skillName = snapshot.data?.name ?? 'Unknown';
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Colors.black),
                      ),
                      child: Text(
                        "$skillName",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Colors.black),
                      ),
                      child: Text(
                        e.dailyWage.toStringAsFixed(2),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Colors.black),
                      ),
                      child: Text(
                        e.overtimeRate.toStringAsFixed(2),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
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
