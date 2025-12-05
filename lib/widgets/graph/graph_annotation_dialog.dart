import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../theme/colors.dart';
import 'graph_models.dart';

class GraphAnnotationDialog extends StatefulWidget {
  final Offset position;
  final Function(GraphAnnotation) onSave;

  const GraphAnnotationDialog({
    super.key,
    required this.position,
    required this.onSave,
  });

  @override
  State<GraphAnnotationDialog> createState() => _GraphAnnotationDialogState();
}

class _GraphAnnotationDialogState extends State<GraphAnnotationDialog> {
  final TextEditingController _textController = TextEditingController();
  double _fontSize = 36.0;
  Color _textColor = Colors.white;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_textController.text.trim().isEmpty) return;

    final annotation = GraphAnnotation(
      id: const Uuid().v4(),
      text: _textController.text.trim(),
      position: widget.position,
      fontSize: _fontSize,
      color: _textColor,
    );

    widget.onSave(annotation);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF262321);
    const inputBg = Color(0xFF332F2C);
    const accentColor = Color(0xFFA48566);

    return Dialog(
      backgroundColor: bgColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: SingleChildScrollView(  // <-- FIX: Wrap in SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New annotation',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEAEAEA),
                  fontFamily: 'Serif',
                ),
              ),
              const SizedBox(height: 24),

              // Text Input
              Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  onChanged: (val) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Label text',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Font Size Slider
              Text(
                'Font size: ${_fontSize.toInt()}sp',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: accentColor,
                  inactiveTrackColor: Colors.white10,
                  thumbColor: accentColor,
                  overlayColor: accentColor.withOpacity(0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _fontSize,
                  min: 12,
                  max: 100,
                  onChanged: (val) => setState(() => _fontSize = val),
                ),
              ),
              const SizedBox(height: 16),

              // Color Picker
              const Text(
                'Text color:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ColorBubble(
                    color: Colors.white,
                    isSelected: _textColor == Colors.white,
                    onTap: () => setState(() => _textColor = Colors.white),
                  ),
                  const SizedBox(width: 16),
                  _ColorBubble(
                    color: Colors.black,
                    isSelected: _textColor == Colors.black,
                    onTap: () => setState(() => _textColor = Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Preview Box
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  _textController.text.isEmpty ? 'Preview' : _textController.text,
                  style: TextStyle(
                    color: _textController.text.isEmpty 
                        ? Colors.white24 
                        : _textColor,
                    fontSize: _fontSize > 40 ? 40 : _fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

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
                      backgroundColor: Colors.white10,
                      foregroundColor: accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorBubble extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorBubble({required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: isSelected 
            ? Icon(Icons.check, color: color == Colors.white ? Colors.black : Colors.white) 
            : null,
      ),
    );
  }
}