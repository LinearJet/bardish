import 'package:flutter/material.dart';
import 'graph_models.dart';

class GraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final List<GraphParticle> particles;
  final List<GraphAnnotation> annotations;
  final List<GraphStickyNote> stickyNotes;
  final ThemeData theme;
  final Offset offset;
  final double scale;
  final double animationValue;
  final Object? draggedItem;
  final Object? selectedItem;
  final double dragScale; // 0.0 to 1.0 (pickup progress)
  final List<GraphNode> selectedNodes;
  final List<GraphNode> searchResults;

  GraphPainter({
    required this.nodes,
    required this.edges,
    required this.particles,
    required this.annotations,
    required this.stickyNotes,
    required this.theme,
    required this.offset,
    required this.scale,
    required this.animationValue,
    this.draggedItem,
    this.selectedItem,
    this.dragScale = 0.0,
    required this.selectedNodes,
    this.searchResults = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final visibleRect = Rect.fromLTRB(
      -offset.dx / scale - 400,
      -offset.dy / scale - 400,
      (size.width - offset.dx) / scale + 400,
      (size.height - offset.dy) / scale + 400,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // 1. Bottom Layer
    _drawEdges(canvas, visibleRect);
    _drawParticles(canvas, visibleRect);

    // 2. Middle Layer
    for (var ann in annotations) {
      if (!visibleRect.contains(ann.position)) continue;
      _drawAnnotation(canvas, ann, textPainter);
    }
    
    _drawNodes(canvas, visibleRect, textPainter);

    // 3. Top Layer
    for (var note in stickyNotes) {
      if (!visibleRect.contains(note.position)) continue;
      _drawStickyNote(canvas, note, textPainter);
    }

    // 4. Overlay
    if (selectedItem != null) {
      _drawSelectionControls(canvas, selectedItem!, textPainter);
    }

    canvas.restore();
  }

  void _drawEdges(Canvas canvas, Rect visibleRect) {
    final linePaint = Paint()..strokeWidth = 1.0..style = PaintingStyle.stroke;
    final int totalNodes = nodes.length;
    final double staggerSpeed = totalNodes > 20 ? 0.02 : 0.1;

    for (var edge in edges) {
      if (!visibleRect.contains(edge.source.position) &&
          !visibleRect.contains(edge.target.position)) continue;

      final double start = edge.source.index * staggerSpeed;
      final double opacity = ((animationValue - start) * 2.0).clamp(0.0, 0.3);

      if (opacity > 0) {
        linePaint.color = const Color(0xFF888888).withOpacity(opacity);
        canvas.drawLine(edge.source.position, edge.target.position, linePaint);
      }
    }
  }

  void _drawParticles(Canvas canvas, Rect visibleRect) {
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      if (!visibleRect.contains(p.position)) continue;
      double particleOpacity = 1.0;
      if (p.progress < 0.2) particleOpacity = p.progress / 0.2;
      if (p.progress > 0.8) particleOpacity = (1.0 - p.progress) / 0.2;
      particlePaint.color = const Color(0xFFA48566).withOpacity(0.8 * particleOpacity);
      canvas.drawCircle(p.position, 0.5, particlePaint);
    }
  }

  void _drawNodes(Canvas canvas, Rect visibleRect, TextPainter textPainter) {
    final int totalNodes = nodes.length;
    final double staggerSpeed = totalNodes > 20 ? 0.02 : 0.1;

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (!visibleRect.contains(node.position)) continue;

      double progress = (animationValue - (i * staggerSpeed)) * 4.0;
      progress = progress.clamp(0.0, 1.0);
      if (progress <= 0) continue;

      final isDragged = node == draggedItem;
      final isSelected = selectedNodes.contains(node);
      final isSearched = searchResults.contains(node);
      
      // Interaction scaling
      double scaleMultiplier = (isSelected || isSearched) ? 1.3 : 1.0;
      if (isDragged) scaleMultiplier = 1.3 + (0.2 * dragScale);

      final currentScale = Curves.easeOutBack.transform(progress) * scaleMultiplier;
      final currentOpacity = progress;

      final circlePaint = Paint()
        ..color = (isSelected || isSearched)
            ? const Color(0xFFA48566).withOpacity(0.9 * currentOpacity)
            : const Color(0xFF2E3238).withOpacity(0.9 * currentOpacity)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = (node.isBiggest || isDragged || isSelected || isSearched
            ? const Color(0xFFA48566)
            : const Color(0xFF666666)).withOpacity(currentOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (node.isBiggest || isDragged || isSelected || isSearched) ? 2.0 : 1.0;

      canvas.save();
      canvas.translate(node.position.dx, node.position.dy);
      canvas.scale(currentScale);

      // Dynamic shadow based on lift
      if (isDragged || isSelected || isSearched) {
        double blur = 12 + (10 * dragScale);
        final shadowPaint = Paint()
          ..color = const Color(0xFFA48566).withOpacity(0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
        canvas.drawCircle(Offset.zero, node.radius + 8, shadowPaint);
      }

      canvas.drawCircle(Offset.zero, node.radius, circlePaint);
      canvas.drawCircle(Offset.zero, node.radius, borderPaint);

      // Label
      String label = node.note.title.isEmpty ? "Untitled" : node.note.title;
      bool showLabel = scale > 0.8 || node.isBiggest || isDragged || isSelected || isSearched;

      if (showLabel) {
        if (label.length > 10 && !node.isBiggest && !isDragged && !isSelected && !isSearched) {
          label = "${label.substring(0, 8)}..";
        }
        double fontSize = (node.radius * 0.7).clamp(8.0, 14.0);
        textPainter.text = TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white.withOpacity(currentOpacity),
            fontSize: fontSize,
            fontWeight: (node.isBiggest || isDragged || isSelected || isSearched) ? FontWeight.bold : FontWeight.w500,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(-textPainter.width / 2, node.radius + 4));
      }
      canvas.restore();
    }
  }

  void _drawAnnotation(Canvas canvas, GraphAnnotation ann, TextPainter textPainter) {
    final isDragged = draggedItem == ann;
    final scaleMult = isDragged ? (1.0 + (0.1 * dragScale)) : 1.0;

    textPainter.text = TextSpan(
      text: ann.text,
      style: TextStyle(
        color: ann.color,
        fontSize: ann.fontSize * scaleMult,
        fontWeight: FontWeight.bold,
        fontFamily: 'Serif',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, ann.position - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  void _drawStickyNote(Canvas canvas, GraphStickyNote note, TextPainter textPainter) {
    final isDragged = draggedItem == note;
    final scaleMult = isDragged ? (1.0 + (0.05 * dragScale)) : 1.0;
    
    final rect = Rect.fromCenter(
      center: note.position, 
      width: note.width * scaleMult, 
      height: note.height * scaleMult
    );

    // Shadow moves further away as you lift
    final shadowOffset = isDragged ? (4 + 8 * dragScale) : 4.0;
    final shadowBlur = isDragged ? (4 + 8 * dragScale) : 4.0;

    final shadowPath = Path()..addRect(rect.shift(Offset(shadowOffset, shadowOffset)));
    canvas.drawShadow(shadowPath, Colors.black, shadowBlur, true);

    // Note Body
    final notePaint = Paint()..color = note.color;
    canvas.drawRect(rect, notePaint);

    // Text
    textPainter.text = TextSpan(
      text: note.text,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 14,
        fontFamily: 'Serif',
        height: 1.4,
      ),
    );
    textPainter.layout(maxWidth: rect.width - 20);
    textPainter.paint(canvas, rect.topLeft + const Offset(10, 10));
  }

  void _drawSelectionControls(Canvas canvas, Object item, TextPainter textPainter) {
    Rect rect;
    if (item is GraphStickyNote) {
      rect = Rect.fromCenter(center: item.position, width: item.width, height: item.height);
    } else if (item is GraphAnnotation) {
      textPainter.text = TextSpan(
        text: item.text,
        style: TextStyle(fontSize: item.fontSize, fontFamily: 'Serif', fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      rect = Rect.fromCenter(center: item.position, width: textPainter.width + 20, height: textPainter.height + 20);
    } else {
      return;
    }

    // Border
    final paint = Paint()
      ..color = const Color(0xFFA48566)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, paint);

    // Resize Handle (Bottom-Right)
    final resizeCenter = rect.bottomRight;
    canvas.drawCircle(resizeCenter, 10, Paint()..color = const Color(0xFFA48566));
    
    // Draw simple white arrow shape for resize
    final arrowPaint = Paint()..color = Colors.white..strokeWidth = 2.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawLine(resizeCenter + const Offset(-4, -4), resizeCenter + const Offset(4, 4), arrowPaint);
    canvas.drawLine(resizeCenter + const Offset(4, 4), resizeCenter + const Offset(0, 4), arrowPaint);
    canvas.drawLine(resizeCenter + const Offset(4, 4), resizeCenter + const Offset(4, 0), arrowPaint);

    // Delete Button (Top-Right)
    final deleteCenter = rect.topRight;
    canvas.drawCircle(deleteCenter, 12, Paint()..color = Colors.redAccent);
    
    // Draw white X
    final xPaint = Paint()..color = Colors.white..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    canvas.drawLine(deleteCenter + const Offset(-4, -4), deleteCenter + const Offset(4, 4), xPaint);
    canvas.drawLine(deleteCenter + const Offset(4, -4), deleteCenter + const Offset(-4, 4), xPaint);
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) => true;
}