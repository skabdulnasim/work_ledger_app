import 'package:flutter/material.dart';

class ThreeSwitchState extends StatefulWidget {
  final List<String> labels;
  final ValueChanged<int> onStateChanged;
  final int initialIndex;
  final Axis axis;

  const ThreeSwitchState({
    Key? key,
    required this.labels,
    required this.onStateChanged,
    this.initialIndex = 0,
    this.axis = Axis.horizontal,
  }) : super(key: key);

  @override
  State<ThreeSwitchState> createState() => _ThreeSwitchStateState();
}

class _ThreeSwitchStateState extends State<ThreeSwitchState> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  Color getColor(int index) {
    if (index == 0) return const Color.fromARGB(255, 255, 57, 57);
    if (index == 1) return const Color.fromARGB(255, 255, 238, 0);
    return const Color.fromARGB(255, 0, 228, 72);
  }

  @override
  Widget build(BuildContext context) {
    final isSelected =
        List.generate(widget.labels.length, (i) => i == selectedIndex);

    return ToggleButtons(
      direction: widget.axis,
      isSelected: isSelected,
      onPressed: (index) {
        setState(() {
          selectedIndex = index;
        });
        widget.onStateChanged(index);
      },
      borderRadius: BorderRadius.circular(8.0),
      selectedBorderColor: getColor(selectedIndex),
      fillColor: getColor(selectedIndex),
      selectedColor: Colors.black,
      color: Colors.black26,
      children: widget.labels
          .map((label) => Text(
                label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ))
          .toList(),
    );
  }
}
