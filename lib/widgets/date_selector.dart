import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final void Function(DateTime) onDateSelected;

  const DateSelector({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
  });

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = selectedDate ?? now;
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (newDate != null) {
      onDateSelected(newDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = selectedDate != null
        ? DateFormat('dd-MM-yyyy').format(selectedDate!)
        : 'Select Date';

    return GestureDetector(
      onTap: () => _pickDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: Colors.grey),
          borderRadius: BorderRadius.circular(6),
          color: Color(0xFFF8F8F8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Text(displayDate, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
