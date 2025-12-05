import 'dart:ui';
import '../../models/note.dart';

class GraphNode {
  final Note note;
  Offset position;
  double radius;
  bool isBiggest;
  final int index;

  GraphNode({
    required this.note,
    required this.position,
    required this.radius,
    this.isBiggest = false,
    required this.index,
  });
}

class GraphEdge {
  final GraphNode source;
  final GraphNode target;
  GraphEdge({required this.source, required this.target});
}

class GraphParticle {
  final GraphNode start;
  final GraphNode end;
  double progress;
  final double speed;

  GraphParticle({
    required this.start,
    required this.end,
    this.progress = 0.0,
    required this.speed,
  });

  Offset get position {
    return Offset.lerp(start.position, end.position, progress)!;
  }
}

class GraphAnnotation {
  String id;
  String text;
  Offset position;
  double fontSize;
  Color color;

  GraphAnnotation({
    required this.id,
    required this.text,
    required this.position,
    required this.fontSize,
    required this.color,
  });
}

class GraphStickyNote {
  String id;
  String text;
  Offset position;
  double width;
  double height;
  Color color;

  GraphStickyNote({
    required this.id,
    required this.text,
    required this.position,
    this.width = 150.0,
    this.height = 150.0,
    required this.color,
  });
}