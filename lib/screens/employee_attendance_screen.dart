import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:work_ledger/db_models/db_employee_salary_generate.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:work_ledger/models/employee_attendance.dart';
import 'package:work_ledger/db_models/db_employee.dart';
import 'package:work_ledger/db_models/db_employee_attendance.dart';
import 'package:work_ledger/models/site.dart';
import 'package:work_ledger/services/helper.dart';
import 'package:work_ledger/widgets/three_state_switch.dart';

class EmployeeAttendanceScreen extends StatefulWidget {
  final Site site;
  const EmployeeAttendanceScreen({super.key, required this.site});
  @override
  _EmployeeAttendanceScreenState createState() =>
      _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> {
  List<Employee> employees = [];
  List<DateTime> dates = [];

  final ScrollController verticalController = ScrollController();
  final ScrollController horizontalController = ScrollController();

  final ScrollController fixedColumnVerticalController = ScrollController();
  final ScrollController fixedHeaderHorizontalController = ScrollController();

  TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  int employeeBatchSize = 10;
  int loadedEmployeeCount = 0;
  bool isLoadingMoreEmployees = false;
  bool isLoadingMoreDates = false;
  DateTime calendarStartDate = DateTime.now().subtract(Duration(days: 4));
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    // Initially load 20 employees
    loadMoreEmployees();

    // Initially load 14 dates starting from calendarStartDate
    dates = List.generate(
      5,
      (index) => calendarStartDate.add(
        Duration(days: index),
      ),
    );

    // Scroll sync listeners (your current implementation is perfect)
    // Add this listener to detect bottom vertical scroll:
    verticalController.addListener(() {
      if (verticalController.position.pixels >=
          verticalController.position.maxScrollExtent - 100) {
        loadMoreEmployees();
      }

      if (fixedColumnVerticalController.offset != verticalController.offset) {
        fixedColumnVerticalController.jumpTo(verticalController.offset);
      }
    });

    fixedColumnVerticalController.addListener(() {
      if (verticalController.offset != fixedColumnVerticalController.offset) {
        verticalController.jumpTo(fixedColumnVerticalController.offset);
      }
    });

    // Detect left scroll for loading earlier dates
    horizontalController.addListener(() {
      if (horizontalController.offset <= 20 && !isLoadingMoreDates) {
        loadMorePastDates();
      }

      if (fixedHeaderHorizontalController.offset !=
          horizontalController.offset) {
        fixedHeaderHorizontalController.jumpTo(horizontalController.offset);
      }
    });

    fixedHeaderHorizontalController.addListener(() {
      if (horizontalController.offset !=
          fixedHeaderHorizontalController.offset) {
        horizontalController.jumpTo(fixedHeaderHorizontalController.offset);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToToday());
  }

  void loadMoreEmployees() {
    if (isLoadingMoreEmployees) return;

    isLoadingMoreEmployees = true;

    final nextBatch = DBEmployee.getEmployees(
      offset: loadedEmployeeCount,
      limit: employeeBatchSize,
      qry: _searchText,
    );

    if (nextBatch.isNotEmpty) {
      setState(() {
        employees.addAll(nextBatch);
        loadedEmployeeCount += nextBatch.length;
      });
    }

    isLoadingMoreEmployees = false;
  }

  void loadMorePastDates() {
    if (isLoadingMoreDates) return;

    isLoadingMoreDates = true;

    final newStartDate = calendarStartDate.subtract(Duration(days: 5));
    final newDates = List.generate(
      5,
      (index) => newStartDate.add(Duration(days: index)),
    );

    setState(() {
      calendarStartDate = newStartDate;
      dates = [...newDates, ...dates]; // prepend
      isLoadingMoreDates = false;

      // Maintain current visual position after prepending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        horizontalController.jumpTo(horizontalController.offset + 5 * 160);
      });
    });
  }

  void scrollToToday() {
    final index =
        dates.indexWhere((d) => DateUtils.isSameDay(d, DateTime.now()));
    if (index >= 0) {
      horizontalController.jumpTo(index * 160.0); // width of cell
    }
  }

  int getAttendanceState(EmployeeAttendance att) {
    if (att.isFullDay) return 2;
    if (att.isHalfDay) return 1;
    return 0;
  }

