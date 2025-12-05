import 'package:hive/hive.dart';

part 'project.g.dart';

@HiveType(typeId: 4)
class Project extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late int colorValue;

  @HiveField(3)
  late String iconKey; // 'network', 'hub', 'ideas', 'favorites'

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  late DateTime updatedAt;
}