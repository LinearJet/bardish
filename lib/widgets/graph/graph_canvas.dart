import 'package:flutter/material.dart';
import 'graph_models.dart';
import 'graph_painter.dart';

class GraphCanvas extends StatelessWidget {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final List<GraphParticle> particles;
  final List<GraphAnnotation> annotations;
  final List<GraphStickyNote> stickyNotes;
  final Offset viewportOffset;
  final double viewportScale;
  final double animationValue;
  final Object? selectedItem;
  final Object? draggedItem;
  final double dragScale; // New parameter for "lift" effect
  final List<GraphNode> selectedNodes; 
  final List<GraphNode> searchResults;
  
  final Function(ScaleStartDetails) onScaleStart;
  final Function(ScaleUpdateDetails) onScaleUpdate;
  final Function(ScaleEndDetails) onScaleEnd;
  final Function(TapUpDetails) onTapUp;

  const GraphCanvas({
    super.key,
    required this.nodes,
    required this.edges,
    required this.particles,
    required this.annotations,
    required this.stickyNotes,
    required this.viewportOffset,
    required this.viewportScale,
    required this.animationValue,
    this.selectedItem,
    this.draggedItem,
    this.dragScale = 0.0,
    required this.selectedNodes,
    required this.searchResults,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      onScaleEnd: onScaleEnd,
      onTapUp: onTapUp,
      child: CustomPaint(
        painter: GraphPainter(
          nodes: nodes,
          edges: edges,
          particles: particles,
          annotations: annotations,
          stickyNotes: stickyNotes,
          theme: Theme.of(context),
          offset: viewportOffset,
          scale: viewportScale,
          animationValue: animationValue,
          draggedItem: draggedItem,
          selectedItem: selectedItem,
          dragScale: dragScale,
          selectedNodes: selectedNodes,
          searchResults: searchResults,
        ),
        size: Size.infinite,
      ),
    );
  }
}