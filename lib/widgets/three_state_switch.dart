import 'package:flutter/material.dart';

class ThreeStateSwitch extends StatefulWidget {
  final List<String> labels;
  final ValueChanged<int> onStateChanged;
  final int selectedIndex; // To pass initial selected state
  final Axis axis; // To define orientation: vertical or horizontal

  const ThreeStateSwitch({
    Key? key,
    required this.labels,
    required this.onStateChanged,
    this.selectedIndex = 1, // Default to middle state
    this.axis = Axis.horizontal, // Default orientation is horizontal
  }) : super(key: key);

  @override
  _ThreeStateSwitchState createState() => _ThreeStateSwitchState();
}

class _ThreeStateSwitchState extends State<ThreeStateSwitch> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      direction: widget.axis, // Set the orientation based on passed axis
      isSelected: List.generate(3, (index) => index == _selectedIndex),
      onPressed: (int index) {
        setState(() {
          _selectedIndex = index;
        });
        widget.onStateChanged(index);
      },
      borderRadius: BorderRadius.circular(8.0),
      selectedBorderColor: _selectedIndex == 0
          ? const Color.fromARGB(255, 255, 57, 57)
          : _selectedIndex == 1
              ? const Color.fromARGB(255, 255, 238, 0)
              : const Color.fromARGB(255, 0, 228, 72),
      fillColor: _selectedIndex == 0
          ? const Color.fromARGB(255, 255, 57, 57)
          : _selectedIndex == 1
              ? const Color.fromARGB(255, 255, 238, 0)
              : const Color.fromARGB(255, 0, 228, 72),
      selectedColor: Colors.black,
      color: Colors.black26,

      children: widget.labels
          .map((label) => Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ))
          .toList(),
    );
  }
}
