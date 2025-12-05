import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late DateTime updatedAt;

  @HiveField(5)
  String? blockId; 
  
  @HiveField(6, defaultValue: false)
  bool isPinned = false; 

  @HiveField(7)
  int? colorValue;

  @HiveField(8)
  String? projectId; 

  @HiveField(9, defaultValue: false)
  bool isPrivate = false;

  bool get isEmpty => title.isEmpty && content.isEmpty;
}