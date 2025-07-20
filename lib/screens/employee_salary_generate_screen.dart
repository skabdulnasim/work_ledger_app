import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:work_ledger/db_models/db_employee.dart';
import 'package:work_ledger/db_models/db_employee_attendance.dart';
import 'package:work_ledger/db_models/db_employee_wallet_transaction.dart';
import 'package:work_ledger/db_models/db_site.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:work_ledger/models/employee_salary_generate.dart';
import 'package:work_ledger/db_models/db_employee_salary_generate.dart';
import 'package:intl/intl.dart';
import 'package:work_ledger/models/employee_wallet_transaction.dart';
import 'package:work_ledger/services/sync_manager.dart';

class EmployeeSalaryGenerateScreen extends StatefulWidget {
  final EmployeeSalaryGenerate salary;

  const EmployeeSalaryGenerateScreen({super.key, required this.salary});

  @override
  State<EmployeeSalaryGenerateScreen> createState() =>
      _EmployeeSalaryGenerateScreenState();
}

class _EmployeeSalaryGenerateScreenState
    extends State<EmployeeSalaryGenerateScreen> {
  late TextEditingController titleController;
  late TextEditingController remarksController;

  DateTime? fromDate;
  DateTime? toDate;

  final dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.salary.title);
    remarksController =
        TextEditingController(text: widget.salary.remarks ?? '');

    // Try loading default fromDate (e.g., previous toDate + 1 day)
    Future.microtask(() async {
      final previous = DBEmployeeSalaryGenerate.getRecent();
      if (previous != null) {
        setState(() {
          fromDate = previous.toDate.add(const Duration(days: 1));
        });
      } else {
        setState(() {
          fromDate = DateTime.now().subtract(const Duration(days: 30));
        });
      }
    });

    toDate = widget.salary.toDate; // Optional: prefill if exists
  }

  Future<void> selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isFrom ? (fromDate ?? DateTime.now()) : (toDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  Future<void> save() async {
    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("From date upto date are required")),
      );
      return;
    }

    widget.salary
      ..title = titleController.text.trim()
      ..fromDate = fromDate!
      ..toDate = toDate!
      ..remarks = remarksController.text.trim();

    await DBEmployeeSalaryGenerate.upsert(widget.salary);

    List<Employee> allEmployees = DBEmployee.getAllEmployees();
    for (var employee in allEmployees) {
      // Filter attendance within date range
      final attendances = DBEmployeeAttendance.getEmployeeAttendances(
          employee.id!, fromDate!, toDate!);

      double totalAttendanceAmount = 0;
      double totalOtAmount = 0;

      for (final rec in attendances) {
        double otRate = 0;
        double dayRate = 0;

        final site = DBSite.find(rec.siteId);
        if (site != null) {
          final paymentRole = site.sitePaymentRoles
              ?.firstWhere((role) => role.skillId == employee.skillId);
          if (paymentRole != null) {
            otRate = paymentRole.overtimeRate;
            dayRate = paymentRole.dailyWage;
          }
        }

        if (rec.isFullDay == true) {
          totalAttendanceAmount += dayRate;
        }

        if (rec.isHalfDay == true) {
          totalAttendanceAmount += (dayRate * 0.5);
        }
        if (rec.overtimeCount > 0) {
          totalOtAmount += (rec.overtimeCount * otRate);
        }
      }

      employee.walletBalance += (totalAttendanceAmount + totalOtAmount);
      await employee.save();

      // Create wallet transaction
      final transaction = EmployeeWalletTransaction(
        id: "LOCAL-${DateTime.now().millisecondsSinceEpoch}",
        employeeId: employee.id!,
        amount: (totalAttendanceAmount + totalOtAmount),
        transactionAt: DateTime.now(),
        createdAt: DateTime.now(),
        transactionType: 'credit',
        transactionableId: widget.salary.id!,
        transactionableType: 'EmployeeSalaryGenerate',
        remarks: "Salary credited to wallet for ${widget.salary.title}",
      );
      await DBEmployeeWalletTransaction.upsert(transaction);
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Saved!")));

    // Start silent sync in background
    final conn = await Connectivity().checkConnectivity();
    if (conn != ConnectivityResult.none && !widget.salary.isSynced) {
      SyncManager().syncEmployeeSalaryGenerateToServer(widget.salary);
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generate Salary")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildField("Title", titleController),
          _buildDatePicker(
              "From Date", fromDate, () => selectDate(context, true)),
          _buildDatePicker("To Date", toDate, () => selectDate(context, false)),
          _buildField("Remarks", remarksController),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: save, child: const Text("Save")),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime? value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child:
                Text(value != null ? dateFormat.format(value) : "Select Date"),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
