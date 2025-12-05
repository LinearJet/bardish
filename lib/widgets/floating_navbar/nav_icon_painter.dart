import 'package:flutter/material.dart';
import 'nav_bar_icon.dart';

class NavIconPainter extends CustomPainter {
  final NavIconType iconType;
  final Color color;
  final bool isActive;

  NavIconPainter({
    required this.iconType,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (iconType) {
      case NavIconType.notes:
        _drawNotesIcon(canvas, size, paint, fillPaint);
        break;
      case NavIconType.checklist:
        _drawChecklistIcon(canvas, size, paint, fillPaint);
        break;
    }
  }

  void _drawNotesIcon(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.15, size.width * 0.6, size.height * 0.7),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, paint);
    
    // Lines
    final lineY1 = size.height * 0.35;
    final lineY2 = size.height * 0.5;
    final lineY3 = size.height * 0.65;
    
    canvas.drawLine(
      Offset(size.width * 0.35, lineY1),
      Offset(size.width * 0.65, lineY1),
      paint..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, lineY2),
      Offset(size.width * 0.65, lineY2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, lineY3),
      Offset(size.width * 0.55, lineY3),
      paint,
    );
  }

  void _drawChecklistIcon(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final checkSize = size.width * 0.16;
    
    // First checkbox
    _drawCheckbox(canvas, size.width * 0.25, size.height * 0.25, checkSize, paint, fillPaint, true);
    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.32),
      Offset(size.width * 0.75, size.height * 0.32),
      paint..strokeWidth = 1.5,
    );
    
    // Second checkbox
    _drawCheckbox(canvas, size.width * 0.25, size.height * 0.5, checkSize, paint, fillPaint, false);
    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.57),
      Offset(size.width * 0.75, size.height * 0.57),
      paint,
    );
    
    // Third checkbox
    _drawCheckbox(canvas, size.width * 0.25, size.height * 0.75, checkSize, paint, fillPaint, true);
    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.82),
      Offset(size.width * 0.65, size.height * 0.82),
      paint,
    );
  }

  void _drawCheckbox(Canvas canvas, double x, double y, double size, Paint paint, Paint fillPaint, bool checked) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, size, size),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(rect, paint..strokeWidth = 1.8);
    
    if (checked) {
      final checkPath = Path()
        ..moveTo(x + size * 0.25, y + size * 0.5)
        ..lineTo(x + size * 0.45, y + size * 0.7)
        ..lineTo(x + size * 0.75, y + size * 0.3);
      canvas.drawPath(checkPath, paint..strokeWidth = 1.8);
    }
  }

  @override
  bool shouldRepaint(NavIconPainter oldDelegate) =>
      iconType != oldDelegate.iconType ||
      color != oldDelegate.color ||
      isActive != oldDelegate.isActive;
}