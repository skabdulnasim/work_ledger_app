import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_company_bill_payment.dart';
import 'package:work_ledger/models/company_bill_payment.dart';
import 'package:work_ledger/models/site.dart';
import 'package:work_ledger/screens/employee_attendance_screen.dart';
import 'package:work_ledger/services/helper.dart';
import 'package:work_ledger/services/secure_api_service.dart';
import 'package:work_ledger/widgets/top_bar.dart';

class BillPaymentListScreen extends StatefulWidget {
  final Site site;
  const BillPaymentListScreen({super.key, required this.site});

  @override
  State<BillPaymentListScreen> createState() => _BillPaymentListScreenState();
}

class _BillPaymentListScreenState extends State<BillPaymentListScreen> {
  final Set<String> _selectedMessageIds = {};
  bool get isSelectionMode => _selectedMessageIds.isNotEmpty;

  final TextEditingController _amountController = TextEditingController();
  DateTime selectedTransactionAt = DateTime.now();
  String selectedTransactionMode = "CASH";
  final TextEditingController _billNoController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final List<String> _attachments = [];

  final ScrollController _scrollController = ScrollController();

  void _sendPayment() async {
    final newPayment = CompanyBillPayment(
      id: "LOCAL-${DateTime.now().microsecondsSinceEpoch}",
      transactionAt: selectedTransactionAt,
      billNo: _billNoController.text,
      amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
      paymentMode: selectedTransactionMode,
      transactionType: "SENT",
      remarks: _remarksController.text,
      siteId: widget.site.id!,
      attachmentPaths: [..._attachments],
    );

    if (newPayment.validate().isEmpty) {
      await DBCompanyBillPayment.upsertCompanyBillPayment(newPayment);
      _amountController.clear();
      _billNoController.clear();
      _remarksController.clear();
      selectedTransactionAt = DateTime.now();
      selectedTransactionMode = "CASH";
      _attachments.clear();
      setState(() {});
      await Future.delayed(Duration(milliseconds: 200));
      _scrollToBottom();

      final conn = await Connectivity().checkConnectivity();
      if (conn != ConnectivityResult.none && !newPayment.isSynced) {
        final response =
            await SecureApiService.createCompanyBillPayment(newPayment);

        if (response != null && response['id'] != null) {
          print(response.toString());
          newPayment
            ..serverId = response['id'].toString()
            ..isSynced = true;

          await newPayment.save();
        }
      }
    } else {
      List<String> validationErrors = newPayment.validate();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationErrors.join('\n')),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _receivePayment() async {
    final newPayment = CompanyBillPayment(
      id: "LOCAL-${DateTime.now().microsecondsSinceEpoch}",
      transactionAt: selectedTransactionAt,
      billNo: _billNoController.text,
      amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
      paymentMode: selectedTransactionMode,
      transactionType: "RECEIVED",
      remarks: _remarksController.text,
      siteId: widget.site.id!,
      attachmentPaths: [..._attachments],
    );
    if (newPayment.validate().isEmpty) {
      await DBCompanyBillPayment.upsertCompanyBillPayment(newPayment);
      _amountController.clear();
      _billNoController.clear();
      _remarksController.clear();
      selectedTransactionAt = DateTime.now();
      selectedTransactionMode = "CASH";
      _attachments.clear();
      setState(() {});
      await Future.delayed(Duration(milliseconds: 200));
      _scrollToBottom();
      final conn = await Connectivity().checkConnectivity();
      if (conn != ConnectivityResult.none && !newPayment.isSynced) {
        final response =
            await SecureApiService.createCompanyBillPayment(newPayment);

        if (response != null && response['id'] != null) {
          print(response.toString());
          newPayment
            ..serverId = response['id'].toString()
            ..isSynced = true;

          await newPayment.save();
        }
      }
    } else {
      List<String> validationErrors = newPayment.validate();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationErrors.join('\n')),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final other = DateTime(date.year, date.month, date.day);

    if (today.difference(other).inDays == 0) return "Today";
    if (today.difference(other).inDays == 1) return "Yesterday";
    return DateFormat('d MMMM, yyyy').format(date);
  }

  Map<String, List<CompanyBillPayment>> groupByDate(
      List<CompanyBillPayment> list) {
    final Map<String, List<CompanyBillPayment>> grouped = {};
    for (final item in list) {
      final key = formatDateHeader(item.transactionAt);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }

  Future<void> pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.single.path!);

      // If image => crop
      if (['jpg', 'jpeg', 'png']
          .any((ext) => file.path.toLowerCase().endsWith(ext))) {
        final cropped = await ImageCropper().cropImage(
          sourcePath: file.path,
          aspectRatio: null,
          compressQuality: 90,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              lockAspectRatio: false,
            ),
            IOSUiSettings(title: 'Crop Image'),
          ],
        );

