import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_employee.dart';
import 'package:work_ledger/db_models/db_user_prefs.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:work_ledger/screens/login_screen.dart';
import 'package:work_ledger/screens/employee_screen.dart';
import 'package:work_ledger/services/helper.dart';
import 'package:work_ledger/widgets/bottom_nav.dart';
import 'package:work_ledger/widgets/top_bar.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        pageTitle: 'Employee',
        fixedAction: [],
        menuActions: [
          {'label': 'Salary Generate', 'value': 'salary_generate'},
          {'label': 'Logout', 'value': 'logout'},
        ],
        onSelected: (value) async {
          switch (value) {
            case 'salary_generate':
              Navigator.pushNamed(context, '/salaries');
              break;
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
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          Helper.getAvatarFillColor(), // Customize color
                      child: Text(
                        Helper.getAvatarText(
                            employee.name), // Replace with dynamic initials
                        style: TextStyle(
                          color: Helper.getAvatarColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(employee.mobileNo)
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        employee.walletBalance.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: employee.walletBalance > 0
                              ? Colors.green
                              : (employee.walletBalance < 0
                                  ? Colors.red
                                  : Colors.black),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
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
      bottomNavigationBar: SafeArea(
        child: BottomNav(currentIndex: 0),
      ),
    );
  }
}
