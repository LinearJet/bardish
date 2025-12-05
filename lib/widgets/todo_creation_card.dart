import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/colors.dart';

class TodoCreationCard extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(String title, List<String> tasks) onCreate;

  const TodoCreationCard({
    super.key,
    required this.onCancel,
    required this.onCreate,
  });

  @override
  State<TodoCreationCard> createState() => _TodoCreationCardState();
}

class _TodoCreationCardState extends State<TodoCreationCard> {
  final TextEditingController _titleController = TextEditingController();
  final List<TextEditingController> _taskControllers = [];

  @override
  void initState() {
    super.initState();
    // Start with one empty task
    _addTask();
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _taskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addTask() {
    setState(() {
      _taskControllers.add(TextEditingController());
    });
  }

  void _removeTask(int index) {
    setState(() {
      _taskControllers[index].dispose();
      _taskControllers.removeAt(index);
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    final tasks = _taskControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (title.isNotEmpty || tasks.isNotEmpty) {
      widget.onCreate(
        title.isEmpty ? "Untitled List" : title,
        tasks,
      );
    } else {
      // Or show error? For now just cancel if empty
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                  "New List",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontFamily: 'Serif',
                  ),
                ),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title Input
            TextField(
              controller: _titleController,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: "Title",
                hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const Divider(),
            
            // Tasks List
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _taskControllers.length,
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Icon(Icons.check_box_outline_blank, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _taskControllers[index],
                            style: TextStyle(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: "Task item",
                              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3)),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addTask(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, color: colorScheme.error.withOpacity(0.5), size: 20),
                          onPressed: () => _removeTask(index),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Add Task Button
            TextButton.icon(
              onPressed: _addTask,
              icon: Icon(Icons.add, color: colorScheme.primary),
              label: Text("Add Task", style: TextStyle(color: colorScheme.primary)),
            ),

            const SizedBox(height: 24),

            // Bottom Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text("Cancel", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("Create"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
