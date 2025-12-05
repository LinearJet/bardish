import 'package:flutter/material.dart';

class UndoRedoBar extends StatelessWidget {
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  const UndoRedoBar({
    super.key,
    required this.onUndo,
    required this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color(0xFF262321) : Colors.grey.shade200;
    final iconColor = theme.iconTheme.color;
    final disabledColor = iconColor?.withOpacity(0.3);

    return Container(
      height: 48,
      width: 120,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: canUndo ? onUndo : null,
            icon: Icon(Icons.undo, color: canUndo ? iconColor : disabledColor, size: 20),
            tooltip: 'Undo',
          ),
          Container(
            width: 1,
            height: 20,
            color: theme.dividerColor.withOpacity(0.1),
          ),
          IconButton(
            onPressed: canRedo ? onRedo : null,
            icon: Icon(Icons.redo, color: canRedo ? iconColor : disabledColor, size: 20),
            tooltip: 'Redo',
          ),
        ],
      ),
    );
  }
}