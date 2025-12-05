import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/note.dart';
import '../../services/note_database.dart'; // Added: Needed for saving connections
import 'graph_edit_menu.dart';
import 'graph_models.dart';
import 'graph_canvas.dart';
import 'graph_annotation_dialog.dart';
import 'graph_sticky_note_dialog.dart';

class GraphView extends StatefulWidget {
  final List<Note> notes;
  final Function(Note) onNoteTap;
  final Function(bool canUndo, bool canRedo) onHistoryChanged;

  const GraphView({
    super.key,
    required this.notes,
    required this.onNoteTap,
    required this.onHistoryChanged,
  });

  @override
  State<GraphView> createState() => GraphViewState();
}

class GraphViewState extends State<GraphView> with TickerProviderStateMixin {
  List<GraphNode> _nodes = [];
  List<GraphEdge> _edges = [];
  final List<GraphParticle> _particles = [];
  final List<GraphNode> _selectedNodes = [];
  List<GraphNode> _searchResults = [];
  
  final List<GraphAnnotation> _annotations = [];
  final List<GraphStickyNote> _stickyNotes = [];

  final math.Random _random = math.Random();

  late AnimationController _fadeController;
  late AnimationController _particleController;
  late AnimationController _menuAnimController;
  late AnimationController _swapAnimController;
  
  late Animation<Offset> _menuSlideAnim;
  late Animation<double> _menuFadeAnim;
  late Animation<double> _swapAnim;

  // Drag "Pickup" Animation
  late AnimationController _dragController;
  late Animation<double> _dragAnimation;

  final List<List<Offset>> _undoStack = [];
  final List<List<Offset>> _redoStack = [];

  Box? _graphBox;
  String _storageKey = 'default';

  Offset _viewportOffset = Offset.zero;
  double _viewportScale = 0.5;
  Offset? _focalPointStart;
  Offset? _viewportOffsetStart;
  double? _viewportScaleStart;

  // Interaction State
  Object? _draggedItem;
  Object? _selectedItem; 
  bool _isResizing = false;
  bool _isDragging = false;
  
  bool _isInitialized = false;
  bool _isEditMode = false;
  Offset? _lastFocalPoint;
  
  Offset? _swapStart1, _swapStart2, _swapTarget1, _swapTarget2;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _particleController.addListener(_tickParticles);