  Widget buildCell(Widget child, {Color? color}) {
    return Container(
      width: 160,
      height: 120,
      alignment: Alignment.center,
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    verticalController.dispose();
    horizontalController.dispose();
    fixedColumnVerticalController.dispose();
    fixedHeaderHorizontalController.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Employee Attendance")),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();

                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    setState(() {
                      employees = [];
                      loadedEmployeeCount = 0;
                      _searchText = value.trim().toLowerCase();
                      loadMoreEmployees();
                    });
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search by name or mobile...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            // Top header row
            Row(
              children: [
                buildCell(
                    Text(
                      "EMPLOYEE",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    color: Colors.grey.shade300),
                Expanded(
                  child: SingleChildScrollView(
                    controller: fixedHeaderHorizontalController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: dates.map((date) {
                        bool isToday =
                            DateUtils.isSameDay(date, DateTime.now());
                        return buildCell(
                          Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center, // Vertical center
                            crossAxisAlignment:
                                CrossAxisAlignment.center, // Horizontal center
                            children: [
                              Text(
                                DateFormat('dd MMM').format(date),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                DateFormat('EEE').format(date),
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                          color: isToday
                              ? Colors.grey.shade200
                              : Colors.grey.shade300,
                        );
                      }).toList(),
                    ),
                  ),
                )
              ],
            ),

            // Main scrollable grid
            Expanded(
              child: Row(
                children: [
                  // Fixed left column
                  SingleChildScrollView(
                    controller: fixedColumnVerticalController,
                    child: Column(
                      children: employees.map((emp) {
                        return buildCell(
                          Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center, // Vertical center
                            crossAxisAlignment:
                                CrossAxisAlignment.start, // Horizontal center
                            children: [
                              Text(
                                emp.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(emp.mobileNo,
                                  style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          color: Colors.grey.shade100,
                        );
                      }).toList(),
                    ),
                  ),

                  // Scrollable grid
                  Expanded(
                    child: SingleChildScrollView(
                      controller: verticalController,
                      child: SingleChildScrollView(
                        controller: horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          children: employees.map((emp) {
                            return Row(
                              children: dates.map((date) {
                                final EmployeeAttendance? att =
                                    DBEmployeeAttendance
                                        .findByEmployeeForDateOfSite(
                                            emp.id!, widget.site.id!, date);

                                final controller = TextEditingController(
                                  text: att != null
                                      ? (att.overtimeCount > 0
                                          ? att.overtimeCount.toStringAsFixed(0)
                                          : '')
                                      : '',
                                );

                                bool isToday =
                                    DateUtils.isSameDay(date, DateTime.now());
                                bool isValidDate =
                                    DBEmployeeSalaryGenerate.isValidDate(date);
                                return buildCell(
                                  Column(
                                    children: [
                                      ThreeStateSwitch(
                                        labels: ['•', '½', '✓'],
                                        selectedIndex: att != null
                                            ? getAttendanceState(att)
                                            : 0,
                                        onStateChanged: (i) async {
                                          if (isValidDate) {
                                            EmployeeAttendance?
                                                existingAttendance =
                                                DBEmployeeAttendance
                                                    .findByEmployeeForDate(
                                                        emp.id!, date);
                                            try {
                                              if (existingAttendance != null) {
                                                EmployeeAttendance updatedAtt =
                                                    existingAttendance
                                                      ..siteId = widget.site.id!
                                                      ..isAbsence = (i == 0)
                                                      ..isFullDay = (i == 2)
                                                      ..isHalfDay = (i == 1)
                                                      ..isSynced = false;
                                                DBEmployeeAttendance.upsert(
                                                    updatedAtt);
                                              } else {
                                                final newAtt =
                                                    EmployeeAttendance(
                                                  id: "LOCAL-${DateTime.now().millisecondsSinceEpoch.toString()}", // or UUID
                                                  employeeId: emp.id!,
                                                  siteId: widget.site.id!,
                                                  date: date,
                                                  isAbsence: (i == 0),
                                                  isFullDay: (i == 2),
                                                  isHalfDay: (i == 1),
                                                  isSynced: false,
                                                );
                                                DBEmployeeAttendance.upsert(
                                                    newAtt);
                                              }

                                              setState(() {});
                                            } catch (e) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(SnackBar(
                                                  content: Text(e.toString())));
                                            }
                                          } else {
                                            Helper.showMessage(
                                                context,
                                                "Salary already generated!",
                                                false);
                                          }
                                        },
                                        axis: Axis.horizontal,
                                      ),
                                      SizedBox(height: 10),
                                      TextField(
                                        readOnly: !isValidDate,
                                        controller: controller,
                                        maxLength: 3,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 22),
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                                decimal: true),
                                        onChanged: (val) async {
                                          double overtimeCount =
                                              double.tryParse(val) ?? 0;
                                          EmployeeAttendance?
                                              existingAttendance =
                                              DBEmployeeAttendance
                                                  .findByEmployeeForDate(
                                                      emp.id!, date);
                                          try {
                                            if (existingAttendance != null) {
                                              EmployeeAttendance updatedAtt =
                                                  existingAttendance
                                                    ..overtimeCount =
                                                        overtimeCount
                                                    ..isSynced = false;
                                              DBEmployeeAttendance.upsert(
                                                  updatedAtt);
                                            } else {
                                              final newAtt = EmployeeAttendance(
                                                id: "LOCAL-${DateTime.now().millisecondsSinceEpoch.toString()}", // or UUID
                                                employeeId: emp.id!,
                                                siteId: widget.site.id!,
                                                date: date,
                                                overtimeCount: overtimeCount,
                                                isSynced: false,
                                              );
                                              DBEmployeeAttendance.upsert(
                                                  newAtt);
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(SnackBar(
                                                content: Text(e.toString())));
                                          }
                                        },
                                        decoration: InputDecoration(
                                          hintText: "00",
                                          counterText: '',
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 6),
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.alarm),
                                          suffixIcon: Container(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 8),
                                            child: Text(
                                              "hr",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 22,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  color: isToday
                                      ? Colors.grey.shade50
                                      : isValidDate
                                          ? null
                                          : Colors.blue.withOpacity(0.2),
                                );
                              }).toList(),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
