import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_employee.dart';
import 'package:work_ledger/db_models/db_user_prefs.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:work_ledger/screens/login_screen.dart';
import 'package:work_ledger/screens/employee_screen.dart';
import 'package:work_ledger/widgets/bottom_nav.dart';
import 'package:work_ledger/widgets/top_bar.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        pageTitle: 'Employee',
        actions: [
          {'label': 'Logout', 'value': 'logout'},
        ],
        onSelected: (value) async {
          switch (value) {
            case 'logout':
              await DBUserPrefs().savePreference(TOKEN, null);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
              break;
          }
        },
      ),
      body: ValueListenableBuilder(
        valueListenable: DBEmployee.getListenable(),
        builder: (context, Box<Employee> box, _) {
          final employees = box.values.toList();

          if (employees.isEmpty) {
            return const Center(child: Text("No employees found"));
          }

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              return ListTile(
                title: Text(employee.name),
                subtitle: Text(employee.mobileNo),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmployeeScreen(employee: employee),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newEmployee = Employee(
            id: "LOCAL-${DateTime.now().millisecondsSinceEpoch}",
            name: '',
            address: '',
            mobileNo: '', // Required, set in form
            skillId: '',
          );
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmployeeScreen(employee: newEmployee),
            ),
          );

          if (result == true) {
            (context as Element).reassemble();
          }
        },
        child: const Icon(Icons.add),
        tooltip: "Add Employee",
      ),
      bottomNavigationBar: BottomNav(currentIndex: 0),
    );
  }
}
