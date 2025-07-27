import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_attach_file.dart';
import 'package:work_ledger/db_models/db_company_bill_payment.dart';
import 'package:work_ledger/db_models/db_employee.dart';
import 'package:work_ledger/db_models/db_employee_hold_transaction.dart';
import 'package:work_ledger/db_models/db_employee_wallet_transaction.dart';
import 'package:work_ledger/db_models/db_expense.dart';
import 'package:work_ledger/db_models/db_hold_amount.dart';
import 'package:work_ledger/db_models/db_site.dart';
import 'package:work_ledger/models/attach_file.dart';
import 'package:work_ledger/models/company_bill_payment.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:work_ledger/models/employee_hold_transaction.dart';
import 'package:work_ledger/models/employee_wallet_transaction.dart';
import 'package:work_ledger/models/expense.dart';
import 'package:work_ledger/models/hold_amount.dart';
import 'package:work_ledger/models/site.dart';
import 'package:work_ledger/services/helper.dart';
import 'package:work_ledger/services/secure_api_service.dart';
import 'package:work_ledger/services/sync_manager.dart';
import 'package:work_ledger/services/unsecure_api_service.dart';
import 'package:work_ledger/widgets/select_employee_popup.dart';
import 'package:work_ledger/widgets/top_bar.dart';
import 'package:path/path.dart' as p;
import 'package:open_filex/open_filex.dart';

class ExpenseTransScreen extends StatefulWidget {
  final Employee employee;
  const ExpenseTransScreen({super.key, required this.employee});

  @override
  State<ExpenseTransScreen> createState() => _ExpenseTransScreenState();
}

class _ExpenseTransScreenState extends State<ExpenseTransScreen> {
  final Set<String> _selectedTranIds = {};
  bool isExpenseForm = true;
  bool get isSelectionMode => _selectedTranIds.isNotEmpty;

  late TextEditingController _amountController;
  late TextEditingController _remarksController;
  DateTime selectedTransactionAt = DateTime.now();
  Site? selectedSite;
  Employee? selectedExpenseTo;
  final List<String> _attachmentIds = [];

