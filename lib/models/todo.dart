import 'package:hive/hive.dart';

part 'todo.g.dart';

@HiveType(typeId: 1)
class TodoList extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late List<TodoTask> tasks;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late DateTime updatedAt;

  @HiveField(5)
  String? colorLabel; // For color organization
}

@HiveType(typeId: 2)
class TodoTask {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String text;

  @HiveField(2)
  late bool isCompleted;

  @HiveField(3)
  late DateTime createdAt;

  TodoTask({
    required this.id,
    required this.text,
    this.isCompleted = false,
    required this.createdAt,
  });
}