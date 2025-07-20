import 'package:flutter/material.dart';
import 'package:work_ledger/db_models/db_employee_salary_generate.dart';
import 'package:work_ledger/models/employee_salary_generate.dart';
import 'package:work_ledger/screens/employee_salary_generate_screen.dart';
import 'package:work_ledger/services/helper.dart';

class EmployeeSalaryGenerateListScreen extends StatefulWidget {
  const EmployeeSalaryGenerateListScreen({super.key});

  @override
  State<EmployeeSalaryGenerateListScreen> createState() =>
      _EmployeeSalaryGenerateListScreenState();
}

class _EmployeeSalaryGenerateListScreenState
    extends State<EmployeeSalaryGenerateListScreen> {
  List<EmployeeSalaryGenerate> salaryList = [];

  @override
  void initState() {
    super.initState();
    salaryList = DBEmployeeSalaryGenerate.getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Salary Records")),
      body: salaryList.isEmpty
          ? const Center(child: Text("No salary records found"))
          : ListView.builder(
              itemCount: salaryList.length,
              itemBuilder: (_, index) {
                final record = salaryList[index];
                return ListTile(
                  title: Text(record.title),
                  subtitle: Text(
                      "${Helper.getJustDate(record.fromDate.toLocal())} - ${Helper.getJustDate(record.toDate.toLocal())}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EmployeeSalaryGenerateScreen(salary: record),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newRecord = EmployeeSalaryGenerate(
            id: "LOCAL-${DateTime.now().millisecondsSinceEpoch}",
            title: '',
            fromDate: DateTime.now(),
            toDate: DateTime.now(),
          );

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmployeeSalaryGenerateScreen(salary: newRecord),
            ),
          );

          if (result == true) {
            setState(() {
              salaryList = DBEmployeeSalaryGenerate.getAll();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
