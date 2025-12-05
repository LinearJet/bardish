import 'package:hive_flutter/hive_flutter.dart';
import '../models/project.dart';

class ProjectDatabase {
  static const String _boxName = 'projects';

  static Box<Project> get _box => Hive.box<Project>(_boxName);

  static Future<void> initialize() async {
    Hive.registerAdapter(ProjectAdapter());
    await Hive.openBox<Project>(_boxName);
  }

  static Future<void> saveProject(Project project) async {
    if (project.isInBox) {
      project.updatedAt = DateTime.now();
      await project.save();
    } else {
      await _box.put(project.id, project);
    }
  }

  static Future<void> deleteProject(String id) async {
    await _box.delete(id);
  }

  static List<Project> getProjects() {
    final projects = _box.values.toList();
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }
}