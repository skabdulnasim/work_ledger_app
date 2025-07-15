import 'package:flutter/material.dart';
import 'package:work_ledger/screens/employee_list_screen.dart';
import 'package:work_ledger/screens/site_list_screen.dart';
import 'package:work_ledger/screens/skill_list_screen.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  const BottomNav({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => EmployeeListScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SiteListScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SkillListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Background Bar with Carve
        ClipPath(
          clipper: BottomBarClipper(),
          child: Container(
            height: 70,
            color: const Color.fromARGB(255, 255, 235, 170),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                navItem(Icons.person_sharp, "Employee", 0, context),
                SizedBox(width: 60),
                navItem(Icons.work, "Skill", 2, context),
              ],
            ),
          ),
        ),

        // Floating Center Button
        Positioned(
          bottom: 10,
          child: GestureDetector(
            onTap: () => _onTap(context, 1),
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: currentIndex == 1
                    ? const Color.fromARGB(255, 2, 255, 31)
                    : const Color.fromARGB(255, 0, 191, 22),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: Icon(Icons.location_on,
                  size: 32,
                  color: currentIndex == 1
                      ? Colors.white
                      : const Color.fromARGB(234, 255, 255, 255)),
            ),
          ),
        ),
      ],
    );
  }

  Widget navItem(IconData icon, String label, int index, BuildContext context) {
    final bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => _onTap(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: isSelected ? Colors.blueAccent : Colors.grey.shade600),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom clipper for curved carve in center
class BottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double curveRadius = 35;
    final double centerWidth = 70;

    Path path = Path();
    path.lineTo((size.width - centerWidth) / 2 - 10, 0);
    path.quadraticBezierTo(
      size.width / 2,
      curveRadius * 2,
      (size.width + centerWidth) / 2 + 10,
      0,
    );
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
