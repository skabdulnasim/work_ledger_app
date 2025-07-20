import 'package:flutter/material.dart';

class AttendanceCircle extends CustomPainter {
  final String attendanceType;
  AttendanceCircle({required this.attendanceType});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    if (attendanceType == "full") {
      paint.color = Colors.green;
      canvas.drawCircle(center, radius, paint);
    } else if (attendanceType == "half") {
      // Left half green
      paint.color = Colors.green;
      canvas.drawArc(rect, -3.14 / 2, 3.14, true, paint);

      // Right half yellow
      paint.color = Colors.yellow;
      canvas.drawArc(rect, 3.14 / 2, 3.14, true, paint);
    } else {
      paint.color = Colors.red;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
