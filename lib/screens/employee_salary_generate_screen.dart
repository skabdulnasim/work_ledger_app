import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:work_ledger/db_models/db_employee.dart';
import 'package:work_ledger/db_models/db_employee_attendance.dart';
import 'package:work_ledger/db_models/db_employee_wallet_transaction.dart';
import 'package:work_ledger/db_models/db_site.dart';
import 'package:work_ledger/db_models/db_skill.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:work_ledger/models/employee_attendance.dart';
import 'package:work_ledger/models/employee_salary_generate.dart';
import 'package:work_ledger/db_models/db_employee_salary_generate.dart';
import 'package:intl/intl.dart';
import 'package:work_ledger/models/employee_wallet_transaction.dart';
import 'package:work_ledger/models/site_payment_role.dart';
import 'package:work_ledger/models/skill.dart';
import 'package:work_ledger/services/helper.dart';
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

  Future<List<Map<String, dynamic>>> buildSalarySummary() async {
    List<Map<String, dynamic>> summaryList = [];
    List<Employee> allEmployees = DBEmployee.getAllEmployees();

    for (var employee in allEmployees) {
      Map<String, dynamic> employeeSummary = {
        'employee': employee,
        'sites': <Map<String, dynamic>>[],
        'skill': null,
      };

      Skill? _skill = DBSkill.find(employee.skillId);
      employeeSummary['skill'] = _skill;

      List<EmployeeAttendance> attendances =
          DBEmployeeAttendance.getEmployeeAttendances(
              employee.id!, fromDate!, toDate!);

      // Group attendances by site
      Map<String, List<EmployeeAttendance>> siteGroups = {};
      for (var att in attendances) {
        siteGroups.putIfAbsent(att.siteId, () => []).add(att);
      }

      for (var siteId in siteGroups.keys) {
        final site = DBSite.find(siteId);
        if (site == null) continue;

        final records = siteGroups[siteId]!;

        int fullDays = records.where((a) => a.isFullDay == true).length;
        int halfDays = records.where((a) => a.isHalfDay == true).length;
        int absentDays = records
            .where((a) => a.isFullDay != true && a.isHalfDay != true)
            .length;
        double totalOTs =
            records.fold(0, (sum, a) => sum + (a.overtimeCount ?? 0));

        SitePaymentRole? paymentRole;
        try {
          paymentRole = site.sitePaymentRoles.firstWhere(
            (role) => role.skillId == employee.skillId,
          );
        } catch (_) {}

        employeeSummary['sites'].add({
          'siteName': site.name,
          'fullDays': fullDays,
          'halfDays': halfDays,
          'absentDays': absentDays,
          'OTs': totalOTs,
          'dayRate': paymentRole?.dailyWage ?? 0,
          'otRate': paymentRole?.overtimeRate ?? 0,
        });
      }

      summaryList.add(employeeSummary);
    }

    return summaryList;
  }

  Future<bool> showConfirmationBottomSheet(
      List<Map<String, dynamic>> summaryList) async {
    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          builder: (context) {
            return DraggableScrollableSheet(
              expand: false,
              maxChildSize: 0.95,
              initialChildSize: 0.95,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      children: [
                        // Fixed Header
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12),
                          child: Text(
                            "Confirm Salary Summary",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),

                        const Divider(height: 1),

                        // Scrollable content
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var emp in summaryList) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 16.0, bottom: 4.0),
                                    child: Text(
                                      "${emp['employee'].name} (${emp['skill'] != null ? emp['skill'].name : ''})",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Divider(),
                                  Table(
                                    border: TableBorder.all(color: Colors.grey),
                                    columnWidths: const {
                                      0: FlexColumnWidth(2),
                                      1: FlexColumnWidth(),
                                      2: FlexColumnWidth(),
                                      3: FlexColumnWidth(),
                                      4: FlexColumnWidth(),
                                      5: FlexColumnWidth(),
                                      6: FlexColumnWidth(),
                                    },
                                    defaultVerticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    children: [
                                      TableRow(
                                        decoration: const BoxDecoration(
                                            color: Color(0xFFE0E0E0)),
                                        children: const [
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text("Site",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text("Full",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text("Half",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text("Absent",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text("OTs",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text("Wage",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text("OT Rate",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      for (var site in emp['sites'])
                                        TableRow(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(site['siteName']),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  site['fullDays'].toString()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  site['halfDays'].toString()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(site['absentDays']
                                                  .toString()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child:
                                                  Text(site['OTs'].toString()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child:
                                                  Text("₹${site['dayRate']}"),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text("₹${site['otRate']}"),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                                const SizedBox(
                                    height:
                                        100), // Add space so content doesn't hide under buttons
                              ],
                            ),
                          ),
                        ),

                        // Fixed Buttons
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.close),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  label: const Text(
                                    "CANCEL",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  label: const Text(
                                    "SAVE",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ) ??
        false;
  }

  Future<void> save() async {
    if (titleController.text.toString().isEmpty) {
      Helper.showMessage(context, "Title can't be blank.", false);
      return;
    }

    if (fromDate == null || toDate == null) {
      Helper.showMessage(context, "From date upto date are required.", false);

      return;
    }

    if (fromDate!.isAfter(toDate!)) {
      Helper.showMessage(
          context, "From Date cannot be later than To Date.", false);

      return;
    }

    final summaryList = await buildSalarySummary();
    final confirmed = await showConfirmationBottomSheet(summaryList);

    if (!confirmed) return;

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
        SitePaymentRole? paymentRole;

        try {
          paymentRole = site!.sitePaymentRoles.firstWhere(
            (role) => role.skillId == employee.skillId,
          );
        } catch (e) {
          paymentRole = null;
        }

        if (paymentRole != null) {
          otRate = paymentRole.overtimeRate;
          dayRate = paymentRole.dailyWage;
        } else {
          print(
              "Some employee skills have attendances but, there salary rate not set in site. \nPlease, cross check it!");
          otRate = 0;
          dayRate = 0;
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
          ElevatedButton.icon(
            icon: const Icon(
              Icons.check,
              color: Colors.white,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            label: const Text(
              "SAVE",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            onPressed: save,
          ),
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
