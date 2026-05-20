import 'package:flutter/material.dart';

class FreehandDrawingOverlay extends StatefulWidget {
  @override
  _FreehandDrawingOverlayState createState() => _FreehandDrawingOverlayState();
}

class _FreehandDrawingOverlayState extends State<FreehandDrawingOverlay> {
  List<Offset> points = []; // Stores the points drawn

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          // Add new points as the user drags
          points.add(details.localPosition);
        });
      },
      onPanEnd: (details) {
        // End current path
        points.add(Offset.zero);
      },
      child: CustomPaint(
        painter: FreehandPainter(points),
        child: Container(
          color: Colors.grey.withOpacity(0.2), // Transparent background for overlay
        ),
      ),
    );
  }
}

class FreehandPainter extends CustomPainter {
  final List<Offset> points;

  FreehandPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint whenever points change
  }
}
