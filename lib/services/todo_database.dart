import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo.dart';

class TodoDatabase {
  static const String _boxName = 'todos';

  static Box<TodoList> get _box => Hive.box<TodoList>(_boxName);

  // Initialize (call this in main.dart)
  static Future<void> initialize() async {
    Hive.registerAdapter(TodoListAdapter());
    Hive.registerAdapter(TodoTaskAdapter());
    await Hive.openBox<TodoList>(_boxName);
  }

  // Save or Update
  static Future<void> saveTodoList(TodoList todoList) async {
    if (todoList.isInBox) {
      todoList.updatedAt = DateTime.now();
      await todoList.save();
    } else {
      await _box.put(todoList.id, todoList);
    }
  }

  // Get All
  static Future<List<TodoList>> getTodoLists() async {
    final todos = _box.values.toList();
    todos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return todos;
  }

  // Delete
  static Future<void> deleteTodoList(String id) async {
    await _box.delete(id);
  }

  // Toggle Task
  static Future<void> toggleTask(TodoList todoList, String taskId) async {
    final taskIndex = todoList.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      todoList.tasks[taskIndex].isCompleted = !todoList.tasks[taskIndex].isCompleted;
      todoList.updatedAt = DateTime.now();
      await todoList.save();
    }
  }

  // Update Color Label
  static Future<void> updateColorLabel(TodoList todoList, String? colorLabel) async {
    todoList.colorLabel = colorLabel;
    todoList.updatedAt = DateTime.now();
    await todoList.save();
  }
}