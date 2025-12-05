import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/todo.dart';
import '../services/todo_database.dart';

class CreateTodoDialog extends StatefulWidget {
  final TodoList? existingList;

  const CreateTodoDialog({super.key, this.existingList});

  @override
  State<CreateTodoDialog> createState() => _CreateTodoDialogState();
}

class _CreateTodoDialogState extends State<CreateTodoDialog> {
  final _titleController = TextEditingController();
  final _newTaskController = TextEditingController();
  
  List<TodoTask> _tempTasks = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingList != null) {
      _titleController.text = widget.existingList!.title;
      _tempTasks = List.from(widget.existingList!.tasks);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _newTaskController.dispose();
    super.dispose();
  }

  void _addTask() {
    final text = _newTaskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _tempTasks.add(TodoTask(
          id: const Uuid().v4(),
          text: text,
          createdAt: DateTime.now(),
        ));
        _newTaskController.clear();
      });
    }
  }

  void _removeTask(int index) {
    setState(() {
      _tempTasks.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      _titleController.text = "List ${DateTime.now().toString().split(' ')[0]}";
    }

    final todoList = widget.existingList ?? TodoList()
      ..id = widget.existingList?.id ?? const Uuid().v4()
      ..createdAt = widget.existingList?.createdAt ?? DateTime.now();

    todoList.title = _titleController.text.trim();
    todoList.tasks = _tempTasks;
    todoList.updatedAt = DateTime.now();

    await TodoDatabase.saveTodoList(todoList);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final backgroundColor = theme.dialogBackgroundColor;
    final surfaceColor = isDark ? const Color(0xFF252322) : Colors.grey.shade100;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final hintColor = theme.hintColor;
    
    return Dialog(
      backgroundColor: backgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.playlist_add, color: colorScheme.secondary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        widget.existingList == null ? 'New to-do list' : 'Edit list',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: hintColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildTextField(
                controller: _titleController,
                label: "List title",
                hint: "Enter title...",
                textColor: textColor,
                hintColor: hintColor,
                borderColor: theme.dividerColor,
              ),
              
              const SizedBox(height: 24),
              
              Text(
                "Tasks (${_tempTasks.length})",
                style: TextStyle(
                  color: colorScheme.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 8),

              // Tasks List - Removed the Empty Placeholder to save space
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: _tempTasks.length,
                  separatorBuilder: (c, i) => Divider(height: 1, color: theme.dividerColor),
                  itemBuilder: (context, index) {
                    final task = _tempTasks[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.circle_outlined, size: 16, color: hintColor),
                      title: Text(task.text, style: TextStyle(color: textColor.withOpacity(0.8))),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: colorScheme.error.withOpacity(0.7)),
                        onPressed: () => _removeTask(index),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "+ Add tasks",
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _newTaskController,
                      label: "New task",
                      hint: "Enter task...",
                      textColor: textColor,
                      hintColor: hintColor,
                      borderColor: theme.dividerColor,
                      onSubmitted: (_) => _addTask(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _addTask,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add, color: colorScheme.onSecondary),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor.withOpacity(0.7),
                        side: BorderSide(color: theme.dividerColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text("Create", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color textColor,
    required Color hintColor,
    required Color borderColor,
    Function(String)? onSubmitted,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 16,
            child: Text(
              label,
              style: TextStyle(color: hintColor, fontSize: 10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            child: TextField(
              controller: controller,
              style: TextStyle(color: textColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: hintColor.withOpacity(0.5)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}
