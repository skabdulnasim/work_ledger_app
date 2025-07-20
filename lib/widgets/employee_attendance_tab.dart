import 'package:flutter/material.dart';
import 'package:work_ledger/db_models/db_employee_attendance.dart';
import 'package:work_ledger/db_models/db_employee_wallet_transaction.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:work_ledger/services/helper.dart';
import 'package:work_ledger/widgets/attendance_circle.dart';

class EmployeeAttendanceTab extends StatefulWidget {
  final Employee employee;

  const EmployeeAttendanceTab({Key? key, required this.employee})
      : super(key: key);

  @override
  State<EmployeeAttendanceTab> createState() => _EmployeeAttendanceTabState();
}

class _EmployeeAttendanceTabState extends State<EmployeeAttendanceTab> {
  DateTime? _walletFromDate;
  DateTime? _walletToDate;

  @override
  Widget build(BuildContext context) {
    final txns = DBEmployeeAttendance.getAll(
      employeeId: widget.employee.id,
      fromDate: _walletFromDate,
      toDate: _walletToDate,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _dateSelector("From", _walletFromDate, (date) {
                setState(() => _walletFromDate = date);
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _dateSelector("To", _walletToDate, (date) {
                setState(() => _walletToDate = date);
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: txns.isEmpty
              ? const Center(child: Text("No attendance found"))
              : ListView.builder(
                  itemCount: txns.length,
                  itemBuilder: (context, index) {
                    final txn = txns[index];
                    return ListTile(
                      title: Text(
                        Helper.getJustDate(txn.date.toLocal()),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: CustomPaint(
                        size: const Size(20, 20),
                        painter: txn.isFullDay
                            ? AttendanceCircle(attendanceType: "full")
                            : txn.isHalfDay
                                ? AttendanceCircle(attendanceType: "half")
                                : AttendanceCircle(attendanceType: "absence"),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _dateSelector(
      String label, DateTime? date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selected != null) onSelect(selected);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          date == null ? 'Select' : "${date.toLocal()}".split(' ').first,
        ),
      ),
    );
  }
}
