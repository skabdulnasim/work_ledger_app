import 'package:flutter/material.dart';
import 'package:work_ledger/db_models/db_employee_wallet_transaction.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:work_ledger/services/helper.dart';

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
                      title: Text(
                        "${Helper.getAMPMDateTime(txn.transactionAt.toLocal())}",
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(txn.remarks),
                      trailing: Text(txn.amount.toStringAsFixed(2)),
                    );
                  },
                ),
        ),
      ],
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
              date == null
                  ? '' // Placeholder will be shown above
                  : "${date.toLocal()}".split(' ').first,
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
