import 'package:flutter/material.dart';

class ThreeStateSwitch extends StatelessWidget {
  final List<String> labels;
  final ValueChanged<int> onStateChanged;
  final int selectedIndex;
  final Axis axis;

  const ThreeStateSwitch({
    Key? key,
    required this.labels,
    required this.onStateChanged,
    required this.selectedIndex,
    this.axis = Axis.horizontal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = List.generate(labels.length, (i) => i == selectedIndex);

    Color getColor(int index) {
      if (selectedIndex == 0) return const Color.fromARGB(255, 255, 57, 57);
      if (selectedIndex == 1) return const Color.fromARGB(255, 255, 238, 0);
      return const Color.fromARGB(255, 0, 228, 72);
    }

    return ToggleButtons(
      direction: axis,
      isSelected: isSelected,
      onPressed: onStateChanged,
      borderRadius: BorderRadius.circular(8.0),
      selectedBorderColor: getColor(selectedIndex),
      fillColor: getColor(selectedIndex),
      selectedColor: Colors.black,
      color: Colors.black26,
      children: labels
          .map((label) => Text(
                label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ))
          .toList(),
    );
  }
}