    _menuAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _menuSlideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _menuAnimController, curve: Curves.easeOutBack),
    );
    _menuFadeAnim = CurvedAnimation(parent: _menuAnimController, curve: Curves.easeOut);

    _swapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _swapAnim = CurvedAnimation(parent: _swapAnimController, curve: Curves.easeInOutBack);
    _swapAnimController.addListener(_updateSwapPositions);

    // Expressive Drag Setup
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _dragAnimation = CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeOutBack,
    );

    _initializeWithPersistence();
  }

  void _tickParticles() {
    if (!mounted || _edges.isEmpty) return;
    if (_random.nextDouble() < 0.15 && _particles.length < 50) {
      final edge = _edges[_random.nextInt(_edges.length)];
      final bool reverse = _random.nextBool();
      _particles.add(GraphParticle(
        start: reverse ? edge.target : edge.source,
        end: reverse ? edge.source : edge.target,
        progress: 0.0,
        speed: 0.005 + (_random.nextDouble() * 0.01),
      ));
    }
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.progress += p.speed;
      if (p.progress >= 1.0) _particles.removeAt(i);
    }
    setState(() {});
  }

  // --- External Methods ---
  void toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      _selectedNodes.clear();
      _selectedItem = null;
    });
    if (_isEditMode) {
      _menuAnimController.forward();
    } else {
      _menuAnimController.reverse();
    }
  }

  void resetViewport() {
    setState(() {
      _viewportScale = 0.5;
      final size = MediaQuery.of(context).size;
      _viewportOffset = Offset(size.width / 2, size.height / 2);
    });
    _saveState();
  }

  void clearGraph() {
    setState(() {
      _selectedNodes.clear();
      _selectedItem = null;
      _annotations.clear();
      _stickyNotes.clear();
      _searchResults.clear();
    });
    _graphBox?.delete('${_storageKey}_annotations');
    _graphBox?.delete('${_storageKey}_stickies');
  }

  void addAnnotation() {
    final size = MediaQuery.of(context).size;
    final center = (_viewportOffset * -1 + Offset(size.width / 2, size.height / 2)) / _viewportScale;

    showDialog(
      context: context,
      builder: (context) => GraphAnnotationDialog(
        position: center,
        onSave: (annotation) {
          setState(() {
            _annotations.add(annotation);
            _selectedItem = annotation; 
          });
          _saveState();
        },
      ),
    );
  }

  void addStickyNote() {
    final size = MediaQuery.of(context).size;
    final center = (_viewportOffset * -1 + Offset(size.width / 2, size.height / 2)) / _viewportScale;
    
    showDialog(
      context: context,
      builder: (context) => GraphStickyNoteDialog(
        position: center,
        onSave: (note) {
          setState(() {
            _stickyNotes.add(note);
            _selectedItem = note; 
          });
          _saveState();
        },
      ),
    );
  }

  void searchNodes(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }
    
    final lowerQ = query.toLowerCase();
    setState(() {
      _searchResults = _nodes.where((n) {
        return n.note.title.toLowerCase().contains(lowerQ) ||
               n.note.content.toLowerCase().contains(lowerQ);
      }).toList();
    });
  }

  Future<void> _initializeWithPersistence() async {
    if (widget.notes.isNotEmpty && widget.notes.first.projectId != null) {
      _storageKey = 'graph_${widget.notes.first.projectId}';
    }

    if (!Hive.isBoxOpen('graph_state')) {
      _graphBox = await Hive.openBox('graph_state');
    } else {
      _graphBox = Hive.box('graph_state');
    }

    if (_graphBox != null && mounted) {
      final double? savedScale = _graphBox!.get('${_storageKey}_scale');
      final double? savedDx = _graphBox!.get('${_storageKey}_dx');
      final double? savedDy = _graphBox!.get('${_storageKey}_dy');

      if (savedScale != null && savedDx != null && savedDy != null) {
        _viewportScale = savedScale;
        _viewportOffset = Offset(savedDx, savedDy);
      } else {
        final size = MediaQuery.of(context).size;
        _viewportOffset = Offset(size.width / 2, size.height / 2);
      }

      final sData = _graphBox!.get('${_storageKey}_stickies');
      if (sData is List) {
        _stickyNotes.clear();
        for (var s in sData) {
          _stickyNotes.add(GraphStickyNote(
            id: s['id'],
            text: s['text'],
            position: Offset(s['dx'], s['dy']),
            width: (s['w'] as num?)?.toDouble() ?? 150.0,
            height: (s['h'] as num?)?.toDouble() ?? 150.0,
            color: Color(s['color']),
          ));
        }
      }

      final aData = _graphBox!.get('${_storageKey}_annotations');
      if (aData is List) {
        _annotations.clear();
        for (var a in aData) {
          _annotations.add(GraphAnnotation(
            id: a['id'],
            text: a['text'],
            position: Offset(a['dx'], a['dy']),
            fontSize: a['fontSize'],
            color: Color(a['color']),
          ));
        }
      }
    }

    _initGraph();

    if (mounted) {
      setState(() => _isInitialized = true);
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _saveState();
    _fadeController.dispose();
    _particleController.removeListener(_tickParticles);
    _particleController.dispose();
    _menuAnimController.dispose();
    _swapAnimController.removeListener(_updateSwapPositions);
    _swapAnimController.dispose();
    _dragController.dispose(); 
    super.dispose();
  }

  void _saveState() {
    if (_graphBox == null) return;
    _graphBox!.put('${_storageKey}_scale', _viewportScale);
    _graphBox!.put('${_storageKey}_dx', _viewportOffset.dx);
    _graphBox!.put('${_storageKey}_dy', _viewportOffset.dy);

    for (var node in _nodes) {
      final key = '${_storageKey}_node_${node.note.id}';
      _graphBox!.put(key, [node.position.dx, node.position.dy]);
    }

    final annList = _annotations.map((a) => {
      'id': a.id,
      'text': a.text,
      'dx': a.position.dx,
      'dy': a.position.dy,
      'fontSize': a.fontSize,
      'color': a.color.value,
    }).toList();
    _graphBox!.put('${_storageKey}_annotations', annList);

    final stickyList = _stickyNotes.map((s) => {
      'id': s.id,
      'text': s.text,
      'dx': s.position.dx,
      'dy': s.position.dy,
      'w': s.width,
      'h': s.height,
      'color': s.color.value,
    }).toList();
    _graphBox!.put('${_storageKey}_stickies', stickyList);
  }

  void _initGraph() {
    final random = math.Random();
    _nodes = [];
    _edges = [];
    _particles.clear();

    if (widget.notes.isEmpty) return;

    int maxLen = 0;
    for (var n in widget.notes) {
      final l = n.content.length + (n.title.length * 20);
      if (l > maxLen) maxLen = l;
    }

    final double spread = math.max(1000.0, widget.notes.length * 150.0);

    for (int i = 0; i < widget.notes.length; i++) {
      final note = widget.notes[i];
      double radius = 10.0;
      if (maxLen > 0) {
        final score = (note.content.length + note.title.length * 20);
        final ratio = score / maxLen;
        radius = 10.0 + (10.0 * ratio);
      }

      Offset position;
      if (_graphBox != null) {
        final key = '${_storageKey}_node_${note.id}';
        final savedPos = _graphBox!.get(key);
        if (savedPos != null && savedPos is List) {
          position = Offset((savedPos[0] as num).toDouble(), (savedPos[1] as num).toDouble());
        } else {
          position = Offset(
            (random.nextDouble() - 0.5) * spread,
            (random.nextDouble() - 0.5) * spread
          );
        }
      } else {
        position = Offset(
          (random.nextDouble() - 0.5) * spread,
          (random.nextDouble() - 0.5) * spread
        );
      }

      _nodes.add(GraphNode(
        note: note,
        position: position,
        radius: radius,
        index: i,
      ));
    }

    _nodes.sort((a, b) => b.radius.compareTo(a.radius));
    if (_nodes.isNotEmpty) _nodes.first.isBiggest = true;

    for (var source in _nodes) {
      final regex = RegExp(r'\[\[(.*?)\]\]');
      final matches = regex.allMatches(source.note.content);

      for (final match in matches) {
        final title = match.group(1)?.toLowerCase();
        if (title == null) continue;
        try {
          final target = _nodes.firstWhere((n) => n.note.title.toLowerCase() == title && n != source);
          final exists = _edges.any((e) => (e.source == source && e.target == target) || (e.source == target && e.target == source));
          if (!exists) {
            _edges.add(GraphEdge(source: source, target: target));
          }
        } catch (_) {}
      }
    }
  }

  void _recordHistory() {
    final snapshot = _nodes.map((n) => n.position).toList();
    _undoStack.add(snapshot);
    _redoStack.clear(); 
    if (_undoStack.length > 20) _undoStack.removeAt(0);
    _notifyHistoryChanged();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final currentSnapshot = _nodes.map((n) => n.position).toList();
    _redoStack.add(currentSnapshot);
    final previousSnapshot = _undoStack.removeLast();
    _applySnapshot(previousSnapshot);
    _notifyHistoryChanged();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final currentSnapshot = _nodes.map((n) => n.position).toList();
    _undoStack.add(currentSnapshot);
    final nextSnapshot = _redoStack.removeLast();
    _applySnapshot(nextSnapshot);
    _notifyHistoryChanged();
  }

  void _applySnapshot(List<Offset> snapshot) {
    if (snapshot.length != _nodes.length) return; 
    if (mounted) {
      setState(() {
        for (int i = 0; i < _nodes.length; i++) {
          _nodes[i].position = snapshot[i];
        }
      });
    }
    _saveState();
  }

  void _notifyHistoryChanged() {
    widget.onHistoryChanged(_undoStack.isNotEmpty, _redoStack.isNotEmpty);
  }

  void _swapNodes() {
    if (_selectedNodes.length != 2) return;
    _recordHistory();
    _swapStart1 = _selectedNodes[0].position;
    _swapStart2 = _selectedNodes[1].position;
    _swapTarget1 = _swapStart2;
    _swapTarget2 = _swapStart1;
    _swapAnimController.forward(from: 0.0).then((_) {
      _selectedNodes.clear();
      _saveState();
    });
  }

  void _updateSwapPositions() {
    if (!mounted || _selectedNodes.length != 2 || _swapStart1 == null) return;
    setState(() {
      final t = _swapAnim.value;
      _selectedNodes[0].position = Offset.lerp(_swapStart1!, _swapTarget1!, t)!;
      _selectedNodes[1].position = Offset.lerp(_swapStart2!, _swapTarget2!, t)!;
    });
  }

  // --- UPDATED PERSISTENT CONNECTION LOGIC ---
  void _connectNodes() async {
    if (_selectedNodes.length != 2) return;
    final n1 = _selectedNodes[0];
    final n2 = _selectedNodes[1];
    
    final exists = _edges.any((e) => (e.source == n1 && e.target == n2) || (e.source == n2 && e.target == n1));
    
    if (!exists) {
      // 1. Update Visuals Immediately
      setState(() {
        _edges.add(GraphEdge(source: n1, target: n2));
        _selectedNodes.clear();
      });
      
      // 2. Persist to Database (Append link text)
      // We append [[Title]] to n1 to create the link
      if (!n1.note.content.contains('[[${n2.note.title}]]')) {
         n1.note.content += '\n\n[[${n2.note.title}]]';
         n1.note.updatedAt = DateTime.now();
         await NoteDatabase.saveNote(n1.note);
      }
    }
  }

  // --- UPDATED PERSISTENT DISCONNECT LOGIC ---
  void _disconnectNodes() async {
    if (_selectedNodes.length != 2) return;
    final n1 = _selectedNodes[0];
    final n2 = _selectedNodes[1];
    
    // 1. Update Visuals
    setState(() {
      _edges.removeWhere((e) => (e.source == n1 && e.target == n2) || (e.source == n2 && e.target == n1));
      _selectedNodes.clear();
    });

    // 2. Persist (Remove link from both to be safe)
    bool changed1 = false;
    bool changed2 = false;

    // Remove n2 link from n1
    final regex1 = RegExp(r'\[\[' + RegExp.escape(n2.note.title) + r'\]\]');
    if (n1.note.content.contains(regex1)) {
        n1.note.content = n1.note.content.replaceAll(regex1, '').trim();
        n1.note.updatedAt = DateTime.now();
        changed1 = true;
    }

    // Remove n1 link from n2
    final regex2 = RegExp(r'\[\[' + RegExp.escape(n1.note.title) + r'\]\]');
    if (n2.note.content.contains(regex2)) {
        n2.note.content = n2.note.content.replaceAll(regex2, '').trim();
        n2.note.updatedAt = DateTime.now();
        changed2 = true;
    }

    if (changed1) await NoteDatabase.saveNote(n1.note);
    if (changed2) await NoteDatabase.saveNote(n2.note);
  }

  Offset _screenToWorld(Offset screenPoint) {
    return (screenPoint - _viewportOffset) / _viewportScale;
  }

  dynamic _hitTest(Offset worldPoint) {
    if (_selectedItem != null) {
      Rect rect;
      if (_selectedItem is GraphStickyNote) {
        final s = _selectedItem as GraphStickyNote;
        rect = Rect.fromCenter(center: s.position, width: s.width, height: s.height);
      } else if (_selectedItem is GraphAnnotation) {
        final a = _selectedItem as GraphAnnotation;
        final textPainter = TextPainter(
          text: TextSpan(
            text: a.text,
            style: TextStyle(fontSize: a.fontSize, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        rect = Rect.fromCenter(center: a.position, width: textPainter.width + 20, height: textPainter.height + 20);
      } else {
        rect = Rect.zero;
      }

      final controlTouchRadius = 40.0 / _viewportScale;

      if ((worldPoint - rect.topRight).distance < controlTouchRadius) {
        return {'type': 'delete', 'item': _selectedItem};
      }
      if ((worldPoint - rect.bottomRight).distance < controlTouchRadius) {
        return {'type': 'resize', 'item': _selectedItem};
      }
    }

    for (var note in _stickyNotes.reversed) {
      final rect = Rect.fromCenter(center: note.position, width: note.width, height: note.height);
      if (rect.contains(worldPoint)) return note;
    }

    for (var ann in _annotations.reversed) {
      final textPainter = TextPainter(
          text: TextSpan(text: ann.text, style: TextStyle(fontSize: ann.fontSize)),
          textDirection: TextDirection.ltr
      )..layout();
      final rect = Rect.fromCenter(center: ann.position, width: textPainter.width + 20, height: textPainter.height + 20);
      if (rect.contains(worldPoint)) return ann;
    }

    for (var node in _nodes.reversed) {
      final hitRadius = math.max(node.radius, 40.0 / _viewportScale);
      if ((node.position - worldPoint).distance <= hitRadius) return node;
    }
    
    return null;
  }

  void _onScaleStart(ScaleStartDetails details) {
    final worldPoint = _screenToWorld(details.localFocalPoint);
    final result = _hitTest(worldPoint);
    
    if (result != null) {
      if (result is Map) {
        if (result['type'] == 'delete') {
          setState(() {
            if (result['item'] is GraphStickyNote) _stickyNotes.remove(result['item']);
            if (result['item'] is GraphAnnotation) _annotations.remove(result['item']);
            _selectedItem = null;
          });
          _saveState();
          return;
        }
        if (result['type'] == 'resize') {
          _isResizing = true;
          _draggedItem = result['item'];
        }
      } else {
        _isDragging = true;
        _draggedItem = result;
        _dragController.forward(); 
        if (_draggedItem is! GraphNode) {
          setState(() => _selectedItem = _draggedItem);
        }
        if (_draggedItem is GraphNode) _recordHistory();
      }
      _focalPointStart = null; 
    } else {
      _focalPointStart = details.localFocalPoint;
      _viewportOffsetStart = _viewportOffset;
      _viewportScaleStart = _viewportScale;
      if (_selectedItem != null) setState(() => _selectedItem = null);
    }
    
    _lastFocalPoint = details.localFocalPoint;
    if (mounted) setState(() {});
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final currentWorldPoint = _screenToWorld(details.localFocalPoint);
    final lastWorldPoint = _screenToWorld(_lastFocalPoint!);
    final delta = currentWorldPoint - lastWorldPoint;

    if (_isResizing && _draggedItem != null) {
      setState(() {
        if (_draggedItem is GraphStickyNote) {
          final s = _draggedItem as GraphStickyNote;
          s.width = math.max(50, s.width + delta.dx);
          s.height = math.max(50, s.height + delta.dy);
          s.position += Offset(delta.dx/2, delta.dy/2);
        } else if (_draggedItem is GraphAnnotation) {
          final a = _draggedItem as GraphAnnotation;
          a.fontSize = (a.fontSize + delta.dx * 0.5).clamp(8.0, 300.0);
        }
      });
      _lastFocalPoint = details.localFocalPoint;
      return;
    }

    if (_isDragging && _draggedItem != null) {
      setState(() {
        if (_draggedItem is GraphNode) (_draggedItem as GraphNode).position += delta;
        if (_draggedItem is GraphAnnotation) (_draggedItem as GraphAnnotation).position += delta;
        if (_draggedItem is GraphStickyNote) (_draggedItem as GraphStickyNote).position += delta;
      });
      _lastFocalPoint = details.localFocalPoint;
      return;
    }

    if (_focalPointStart != null && _viewportOffsetStart != null) {
      final newScale = (_viewportScaleStart! * details.scale).clamp(0.05, 5.0);
      final focalWorldPoint = (_focalPointStart! - _viewportOffsetStart!) / _viewportScaleStart!;
      final panDelta = details.localFocalPoint - _focalPointStart!;
      setState(() {
        _viewportScale = newScale;
        _viewportOffset = ((details.scale - 1.0).abs() < 0.01)
            ? _viewportOffsetStart! + panDelta
            : details.localFocalPoint - (focalWorldPoint * newScale);
      });
    }
    _lastFocalPoint = details.localFocalPoint;
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _draggedItem = null;
    _focalPointStart = null;
    _isDragging = false;
    _isResizing = false;
    _dragController.reverse();
    if (mounted) setState(() {});
    _saveState();
  }

  void _onTapUp(TapUpDetails details) {
    if (_isDragging || _isResizing) return;

    final worldPoint = _screenToWorld(details.localPosition);
    final hitResult = _hitTest(worldPoint);
    
    if (hitResult is Map && hitResult['type'] == 'delete') {
       setState(() {
          if (hitResult['item'] is GraphStickyNote) _stickyNotes.remove(hitResult['item']);
          if (hitResult['item'] is GraphAnnotation) _annotations.remove(hitResult['item']);
          _selectedItem = null;
       });
       _saveState();
       return;
    }

    final hitItem = (hitResult is Map) ? hitResult['item'] : hitResult;

    if (hitItem != null) {
      if (hitItem is GraphNode) {
        if (_isEditMode) {
          setState(() {
            if (_selectedNodes.contains(hitItem)) _selectedNodes.remove(hitItem);
            else {
              if (_selectedNodes.length < 2) _selectedNodes.add(hitItem);
              else { _selectedNodes.removeAt(0); _selectedNodes.add(hitItem); }
            }
          });
        } else {
          widget.onNoteTap(hitItem.note);
        }
      } else {
        setState(() => _selectedItem = hitItem);
      }
    } else {
      setState(() {
        _selectedNodes.clear();
        _selectedItem = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_fadeController, _particleController, _dragController]), 
          builder: (context, child) {
            return GraphCanvas(
              nodes: _nodes,
              edges: _edges,
              particles: _particles,
              annotations: _annotations,
              stickyNotes: _stickyNotes,
              viewportOffset: _viewportOffset,
              viewportScale: _viewportScale,
              animationValue: _fadeController.value,
              selectedItem: _selectedItem,
              draggedItem: _draggedItem,
              dragScale: _dragAnimation.value,
              selectedNodes: _selectedNodes,
              searchResults: _searchResults,
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              onTapUp: _onTapUp,
            );
          }
        ),

        if (_isEditMode)
          Positioned(
            bottom: 140,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _menuSlideAnim,
              child: FadeTransition(
                opacity: _menuFadeAnim,
                child: Center(
                  child: GraphEditMenu(
                    hasSelection: _selectedNodes.length == 2,
                    onSwap: _swapNodes,
                    onConnect: _connectNodes,
                    onDisconnect: _disconnectNodes,
                    onCancel: toggleEditMode,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}