        if (cropped != null) {
          _attachments.add(cropped.path);
        }
      } else {
        _attachments.add(file.path);
      }

      setState(() {});
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final now = DateTime.now();

    // Step 1: Pick Date
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (date == null) return;

    // Step 2: Pick Time
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );

    if (time == null) return;

    final DateTime selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Step 3: Validate DateTime is not in the future
    if (selected.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected time cannot be in the future')),
      );
      return;
    }

    setState(() {
      selectedTransactionAt = selected;
    });
  }

  void _deleteSelectedMessages() async {
    final box = Hive.box<CompanyBillPayment>(BOX_COMPANY_BILL_PAYMENT);

    for (final id in _selectedMessageIds) {
      final payment = box.get(id);
      if (payment != null) {
        for (final path in payment.attachmentPaths) {
          final file = File(path);
          if (await file.exists()) await file.delete();
        }
        await box.delete(id);
      }
    }

    setState(() => _selectedMessageIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        pageTitle: isSelectionMode
            ? "${_selectedMessageIds.length} selected"
            : widget.site.name,
        fixedAction: isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelectedMessages,
                ),
              ]
            : [],
        menuActions: [
          {'label': 'Employee Attendance', 'value': 'employee_attendance'},
          {'label': 'Site Details', 'value': 'site'},
        ],
        onSelected: (value) async {
          switch (value) {
            case 'employee_attendance':
              Navigator.pushNamed(
                context,
                '/attendance',
                arguments: widget.site, // Pass the site object here
              );
              break;
            case 'site':
              Navigator.pushNamed(
                context,
                '/site',
                arguments: widget.site, // Pass the site object here
              );
              break;
          }
        },
      ),
      body: GestureDetector(
        onTap: () {
          if (isSelectionMode) {
            setState(() => _selectedMessageIds.clear());
          }
        },
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder<Box<CompanyBillPayment>>(
                valueListenable: DBCompanyBillPayment.getListenable(),
                builder: (context, box, _) {
                  final messages = box.values
                      .where((e) => e.siteId == widget.site.id)
                      .toList()
                    ..sort(
                        (a, b) => a.transactionAt.compareTo(b.transactionAt));

                  final grouped = groupByDate(messages);

                  final allItems = <Widget>[];

                  for (final entry in grouped.entries) {
                    allItems.add(Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ));

                    for (final payment in entry.value) {
                      allItems.add(
                        GestureDetector(
                          onLongPress: () {
                            setState(() => _selectedMessageIds.add(payment.id));
                          },
                          onTap: () {
                            if (isSelectionMode) {
                              setState(() {
                                if (_selectedMessageIds.contains(payment.id)) {
                                  _selectedMessageIds.remove(payment.id);
                                } else {
                                  _selectedMessageIds.add(payment.id);
                                }
                              });
                            }
                          },
                          child: Container(
                            color: _selectedMessageIds.contains(payment.id)
                                ? Colors.blueGrey.withOpacity(0.3)
                                : Colors.transparent,
                            child: _buildMessageBubble(payment),
                          ),
                        ),
                      );
                    }
                  }

                  // Scroll to end after building
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());

                  return ListView(
                    controller: _scrollController,
                    children: allItems,
                  );
                },
              ),
            ),

            // Input form fixed at bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 235, 235, 235),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Invoice No. and Date Picker
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _billNoController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: "INVOICE NO.",
                            fillColor: Color(0xFFF8F8F8),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.attach_file),
                              onPressed: pickAttachment,
                              tooltip: "Attach file",
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(width: 1, color: Colors.grey),
                            borderRadius: BorderRadius.circular(6),
                            color: Color(0xFFF8F8F8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  Helper.getAMPMDateTime(selectedTransactionAt),
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _selectDateTime(context),
                                icon: Icon(Icons.calendar_month_outlined),
                                tooltip: 'Select Date & Time',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Transaction Mode and Remarks
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(width: 1, color: Colors.grey),
                            borderRadius: BorderRadius.circular(6),
                            color: Color(0xFFF8F8F8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedTransactionMode,
                            underline: SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                  value: "CASH", child: Text("CASH")),
                              DropdownMenuItem(
                                  value: "ONLINE", child: Text("ONLINE")),
                              DropdownMenuItem(
                                  value: "CARD", child: Text("CARD")),
                              DropdownMenuItem(
                                  value: "BANK", child: Text("BANK")),
                              DropdownMenuItem(
                                  value: "CHEQUE", child: Text("CHEQUE")),
                            ],
                            onChanged: (v) =>
                                setState(() => selectedTransactionMode = v!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _remarksController,
                          decoration: InputDecoration(
                            hintText: "Remarks...",
                            fillColor: Color(0xFFF8F8F8),
                            filled: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Amount Input
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter amount...",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Color(0xFFF8F8F8),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Text(
                          "₹",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      prefixIconConstraints:
                          BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // SEND and RECEIVE buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            onPressed: _sendPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[100],
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: Text("SEND"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            onPressed: _receivePayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[100],
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: Text("RECEIVE"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_attachments.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final path = _attachments[index];
                    return Stack(
                      children: [
                        if (path.toLowerCase().endsWith('.pdf'))
                          Container(
                            width: 80,
                            height: 100,
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.picture_as_pdf, color: Colors.red),
                                Text('PDF', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          )
                        else
                          Image.file(
                            File(path),
                            width: 80,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _attachments.removeAt(index));
                            },
                            child: Container(
                              color: Colors.black45,
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(CompanyBillPayment payment) {
    final isSelf = payment.transactionType == "RECEIVED";

    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isSelf ? 40 : 8,
          right: isSelf ? 8 : 40,
        ),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelf ? Colors.blue[100] : Colors.green[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount
            Text(
              "₹${payment.amount.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            // Remarks
            if (payment.remarks.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  payment.remarks,
                  style: const TextStyle(fontSize: 13),
                ),
              ),

            // Attachments
            if (payment.attachmentPaths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: payment.attachmentPaths.map((path) {
                    if (path.toLowerCase().endsWith('.pdf')) {
                      return GestureDetector(
                        onTap: () {
                          // Open PDF viewer or external
                        },
                        child: Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.picture_as_pdf,
                                  size: 32, color: Colors.red),
                              SizedBox(height: 4),
                              Text("PDF", style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return GestureDetector(
                        onTap: () {
                          // Show full image viewer
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }
                  }).toList(),
                ),
              ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                DateFormat('hh:mm a').format(payment.transactionAt),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
