import 'package:flutter/material.dart';
import 'option_item.dart';

class OptionIconPainter extends CustomPainter {
  final OptionIconType iconType;
  final Color color;

  OptionIconPainter({
    required this.iconType,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (iconType) {
      case OptionIconType.note:
        _drawNoteIcon(canvas, size, paint);
        break;
      case OptionIconType.folder:
        _drawFolderIcon(canvas, size, paint);
        break;
      case OptionIconType.checklist:
        _drawChecklistIcon(canvas, size, paint);
        break;
    }
  }

  void _drawNoteIcon(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.15)
      ..lineTo(size.width * 0.65, size.height * 0.15)
      ..lineTo(size.width * 0.75, size.height * 0.28)
      ..lineTo(size.width * 0.75, size.height * 0.85)
      ..lineTo(size.width * 0.25, size.height * 0.85)
      ..close();
    
    canvas.drawPath(path, paint);
    
    canvas.drawLine(
      Offset(size.width * 0.65, size.height * 0.15),
      Offset(size.width * 0.65, size.height * 0.28),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, size.height * 0.28),
      Offset(size.width * 0.75, size.height * 0.28),
      paint,
    );
    
    // Content lines
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.45),
      Offset(size.width * 0.65, size.height * 0.45),
      paint..strokeWidth = 1.6,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.6),
      Offset(size.width * 0.65, size.height * 0.6),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.75),
      Offset(size.width * 0.55, size.height * 0.75),
      paint,
    );
  }

  void _drawFolderIcon(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.35)
      ..lineTo(size.width * 0.2, size.height * 0.75)
      ..lineTo(size.width * 0.8, size.height * 0.75)
      ..lineTo(size.width * 0.8, size.height * 0.35)
      ..lineTo(size.width * 0.55, size.height * 0.35)
      ..lineTo(size.width * 0.48, size.height * 0.25)
      ..lineTo(size.width * 0.2, size.height * 0.25)
      ..close();
    
    canvas.drawPath(path, paint);
  }

  void _drawChecklistIcon(Canvas canvas, Size size, Paint paint) {
    final checkSize = size.width * 0.18;
    final Paint fillPaint = Paint()..color = color..style = PaintingStyle.fill;
    
    _drawSmallCheckbox(canvas, size.width * 0.22, size.height * 0.22, checkSize, paint, fillPaint, true);
    canvas.drawLine(
      Offset(size.width * 0.48, size.height * 0.31),
      Offset(size.width * 0.78, size.height * 0.31),
      paint..strokeWidth = 1.8,
    );
    
    _drawSmallCheckbox(canvas, size.width * 0.22, size.height * 0.5, checkSize, paint, fillPaint, false);
    canvas.drawLine(
      Offset(size.width * 0.48, size.height * 0.59),
      Offset(size.width * 0.78, size.height * 0.59),
      paint,
    );
    
    _drawSmallCheckbox(canvas, size.width * 0.22, size.height * 0.78, checkSize, paint, fillPaint, false);
    canvas.drawLine(
      Offset(size.width * 0.48, size.height * 0.87),
      Offset(size.width * 0.68, size.height * 0.87),
      paint,
    );
  }

  void _drawSmallCheckbox(Canvas canvas, double x, double y, double size, Paint paint, Paint fillPaint, bool checked) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, size, size),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, paint..strokeWidth = 2.0);
    
    if (checked) {
      final checkPath = Path()
        ..moveTo(x + size * 0.25, y + size * 0.5)
        ..lineTo(x + size * 0.45, y + size * 0.72)
        ..lineTo(x + size * 0.78, y + size * 0.28);
      canvas.drawPath(checkPath, paint..strokeWidth = 2.0);
    }
  }

  @override
  bool shouldRepaint(OptionIconPainter oldDelegate) =>
      iconType != oldDelegate.iconType || color != oldDelegate.color;
}