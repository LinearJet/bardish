import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../services/todo_database.dart';

class TodoCard extends StatefulWidget {
  final TodoList todoList;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onCreateNote;

  const TodoCard({
    super.key,
    required this.todoList,
    required this.onDelete,
    required this.onEdit,
    required this.onCreateNote,
  });

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  bool _isExpanded = false;

  // Color options for the todo list
  static const Map<String, Color> colorOptions = {
    'red': Color(0xFFE57373),
    'orange': Color(0xFFFFB74D),
    'yellow': Color(0xFFFFD54F),
    'green': Color(0xFF81C784),
    'blue': Color(0xFF64B5F6),
    'purple': Color(0xFFBA68C8),
    'pink': Color(0xFFF06292),
  };

  Color _getColorFromLabel(String? label) {
    if (label == null) return Colors.transparent;
    return colorOptions[label] ?? Colors.transparent;
  }

  Future<void> _toggleTask(String taskId) async {
    await TodoDatabase.toggleTask(widget.todoList, taskId);
    setState(() {}); // Rebuild UI
  }

  Future<void> _showColorMenu(BuildContext context, Offset position) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    final String? selectedColor = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem<String>(
          value: null,
          height: 40,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).dividerColor, width: 2),
                ),
                child: Icon(Icons.close, size: 14, color: Theme.of(context).dividerColor),
              ),
              const SizedBox(width: 12),
              const Text('No color'),
            ],
          ),
        ),
        ...colorOptions.entries.map((entry) => PopupMenuItem<String>(
          value: entry.key,
          height: 40,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: entry.value,
                  shape: BoxShape.circle,
                  border: widget.todoList.colorLabel == entry.key
                      ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Text(entry.key[0].toUpperCase() + entry.key.substring(1)),
            ],
          ),
        )).toList(),
      ],
    );

    if (selectedColor != widget.todoList.colorLabel) {
      await TodoDatabase.updateColorLabel(widget.todoList, selectedColor);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Theme Colors
    final cardColor = theme.cardColor; // Or theme.colorScheme.surface
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final secondaryTextColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.6);
    final borderColor = theme.dividerColor.withOpacity(0.1);

    final completedCount = widget.todoList.tasks.where((t) => t.isCompleted).length;
    final totalCount = widget.todoList.tasks.length;

    // Get the color for the dot
    final hasCustomColor = widget.todoList.colorLabel != null;
    final dotColor = hasCustomColor
        ? _getColorFromLabel(widget.todoList.colorLabel)
        : (completedCount == totalCount && totalCount > 0 
            ? Colors.green 
            : colorScheme.secondary);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- Header ---
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Status Dot - Now clickable for color selection
                  GestureDetector(
                    onTapDown: (TapDownDetails details) {
                      _showColorMenu(context, details.globalPosition);
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Tooltip(
                        message: 'Click to change color',
                        child: Container(
                          width: 16,
                          height: 16,
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                              boxShadow: hasCustomColor ? [
                                BoxShadow(
                                  color: dotColor.withOpacity(0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ] : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.todoList.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedCount of $totalCount completed',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  if (_isExpanded) ...[
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_up, color: theme.iconTheme.color),
                      onPressed: () => setState(() => _isExpanded = false),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: theme.iconTheme.color, size: 20),
                      onPressed: widget.onEdit,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: colorScheme.error.withOpacity(0.7), size: 20),
                      onPressed: widget.onDelete,
                    ),
                  ] else ...[
                     IconButton(
                      icon: Icon(Icons.keyboard_arrow_down, color: theme.iconTheme.color),
                      onPressed: () => setState(() => _isExpanded = true),
                    ),
                  ]
                ],
              ),
            ),
          ),

          // --- Expanded Content ---
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Column(
                    children: [
                      Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
                      // Tasks List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.todoList.tasks.length,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        itemBuilder: (context, index) {
                          final task = widget.todoList.tasks[index];
                          return ListTile(
                            dense: true,
                            onTap: () => _toggleTask(task.id),
                            leading: SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: task.isCompleted,
                                onChanged: (val) => _toggleTask(task.id),
                                activeColor: colorScheme.secondary,
                                checkColor: colorScheme.onSecondary,
                                side: BorderSide(color: theme.disabledColor, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            title: Text(
                              task.text,
                              style: TextStyle(
                                color: task.isCompleted ? theme.disabledColor : textColor,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                decorationColor: theme.disabledColor,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // Create Note Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: widget.onCreateNote,
                            icon: Icon(Icons.note_add_outlined, size: 18, color: theme.iconTheme.color),
                            label: Text("Create note", style: TextStyle(color: textColor)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.dividerColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}