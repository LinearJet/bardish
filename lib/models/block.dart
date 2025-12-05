import 'package:hive/hive.dart';

part 'block.g.dart';

@HiveType(typeId: 3)
class Block extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late DateTime createdAt;
}
