import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:work_ledger/db_models/db_employee_attendance.dart';
import 'package:work_ledger/db_models/db_employee_salary_generate.dart';
import 'package:work_ledger/db_models/db_site.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:work_ledger/models/employee_attendance.dart';
import 'package:work_ledger/models/site.dart';
import 'package:work_ledger/services/helper.dart';
import 'package:work_ledger/widgets/attendance_circle.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:work_ledger/widgets/three_switch_state.dart';

class EmployeeAttendanceTab extends StatefulWidget {
  Employee employee;
  EmployeeAttendanceTab({super.key, required this.employee});

  @override
  State<EmployeeAttendanceTab> createState() => _EmployeeAttendanceTabState();
}

class _EmployeeAttendanceTabState extends State<EmployeeAttendanceTab> {
  late int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, EmployeeAttendance?> _attendanceMap = {};

  List<DateTime> visibleDates = [];
  late DateTime calendarEndDate; // Starts from today
  bool isLoadingMoreDates = false;
  bool isRecentlyUpdated = false;

  @override
  void initState() {
    super.initState();

    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;

    _loadAttendanceData();
  }

  void _loadAttendanceData() {
    _attendanceMap = {};
    final daysToLoad = 60;
    for (int i = 0; i < daysToLoad; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      _attendanceMap[Helper.beginningOfDay(date)] =
          DBEmployeeAttendance.findByEmployeeForDate(
        widget.employee.id!,
        date,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: selectedMonth,
                items: List.generate(12, (index) {
                  final month = index + 1;
                  final now = DateTime.now();

                  final bool isDisabled =
                      (selectedYear == now.year && month > now.month);

                  return DropdownMenuItem<int>(
                    value: month,
                    enabled: !isDisabled,
                    child: Text(
                      DateFormat.MMMM().format(DateTime(0, month)),
                      style: TextStyle(
                        color: isDisabled ? Colors.grey : Colors.black,
                      ),
                    ),
                  );
                }),
                onChanged: (month) {
                  if (month != null) {
                    final now = DateTime.now();
                    final isValid =
                        !(selectedYear == now.year && month > now.month);

                    if (isValid) {
                      setState(() {
                        selectedMonth = month;
                        _focusedDay = DateTime(selectedYear, selectedMonth);
                      });
                    }
                  }
                },
              ),
              SizedBox(width: 16),
              DropdownButton<int>(
                value: selectedYear,
                items: List.generate(
                  DateTime.now().year - 2010 + 1,
                  (index) {
                    final year = 2010 + index;
                    return DropdownMenuItem(
                      value: year,
                      child: Text('$year'),
                    );
                  },
                ),
                onChanged: (year) {
                  if (year != null) {
                    setState(() {
                      selectedYear = year;
                      _focusedDay = DateTime(selectedYear, selectedMonth);
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: TableCalendar(
            headerVisible: false,
            firstDay: DateTime(2020),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            onDaySelected: (selectedDay, focusedDay) {
              bool isValidDate =
                  DBEmployeeSalaryGenerate.isValidDate(selectedDay);
              if (isValidDate) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });

                // IF RECENTLY UPDATED THEN MAKE A CHANCE TO SHOW IN CALENDER.
                if (isRecentlyUpdated) {
                  isRecentlyUpdated = false;
                  return;
                }

                final existing = DBEmployeeAttendance.findByEmployeeForDate(
                  widget.employee.id!,
                  selectedDay,
                );

                _showAttendanceForm(
                  context: context,
                  date: selectedDay,
                  emp: widget.employee,
                  existingAttendance: existing,
                );
                isRecentlyUpdated = true;
              } else {
                Helper.showMessage(
                    context,
                    "Salary already generated for date: ${Helper.getTextDate(selectedDay)}.",
                    false);
              }
            },
            calendarStyle: CalendarStyle(
              markerSize: 40,
              selectedDecoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
                // disable default
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                bool isValidDate = DBEmployeeSalaryGenerate.isValidDate(day);
                return Container(
                  margin: EdgeInsets.zero, // no gap
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: isValidDate ? null : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.zero,
                  ),
                  alignment: Alignment.center,
                  child: _buildAttendanceCell(day),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildAttendanceCell(day);
              },
            ),
            onPageChanged: (pageDate) {
              selectedMonth = pageDate.month;
              selectedYear = pageDate.year;
              _focusedDay = pageDate;
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  int getAttendanceState(EmployeeAttendance att) {
    if (att.isFullDay) return 2;
    if (att.isHalfDay) return 1;
    return 0;
  }

  void _showAttendanceForm({
    required BuildContext context,
    required DateTime date,
    required Employee emp,
    EmployeeAttendance? existingAttendance,
  }) {
    List<Site> allSites = DBSite.getAllSites();
    Site? selectedSite = existingAttendance != null
        ? DBSite.find(existingAttendance.siteId)
        : null;
    int selectedAttendanceState =
        existingAttendance != null ? getAttendanceState(existingAttendance) : 0;
    TextEditingController overtimeController = TextEditingController(
        text: existingAttendance?.overtimeCount.toStringAsFixed(0) ?? '0');
    TextEditingController remarksController =
        TextEditingController(text: existingAttendance?.remarks ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center, // Vertical center
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Horizontal center
                children: [
                  Text(
                    DateFormat('dd MMMM, yyyy').format(date),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    DateFormat('EEEE').format(date),
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              ThreeSwitchState(
                labels: ['•', '½', '✓'],
                initialIndex: selectedAttendanceState,
                onStateChanged: (index) {
                  selectedAttendanceState = index;
                },
                axis: Axis.horizontal,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<Site>(
                value: selectedSite,
                items: allSites.map((site) {
                  return DropdownMenuItem<Site>(
                    value: site,
                    child: Text(site.name),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedSite = value;
                },
                decoration: InputDecoration(
                  labelText: 'Select Site',
                  border:
                      OutlineInputBorder(), // ⬅️ This gives the outlined box
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: overtimeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Overtime (hours)',
                  border:
                      OutlineInputBorder(), // ⬅️ This gives the outlined box
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: remarksController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Remarks (Optional)',
                  border:
                      OutlineInputBorder(), // ⬅️ This gives the outlined box
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.check),
                    label: Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.blue, // Set background color to blue
                      foregroundColor:
                          Colors.white, // Optional: sets icon/text color
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(150, 48),
                    ),
                    onPressed: () async {
                      if (selectedSite == null) {
                        Helper.showMessage(
                            context, "Please select a site.", false);
                        return;
                      }
                      EmployeeAttendance att;
                      final isAbsence = selectedAttendanceState == 0;
                      final isHalfDay = selectedAttendanceState == 1;
                      final isFullDay = selectedAttendanceState == 2;

                      final double? overtime =
                          double.tryParse(overtimeController.text);
                      final String remarks = remarksController.text;

                      if (existingAttendance != null) {
                        att = existingAttendance
                          ..siteId = selectedSite!.id!
                          ..isAbsence = isAbsence
                          ..isFullDay = isFullDay
                          ..isHalfDay = isHalfDay
                          ..overtimeCount = overtime ?? 0
                          ..remarks = remarks
                          ..isSynced = false;
                      } else {
                        att = EmployeeAttendance(
                          id: "LOCAL-${DateTime.now().millisecondsSinceEpoch}",
                          employeeId: emp.id!,
                          siteId: selectedSite!.id!,
                          date: date,
                          isAbsence: isAbsence,
                          isFullDay: isFullDay,
                          isHalfDay: isHalfDay,
                          overtimeCount: overtime ?? 0,
                          remarks: remarks,
                          isSynced: false,
                        );
                      }

                      DBEmployeeAttendance.upsert(att);

                      // ✅ Update attendanceMap manually
                      setState(() {
                        _attendanceMap[Helper.beginningOfDay(date)] = att;
                      });

                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.close),
                    label: Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.redAccent, // Set background color to blue
                      foregroundColor:
                          Colors.white, // Optional: sets icon/text color
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(150, 48),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCell(DateTime day) {
    final attendance = _attendanceMap[Helper.beginningOfDay(day)];

    final painter = attendance == null
        ? AttendanceCircle(attendanceType: "absence")
        : attendance.isFullDay
            ? AttendanceCircle(attendanceType: "full")
            : attendance.isHalfDay
                ? AttendanceCircle(attendanceType: "half")
                : AttendanceCircle(attendanceType: "absence");

    return CustomPaint(
      painter: painter,
      child: Container(
        width: 45,
        height: 45,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (attendance?.overtimeCount != null &&
                attendance!.overtimeCount > 0)
              Text(
                "+${attendance.overtimeCount.toStringAsFixed(0)}h",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
                overflow: TextOverflow.visible,
              ),
          ],
        ),
      ),
    );
  }

  Widget _dateSelector(
      String label, DateTime? date, Function(DateTime) onSelect) {
    return GestureDetector(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selected != null) onSelect(selected);
      },
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: Colors.grey),
              borderRadius: BorderRadius.circular(6),
              color: const Color(0xFFF8F8F8),
            ),
            width: double.infinity,
            child: Text(
              date == null ? '' : "${date.toLocal()}".split(' ').first,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
          Positioned(
            left: 8,
            top: date == null ? 18 : 0,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: date == null ? 14 : 12,
                color: date == null ? Colors.grey : Colors.black,
              ),
              child: Container(
                color: const Color(0xFFF8F8F8),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(label),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
