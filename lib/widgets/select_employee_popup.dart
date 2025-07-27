import 'package:flutter/material.dart';
import 'package:work_ledger/db_models/db_employee.dart';
import 'package:work_ledger/models/employee.dart';

class SelectEmployeePopup extends StatefulWidget {
  @override
  _SelectEmployeePopupState createState() => _SelectEmployeePopupState();
}

class _SelectEmployeePopupState extends State<SelectEmployeePopup> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Employee> _employees = [];
  bool _isLoading = false;
  String _query = '';
  int _offset = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.requestFocus();
  }

  void _fetchEmployees() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    final employees = DBEmployee.getEmployees(
      offset: _offset,
      limit: _limit,
      qry: _query,
    );

    setState(() {
      _employees.addAll(employees);
      _isLoading = false;
      _offset += _limit;
    });
  }

  void _onSearchChanged() {
    setState(() {
      _query = _controller.text;
      _employees.clear();
      _offset = 0;
      _isLoading = false;
    });
    _fetchEmployees();
  }

  void _onScroll() {
    if (_isLoading) return; // Do not fetch more data if already loading

    // Calculate the maximum scroll extent before reaching the bottom
    final maxScroll = _scrollController.position.maxScrollExtent;
    // Calculate the current scroll position
    final currentScroll = _scrollController.position.pixels;

    // Check if we've reached the bottom of the list and there are more items to fetch
    if (currentScroll >= maxScroll && _employees.length >= _limit) {
      _fetchEmployees();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose(); // Dispose the FocusNode
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (value) => _onSearchChanged(),
                  onSubmitted: (String query) async {
                    if (_employees.isEmpty) {
                      Navigator.pop(context, query);
                    }
                  },
                  focusNode: _searchFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Search by employee name / mobile no.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2),
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle button press
                      Navigator.pop(context, _query);
                    },
                    style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                          // Ensure square shape
                        ),
                        backgroundColor: Colors.blue[100]),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceEvenly, // Center icon and text vertically
                      children: [
                        Icon(
                          Icons.people_alt,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _employees.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _employees.length) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              final employee = _employees[index];
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(width: 0.5, color: Colors.black),
                  ),
                ),
                child: ListTile(
                  title: _buildHighlightedText(employee.name, _query),
                  subtitle: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Text(
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              'Mobile : ',
                            ),
                            _buildHighlightedText(employee.mobileNo, _query),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              'Balance : ',
                            ),
                            Expanded(
                              child: Text(
                                '₹ ${employee.walletBalance.toStringAsFixed(2)}',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context, employee);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text);
    }

    final RegExp regex = RegExp(query, caseSensitive: false);
    final Iterable<RegExpMatch> matches = regex.allMatches(text);
    if (matches.isEmpty) {
      return Text(text);
    }

    List<TextSpan> spans = [];
    int start = 0;
    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: TextStyle(
            color: Colors.red,
          ),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(style: TextStyle(color: Colors.black), children: spans),
    );
  }
}
