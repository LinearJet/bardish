import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/project.dart';
import '../../models/note.dart';
import '../../services/note_database.dart';
import '../../widgets/graph/graph_view.dart';
import '../note_view_screen.dart';
import '../note_editor_screen.dart';
import '../../widgets/note_view/note_preview_dialog.dart';
import '../../widgets/graph/graph_bottom_bar.dart';
import '../../widgets/common/undo_redo_bar.dart';
import '../../widgets/ai_chat_dialog.dart';
// Remove direct dialog import since GraphView handles it now
// import '../../widgets/graph/graph_annotation_dialog.dart'; 

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  List<Note> _projectNotes = [];
  bool _isLoading = true;
  bool _canUndo = false;
  bool _canRedo = false;
  
  final GlobalKey<GraphViewState> _graphKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    
    final allNotes = await NoteDatabase.getNotes();
    final filtered = allNotes.where((n) => n.projectId == widget.project.id).toList();
    
    if (mounted) {
      setState(() {
        _projectNotes = filtered;
        _isLoading = false;
      });
    }
  }

  void _showNotePreview(Note note) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => NotePreviewDialog(
        note: note,
        onEdit: () async {
          Navigator.pop(context);
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
          );
          _loadNotes();
        },
        onRemove: () async {
          Navigator.pop(context);
          note.projectId = null;
          await note.save();
          _loadNotes();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Removed '${note.title.isEmpty ? 'Untitled' : note.title}'"),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
    _loadNotes();
  }

  // --- Handlers for Bottom Bar Features ---

  void _onAnnotation() {
    // Calls the GraphView method to add annotation at center screen
    _graphKey.currentState?.addAnnotation();
  }

  void _onSearch() {
    showDialog(
      context: context,
      builder: (context) {
        String query = '';
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Search Graph', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Node title or content...',
                    hintStyle: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  onChanged: (val) {
                    query = val;
                    _graphKey.currentState?.searchNodes(val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _graphKey.currentState?.searchNodes('');
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _onToggleLight() {
    final box = Hive.box('settings');
    final current = box.get('themeMode', defaultValue: 'dark');
    final newMode = current == 'light' ? 'dark' : 'light';
    box.put('themeMode', newMode);
  }

  void _onAskAi() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AiChatDialog(contextNotes: _projectNotes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color(0xFF161312) : theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_projectNotes.isNotEmpty)
              Positioned.fill(
                child: GraphView(
                  key: _graphKey,
                  notes: _projectNotes,
                  onNoteTap: _showNotePreview,
                  onHistoryChanged: (canUndo, canRedo) {
                    setState(() {
                      _canUndo = canUndo;
                      _canRedo = canRedo;
                    });
                  },
                ),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hub, size: 80, color: theme.hintColor.withOpacity(0.5)),
                      const SizedBox(height: 24),
                      Text(
                        'No linked notes',
                        style: TextStyle(
                          fontFamily: 'Serif',
                          fontSize: 28,
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: UndoRedoBar(
                  canUndo: _canUndo,
                  canRedo: _canRedo,
                  onUndo: () => _graphKey.currentState?.undo(),
                  onRedo: () => _graphKey.currentState?.redo(),
                ),
              ),
            ),

            Positioned(
              bottom: 26,
              left: 30,
              right: 30,
              child: GraphBottomBar(
                onBack: () => Navigator.pop(context),
                onEdit: () => _graphKey.currentState?.toggleEditMode(),
                onReset: () => _graphKey.currentState?.resetViewport(),
                onClear: () => _graphKey.currentState?.clearGraph(),
                onAnnotation: _onAnnotation,
                onStickyNote: () => _graphKey.currentState?.addStickyNote(),
                onSearch: _onSearch,
                onToggleLight: _onToggleLight,
                onAskAi: _onAskAi,
              ),
            ),
          ],
        ),
      ),
    );
  }
}