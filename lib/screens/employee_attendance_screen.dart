import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:work_ledger/models/employee_attendance.dart';
import 'package:work_ledger/db_models/db_employee.dart';
import 'package:work_ledger/db_models/db_employee_attendance.dart';
import 'package:work_ledger/widgets/three_state_switch.dart';

class EmployeeAttendanceScreen extends StatefulWidget {
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

  int employeeBatchSize = 10;
  int loadedEmployeeCount = 0;
  bool isLoadingMoreEmployees = false;
  bool isLoadingMoreDates = false;
  DateTime calendarStartDate = DateTime.now().subtract(Duration(days: 3));

  @override
  void initState() {
    super.initState();

    // Initially load 20 employees
    loadMoreEmployees();

    // Initially load 14 dates starting from calendarStartDate
    dates = List.generate(
        5, (index) => calendarStartDate.add(Duration(days: index)));

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

    final newStartDate = calendarStartDate.subtract(Duration(days: 7));
    final newDates = List.generate(
      7,
      (index) => newStartDate.add(Duration(days: index)),
    );

    setState(() {
      calendarStartDate = newStartDate;
      dates = [...newDates, ...dates]; // prepend
      isLoadingMoreDates = false;

      // Maintain current visual position after prepending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        horizontalController.jumpTo(horizontalController.offset + 7 * 160);
      });
    });
  }

  // @override
  // void initState() {
  //   super.initState();

  //   employees = DBEmployee.getAllEmployees();
  //   DateTime start = DateTime.now().subtract(Duration(days: 3));
  //   dates = List.generate(14, (index) => start.add(Duration(days: index)));

  //   // Sync: content -> fixed header
  //   horizontalController.addListener(() {
  //     if (fixedHeaderHorizontalController.offset !=
  //         horizontalController.offset) {
  //       fixedHeaderHorizontalController.jumpTo(horizontalController.offset);
  //     }
  //   });

  //   // Sync: fixed header -> content
  //   fixedHeaderHorizontalController.addListener(() {
  //     if (horizontalController.offset !=
  //         fixedHeaderHorizontalController.offset) {
  //       horizontalController.jumpTo(fixedHeaderHorizontalController.offset);
  //     }
  //   });

  //   // Sync: content -> fixed column
  //   verticalController.addListener(() {
  //     if (fixedColumnVerticalController.offset != verticalController.offset) {
  //       fixedColumnVerticalController.jumpTo(verticalController.offset);
  //     }
  //   });

  //   // Sync: fixed column -> content
  //   fixedColumnVerticalController.addListener(() {
  //     if (verticalController.offset != fixedColumnVerticalController.offset) {
  //       verticalController.jumpTo(fixedColumnVerticalController.offset);
  //     }
  //   });

  //   // Scroll to today
  //   WidgetsBinding.instance.addPostFrameCallback((_) => scrollToToday());
  // }

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

  void setAttendanceState(EmployeeAttendance att, int index) {
    att.isAbsence = index == 0;
    att.isHalfDay = index == 1;
    att.isFullDay = index == 2;
    att.isSynced = false;
    DBEmployeeAttendance.upsert(att);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Employee Attendance")),
      body: Column(
        children: [
          // Top header row
          Row(
            children: [
              buildCell(Text("Employee"), color: Colors.grey.shade300),
              Expanded(
                child: SingleChildScrollView(
                  controller: fixedHeaderHorizontalController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: dates.map((date) {
                      bool isToday = DateUtils.isSameDay(date, DateTime.now());
                      return buildCell(
                        Column(
                          children: [
                            Text(DateFormat('dd MMM').format(date),
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(DateFormat('EEE').format(date)),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(emp.name, style: TextStyle(fontSize: 14)),
                            Text(emp.mobileNo,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
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
                              final att =
                                  DBEmployeeAttendance.findByEmployeeForDate(
                                          emp.id!, date) ??
                                      EmployeeAttendance(
                                        employeeId: emp.id!,
                                        siteId: "1",
                                        date: date,
                                        isAbsence: true,
                                      );
                              final controller = TextEditingController(
                                text: att.overtimeCount > 0
                                    ? att.overtimeCount.toString()
                                    : '',
                              );

                              bool isToday =
                                  DateUtils.isSameDay(date, DateTime.now());

                              return buildCell(
                                Column(
                                  children: [
                                    ThreeStateSwitch(
                                      labels: ['•', '½', '✓'],
                                      selectedIndex: getAttendanceState(att),
                                      onStateChanged: (i) {
                                        setAttendanceState(att, i);
                                        setState(() {});
                                      },
                                      axis: Axis.horizontal,
                                    ),
                                    SizedBox(height: 10),
                                    TextField(
                                      controller: controller,
                                      maxLength: 3,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 22),
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                              decimal: true),
                                      onChanged: (val) {
                                        att.overtimeCount =
                                            double.tryParse(val) ?? 0;
                                        att.isSynced = false;
                                        DBEmployeeAttendance.upsert(att);
                                      },
                                      decoration: InputDecoration(
                                        hintText: "00",
                                        counterText: '',
                                        contentPadding:
                                            EdgeInsets.symmetric(horizontal: 6),
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.alarm),
                                        suffixIcon: Container(
                                          padding:
                                              EdgeInsets.symmetric(vertical: 8),
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
                                    : Colors.white,
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
    );
  }
}