  List<Site> sites = [];
  List<Employee> employees = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _remarksController = TextEditingController();
    initSitesAndEmployees();
  }

  void initSitesAndEmployees() {
    sites = DBSite.getAllSites();
    employees = DBEmployee.getAllEmployees();
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

  Map<String, List<EmployeeHoldTransaction>> groupByDate(
      List<EmployeeHoldTransaction> list) {
    final Map<String, List<EmployeeHoldTransaction>> grouped = {};
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
          String file_name = p.basename(file.path);

          AttachFile f = AttachFile(
              id: "LOCAL-${DateTime.now().microsecondsSinceEpoch}",
              filename: file_name,
              fileType: 'image',
              localPath: cropped.path);
          DBAttachFile.upsert(f);
          _attachmentIds.add(f.id);
        }
      } else {
        String file_name = p.basename(file.path);

        AttachFile f = AttachFile(
            id: "LOCAL-${DateTime.now().microsecondsSinceEpoch}",
            filename: file_name,
            fileType: 'document',
            localPath: file.path);
        DBAttachFile.upsert(f);
        _attachmentIds.add(f.id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        pageTitle: isSelectionMode
            ? "${_selectedTranIds.length} selected"
            : "${widget.employee.name}",
        fixedAction: [],
        menuActions: [],
        onSelected: (value) async {},
      ),
      body: GestureDetector(
        onTap: () {
          if (isSelectionMode) {
            setState(() => _selectedTranIds.clear());
          }
        },
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder<Box<EmployeeHoldTransaction>>(
                valueListenable: DBEmployeeHoldTransaction.getListenable(),
                builder: (context, box, _) {
                  final messages = box.values
                      .where((e) => e.employeeId == widget.employee.id)
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

                    for (final tran in entry.value) {
                      allItems.add(
                        GestureDetector(
                          onLongPress: () {
                            setState(() => _selectedTranIds.add(tran.id));
                          },
                          onTap: () {
                            if (isSelectionMode) {
                              setState(() {
                                if (_selectedTranIds.contains(tran.id)) {
                                  _selectedTranIds.remove(tran.id);
                                } else {
                                  _selectedTranIds.add(tran.id);
                                }
                              });
                            }
                          },
                          child: Container(
                            color: _selectedTranIds.contains(tran.id)
                                ? Colors.blueGrey.withOpacity(0.3)
                                : Colors.transparent,
                            child: _buildTranBubble(tran),
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
            SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "ADD MONEY",
                              style: TextStyle(
                                color:
                                    isExpenseForm ? Colors.grey : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Switch(
                              value: isExpenseForm,
                              onChanged: (val) {
                                setState(() {
                                  isExpenseForm = val;
                                });
                              },
                              activeColor: Colors
                                  .blue, // Thumb color when ON (expense selected)
                              activeTrackColor:
                                  Colors.blue[100], // Track color when ON
                              inactiveThumbColor: Colors
                                  .green, // Thumb color when OFF (add money)
                              inactiveTrackColor:
                                  Colors.green[100], // Track color when OFF
                            ),
                            Text(
                              "EXPENSE",
                              style: TextStyle(
                                color:
                                    isExpenseForm ? Colors.blue : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        isExpenseForm
                            ? buildExpenseForm()
                            : buildHoldAmountForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEmployeePopup() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Optional: makes the sheet full height if needed
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            height: 600,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 10,
              left: 10,
              right: 10,
            ),
            child: SelectEmployeePopup(), // Your custom widget
          ),
        );
      },
    );

    if (result is String) {
      selectedExpenseTo = null;
    }

    if (result is Employee) {
      selectedExpenseTo = result;
      print("Expense to employee selected!");
    }

    setState(() {});
  }

  Widget buildExpenseForm() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFF8F8F8),
          ),
          child: GestureDetector(
            onTap: _handleEmployeePopup,
            child: Container(
              height: 55,
              padding:
                  const EdgeInsets.only(left: 5, right: 5, top: 0, bottom: 0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedExpenseTo?.name ?? 'Paid to employee.',
                        ),
                        Text(
                          selectedExpenseTo?.mobileNo ?? 'Mobile number.',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selectedExpenseTo != null)
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        selectedExpenseTo = null;
                        setState(() {});
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red[100],
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: _handleEmployeePopup,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
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
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  prefixIconConstraints:
                      BoxConstraints(minWidth: 0, minHeight: 0),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                child: DropdownButton<Site>(
                  isExpanded: true,
                  value: selectedSite,
                  underline: SizedBox(),
                  items: [
                    const DropdownMenuItem<Site>(
                      value: null,
                      child: Text('-- Select Site --',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    ...sites.map((site) {
                      return DropdownMenuItem<Site>(
                        value: site,
                        child: Text(site.name),
                      );
                    }).toList(),
                  ],
                  onChanged: (Site? value) {
                    setState(() {
                      selectedSite = value;
                    });
                  },
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

        // buttons
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    selectedExpenseTo = null;
                    selectedSite = null;
                    _amountController.clear();
                    _remarksController.clear();
                    selectedTransactionAt = DateTime.now();
                    _attachmentIds.clear();

                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text("CLEAR"),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 45,
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text("EXPENSE"),
                ),
              ),
            ),
          ],
        ),

        if (_attachmentIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _attachmentIds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final attFileId = _attachmentIds[index];
                final path = DBAttachFile.find(attFileId);
                return Stack(
                  children: [
                    if (path!.fileType == "image")
                      if (path.localPath != null)
                        Image.file(
                          File(path.localPath!),
                          width: 80,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      else
                        Row(
                          children: [
                            Image.network(
                              path.previewUrl!,
                              width: 80,
                              height: 100,
                            ),
                            IconButton(
                              icon: Icon(Icons.download),
                              onPressed: () async {
                                final filePath = await UnsecureApiService()
                                    .downloadFile(
                                        path.downloadUrl!, path.filename);
                                setState(() {
                                  path.localPath = filePath;
                                  path.save();
                                });
                              },
                            ),
                          ],
                        ),
                    if (path.fileType == "document")
                      if (path.localPath != null)
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
                        Row(
                          children: [
                            Icon(Icons.file_present),
                            Text(path.filename),
                            IconButton(
                              icon: Icon(Icons.download),
                              onPressed: () async {
                                final filePath = await UnsecureApiService()
                                    .downloadFile(
                                        path.downloadUrl!, path.filename);
                                setState(() {
                                  path.localPath = filePath;
                                  path.save();
                                });
                              },
                            )
                          ],
                        ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _attachmentIds.removeAt(index));
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
    );
  }

  Widget buildHoldAmountForm() {
    return Column(
      children: [
        SizedBox(
          height: 55,
        ),
        SizedBox(
          height: 8,
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
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
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  prefixIconConstraints:
                      BoxConstraints(minWidth: 0, minHeight: 0),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                child: DropdownButton<Site>(
                  isExpanded: true,
                  value: selectedSite,
                  underline: SizedBox(),
                  items: [
                    const DropdownMenuItem<Site>(
                      value: null,
                      child: Text('-- Select Site --',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    ...sites.map((site) {
                      return DropdownMenuItem<Site>(
                        value: site,
                        child: Text(site.name),
                      );
                    }).toList(),
                  ],
                  onChanged: (Site? value) {
                    setState(() {
                      selectedSite = value;
                    });
                  },
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

        // buttons
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    selectedExpenseTo = null;
                    selectedSite = null;
                    _amountController.clear();
                    _remarksController.clear();
                    selectedTransactionAt = DateTime.now();
                    _attachmentIds.clear();

                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text("CLEAR"),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 45,
                child: ElevatedButton(
                  onPressed: _saveHoldAmount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text("ADD MONEY"),
                ),
              ),
            ),
          ],
        ),

        if (_attachmentIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _attachmentIds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final attFileId = _attachmentIds[index];
                final path = DBAttachFile.find(attFileId);
                return Stack(
                  children: [
                    if (path!.fileType == "image")
                      if (path.localPath != null)
                        Image.file(
                          File(path.localPath!),
                          width: 80,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      else
                        Row(
                          children: [
                            Image.network(
                              path.previewUrl!,
                              width: 80,
                              height: 100,
                            ),
                            IconButton(
                              icon: Icon(Icons.download),
                              onPressed: () async {
                                final filePath = await UnsecureApiService()
                                    .downloadFile(
                                        path.downloadUrl!, path.filename);
                                setState(() {
                                  path.localPath = filePath;
                                  path.save();
                                });
                              },
                            ),
                          ],
                        ),
                    if (path.fileType == "document")
                      if (path.localPath != null)
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
                        Row(
                          children: [
                            Icon(Icons.file_present),
                            Text(path.filename),
                            IconButton(
                              icon: Icon(Icons.download),
                              onPressed: () async {
                                final filePath = await UnsecureApiService()
                                    .downloadFile(
                                        path.downloadUrl!, path.filename);
                                setState(() {
                                  path.localPath = filePath;
                                  path.save();
                                });
                              },
                            )
                          ],
                        ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _attachmentIds.removeAt(index));
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
    );
  }

  Widget _buildTranBubble(EmployeeHoldTransaction tran) {
    bool isLeft = true;
    Expense? expense;
    HoldAmount? holdAmount;
    if (tran.transactionableType == "Expense") {
      isLeft = true;
      expense = DBExpense.find(tran.transactionableId);
    } else if (tran.transactionableType == "HoldAmount") {
      isLeft = false;
      holdAmount = DBHoldAmount.find(tran.transactionableId);
    }

    return Align(
      alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isLeft ? 40 : 8,
          right: isLeft ? 8 : 40,
        ),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLeft ? Colors.blue[100] : Colors.green[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount
            Text(
              "₹${tran.amount.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            // Remarks
            if (tran.remarks.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  tran.remarks,
                  style: const TextStyle(fontSize: 13),
                ),
              ),

            if (expense != null)
              // Attachments
              if (expense.attachFileIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: expense.attachFileIds.map((attId) {
                      final att = DBAttachFile.find(attId);
                      if (att != null) {
                        if (att.fileType.startsWith('image')) {
                          if (att.localPath != null) {
                            return GestureDetector(
                              onTap: () async {
                                Helper.showMessage(context,
                                    "IMAGE PREVIEW COMMING SOON...", true);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  File(att.localPath!),
                                  fit: BoxFit.fitWidth,
                                  width: double.infinity,
                                ),
                              ),
                            );
                          } else {
                            return GestureDetector(
                              onTap: () async {
                                final filePath = await UnsecureApiService()
                                    .downloadFile(
                                        att.downloadUrl!, att.filename);
                                setState(() {
                                  att.localPath = filePath;
                                  print(att.toString());
                                  DBAttachFile.upsert(att);
                                });
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  att.previewUrl!,
                                  fit: BoxFit.fitWidth,
                                  width: double.infinity,
                                ),
                              ),
                            );
                          }
                        } else {
                          if (att.localPath != null) {
                            return Row(
                              children: [
                                Icon(Icons.file_present),
                                Expanded(child: Text(att.filename)),
                                IconButton(
                                  icon: Icon(Icons.open_in_new),
                                  onPressed: () async {
                                    Helper.showMessage(context,
                                        "FILE PREVIEW COMMING SOON...", true);
                                    //await OpenFilex.open(att.localPath!);

                                    //   final file = File(
                                    //       '/data/user/0/com.softwebfashion.work_ledger/app_flutter/file-sample_150kb.pdf');
                                    //   OpenFilex.open(file.path);
                                  },
                                ),
                              ],
                            );
                          } else {
                            return Row(
                              children: [
                                Icon(Icons.file_present),
                                Expanded(
                                  child: Text(att.filename),
                                ),
                                IconButton(
                                  icon: Icon(Icons.download),
                                  onPressed: () async {
                                    final filePath = await UnsecureApiService()
                                        .downloadFile(
                                            att.downloadUrl!, att.filename);
                                    setState(() {
                                      att.localPath = filePath;
                                      print(att.toString());
                                      DBAttachFile.upsert(att);
                                    });
                                  },
                                )
                              ],
                            );
                          }
                        }
                      } else {
                        return Row(
                          children: [],
                        );
                      }
                    }).toList(),
                  ),
                ),

            if (holdAmount != null)
              // Attachments
              if (holdAmount.attachFileIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: holdAmount.attachFileIds.map((attId) {
                      final att = DBAttachFile.find(attId);
                      if (att != null) {
                        if (att.fileType.startsWith('image')) {
                          if (att.localPath != null) {
                            return GestureDetector(
                              onTap: () async {
                                Helper.showMessage(context,
                                    "IMAGE PREVIEW COMMING SOON...", true);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  File(att.localPath!),
                                  fit: BoxFit.fitWidth,
                                  width: double.infinity,
                                ),
                              ),
                            );
                          } else {
                            return GestureDetector(
                              onTap: () async {
                                final filePath = await UnsecureApiService()
                                    .downloadFile(
                                        att.downloadUrl!, att.filename);
                                setState(() {
                                  att.localPath = filePath;
                                  print(att.toString());
                                  DBAttachFile.upsert(att);
                                });
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  att.previewUrl!,
                                  fit: BoxFit.fitWidth,
                                  width: double.infinity,
                                ),
                              ),
                            );
                          }
                        } else {
                          if (att.localPath != null) {
                            return Row(
                              children: [
                                Icon(Icons.file_present),
                                Expanded(child: Text(att.filename)),
                                IconButton(
                                  icon: Icon(Icons.open_in_new),
                                  onPressed: () async {
                                    Helper.showMessage(context,
                                        "FILE PREVIEW COMMING SOON...", true);
                                  },
                                ),
                              ],
                            );
                          } else {
                            return Row(
                              children: [
                                Icon(Icons.file_present),
                                Expanded(
                                  child: Text(att.filename),
                                ),
                                IconButton(
                                  icon: Icon(Icons.download),
                                  onPressed: () async {
                                    final filePath = await UnsecureApiService()
                                        .downloadFile(
                                            att.downloadUrl!, att.filename);
                                    setState(() {
                                      att.localPath = filePath;
                                      print(att.toString());
                                      DBAttachFile.upsert(att);
                                    });
                                  },
                                )
                              ],
                            );
                          }
                        }
                      } else {
                        return Row(
                          children: [],
                        );
                      }
                    }).toList(),
                  ),
                ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                DateFormat('hh:mm a').format(tran.transactionAt),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveExpense() async {
    Employee employee = widget.employee;
    final newExpense = Expense(
        id: "LOCAL-${DateTime.now().microsecondsSinceEpoch}",
        expenseAt: selectedTransactionAt,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        expenseById: employee.id!,
        remarks: _remarksController.text,
        siteId: selectedSite != null ? selectedSite!.id! : '',
        attachFileIds: [..._attachmentIds]);
    if (selectedExpenseTo != null) {
      newExpense.expenseToId = selectedExpenseTo!.id!;
    }
    final validations = newExpense.validate();
    if (validations.isEmpty) {
      DBExpense.upsertExpense(newExpense);
      employee.holdAmount -= (double.tryParse(_amountController.text) ?? 0.0);
      await employee.save();

      // Create wallet transaction
      final transaction = EmployeeHoldTransaction(
        id: "LOCAL-${DateTime.now().millisecondsSinceEpoch}",
        employeeId: employee.id!,
        amount: (double.tryParse(_amountController.text) ?? 0.0),
        transactionAt: selectedTransactionAt,
        transactionType: 'debit',
        transactionableId: newExpense.id,
        transactionableType: 'Expense',
        remarks: newExpense.remarks,
        balanceAmount: employee.holdAmount,
      );
      await DBEmployeeHoldTransaction.upsert(transaction);

      if (selectedExpenseTo != null) {
        selectedExpenseTo!.walletBalance -=
            (double.tryParse(_amountController.text) ?? 0.0);
        await selectedExpenseTo!.save();

        // Create wallet transaction
        final transaction = EmployeeWalletTransaction(
          id: "LOCAL-${DateTime.now().millisecondsSinceEpoch}",
          employeeId: selectedExpenseTo!.id!,
          amount: (double.tryParse(_amountController.text) ?? 0.0),
          transactionAt: newExpense.expenseAt,
          transactionType: 'debit',
          transactionableId: newExpense.id,
          transactionableType: 'Expense',
          remarks: "PAID: ${_remarksController.text}.",
          createdAt: DateTime.now(),
        );
        await DBEmployeeWalletTransaction.upsert(transaction);
      }

      selectedExpenseTo = null;
      selectedSite = null;
      _amountController.clear();
      _remarksController.clear();
      selectedTransactionAt = DateTime.now();
      _attachmentIds.clear();

      setState(() {});
      await Future.delayed(Duration(milliseconds: 200));
      _scrollToBottom();
      final conn = await Connectivity().checkConnectivity();
      if (conn != ConnectivityResult.none && !newExpense.isSynced) {
        SyncManager().syncExpenseToServer(newExpense);
      }
    } else {
      Helper.showMessage(context, validations.first, false);
    }
  }

  void _saveHoldAmount() async {
    Employee employee = widget.employee;
    final newHold = HoldAmount(
        id: "LOCAL-${DateTime.now().microsecondsSinceEpoch}",
        addedAt: selectedTransactionAt,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        employeeId: employee.id!,
        remarks: _remarksController.text,
        siteId: selectedSite != null ? selectedSite!.id! : '',
        attachFileIds: [..._attachmentIds]);

    final validations = newHold.validate();
    if (validations.isEmpty) {
      DBHoldAmount.upsertHoldAmount(newHold);
      employee.holdAmount += (double.tryParse(_amountController.text) ?? 0.0);
      await employee.save();

      // Create wallet transaction
      final transaction = EmployeeHoldTransaction(
        id: "LOCAL-${DateTime.now().millisecondsSinceEpoch}",
        employeeId: employee.id!,
        amount: (double.tryParse(_amountController.text) ?? 0.0),
        transactionAt: selectedTransactionAt,
        transactionType: 'credit',
        transactionableId: newHold.id,
        transactionableType: 'HoldAmount',
        remarks: newHold.remarks,
        balanceAmount: employee.holdAmount,
      );
      await DBEmployeeHoldTransaction.upsert(transaction);

      _amountController.clear();
      _remarksController.clear();
      selectedTransactionAt = DateTime.now();
      _attachmentIds.clear();
      selectedSite = null;

      setState(() {});
      await Future.delayed(Duration(milliseconds: 200));
      _scrollToBottom();
      final conn = await Connectivity().checkConnectivity();
      if (conn != ConnectivityResult.none && !newHold.isSynced) {
        SyncManager().syncHoldAmountToServer(newHold);
      }
    } else {
      Helper.showMessage(context, validations.first, false);
    }
  }
}
