import 'package:flutter/material.dart';
import 'package:work_ledger/db_models/db_employee_wallet_transaction.dart';
import 'package:work_ledger/models/employee.dart';

class EmployeeWalletTab extends StatefulWidget {
  final Employee employee;

  const EmployeeWalletTab({Key? key, required this.employee}) : super(key: key);

  @override
  State<EmployeeWalletTab> createState() => _EmployeeWalletTabState();
}

class _EmployeeWalletTabState extends State<EmployeeWalletTab> {
  DateTime? _walletFromDate;
  DateTime? _walletToDate;

  @override
  Widget build(BuildContext context) {
    final txns = DBEmployeeWalletTransaction.getAll(
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
              ? const Center(child: Text("No transactions found"))
              : ListView.builder(
                  itemCount: txns.length,
                  itemBuilder: (context, index) {
                    final txn = txns[index];
                    return ListTile(
                      title: Text(txn.amount.toStringAsFixed(2)),
                      subtitle: Text(txn.remarks),
                      trailing: Text(
                        txn.transactionAt.toLocal().toString().split(' ').first,
                        style: const TextStyle(fontSize: 12),
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
