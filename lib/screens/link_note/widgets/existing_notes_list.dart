import 'package:flutter/material.dart';
import '../../../models/note.dart';
import '../../../services/note_database.dart';

class ExistingNotesList extends StatefulWidget {
  final String searchQuery;
  final Function(Note) onNoteSelected;

  const ExistingNotesList({
    super.key,
    required this.searchQuery,
    required this.onNoteSelected,
  });

  @override
  State<ExistingNotesList> createState() => _ExistingNotesListState();
}

class _ExistingNotesListState extends State<ExistingNotesList> {
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void didUpdateWidget(ExistingNotesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _loadNotes();
    }
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final results = await NoteDatabase.searchNotes(widget.searchQuery);
    if (mounted) {
      setState(() {
        _notes = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notes.isEmpty) {
      return Center(
        child: Text(
          "No notes found",
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return _NoteLinkTile(
          note: note,
          onTap: () => widget.onNoteSelected(note),
        );
      },
    );
  }
}

class _NoteLinkTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const _NoteLinkTile({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = note.title.isEmpty ? "Untitled" : note.title;
    final snippet = note.content.replaceAll('\n', ' ').trim();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface, // Background similar to screenshot cards
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontFamily: 'Serif', // Matching your style
              ),
            ),
            if (snippet.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
