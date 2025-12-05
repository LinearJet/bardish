import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'graph_models.dart';

class GraphStickyNoteDialog extends StatefulWidget {
  final Offset position;
  final Function(GraphStickyNote) onSave;

  const GraphStickyNoteDialog({
    super.key,
    required this.position,
    required this.onSave,
  });

  @override
  State<GraphStickyNoteDialog> createState() => _GraphStickyNoteDialogState();
}

class _GraphStickyNoteDialogState extends State<GraphStickyNoteDialog> {
  final TextEditingController _textController = TextEditingController();
  Color _noteColor = const Color(0xFFFFF8B8); // Default Yellow

  final List<Color> _colors = [
    const Color(0xFFFFF8B8), // Yellow
    const Color(0xFFE2F6D3), // Green
    const Color(0xFFD4E4ED), // Blue
    const Color(0xFFF6E2DD), // Pink
    const Color(0xFFE9E3D4), // Beige
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_textController.text.trim().isEmpty) return;

    final note = GraphStickyNote(
      id: const Uuid().v4(),
      text: _textController.text.trim(),
      position: widget.position,
      color: _noteColor,
    );

    widget.onSave(note);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF262321);
    const inputBg = Color(0xFF332F2C);
    const accentColor = Color(0xFFA48566);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Sticky Note',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEAEAEA),
                fontFamily: 'Serif',
              ),
            ),
            const SizedBox(height: 20),

            // Color Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _colors.map((c) => GestureDetector(
                onTap: () => setState(() => _noteColor = c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: _noteColor == c 
                        ? Border.all(color: Colors.white, width: 2) 
                        : null,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),

            // Text Input
            Container(
              decoration: BoxDecoration(
                color: _noteColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _textController,
                maxLines: 4,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Write something...',
                  hintStyle: TextStyle(color: Colors.black45),
                  border: InputBorder.none,
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: accentColor)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}