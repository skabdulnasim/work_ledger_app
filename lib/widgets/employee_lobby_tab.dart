import 'package:flutter/material.dart';
import 'package:work_ledger/db_models/db_skill.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:work_ledger/models/skill.dart';
import 'package:work_ledger/services/helper.dart';

class EmployeeLobbyTab extends StatefulWidget {
  final Employee employee;
  const EmployeeLobbyTab({super.key, required this.employee});

  @override
  State<EmployeeLobbyTab> createState() => _EmployeeLobbyTabState();
}

class _EmployeeLobbyTabState extends State<EmployeeLobbyTab> {
  late Employee employee;
  Skill? selectedSkill;

  @override
  void initState() {
    super.initState();
    employee = widget.employee;
    selectedSkill = DBSkill.find(employee.skillId);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Avatar
          CircleAvatar(
            radius: 48,
            backgroundColor: Helper.getAvatarFillColor(), // Customize color
            child: Text(
              Helper.getAvatarText(
                  employee.name), // Replace with dynamic initials
              style: TextStyle(
                color: Helper.getAvatarColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Name
          Text(
            employee.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            employee.mobileNo,
            style: const TextStyle(fontSize: 12),
          ),

          const SizedBox(height: 24),

          // Info Card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow(Icons.location_on, "Address", employee.address),
                  const Divider(),
                  _buildInfoRow(Icons.work, "Skill", selectedSkill?.name ?? ''),
                  const Divider(),
                  _buildInfoRow(
                    Icons.account_balance_wallet,
                    "Wallet Balance",
                    employee.walletBalance.toStringAsFixed(2),
                    valueColor: employee.walletBalance > 0
                        ? Colors.green
                        : (employee.walletBalance < 0
                            ? Colors.red
                            : Colors.black),
                  ),
                  const Divider(),
                  _buildInfoRow(Icons.money_off, "Expance Balance",
                      employee.holdAmount.toStringAsFixed(2),
                      valueColor: employee.holdAmount > 0
                          ? Colors.green
                          : (employee.holdAmount < 0
                              ? Colors.red
                              : Colors.lightBlue),
                      trailing: ElevatedButton.icon(
                        icon: Icon(Icons.bar_chart),
                        label: Text("Transactions"),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/expense_trans',
                            arguments: employee, // Pass the site object here
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 255, 235, 170),
                          foregroundColor: Colors.purple,
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                4), // Rectangle with slight curve
                          ),
                          elevation: 3,
                          shadowColor: Colors.black45,
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor, Widget? trailing}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (trailing != null) trailing
      ],
    );
  }
}
