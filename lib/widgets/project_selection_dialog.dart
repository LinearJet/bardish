import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/project_database.dart';
import '../services/note_database.dart'; // Added NoteDatabase
import '../screens/projects/create_project_sheet.dart';

class ProjectSelectionDialog extends StatefulWidget {
  const ProjectSelectionDialog({super.key});

  @override
  State<ProjectSelectionDialog> createState() => _ProjectSelectionDialogState();
}

class _ProjectSelectionDialogState extends State<ProjectSelectionDialog> {
  List<Project> _projects = [];
  Map<String, int> _projectCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final projects = ProjectDatabase.getProjects();
    final notes = await NoteDatabase.getNotes();
    
    final Map<String, int> counts = {};
    for (var project in projects) {
      counts[project.id] = notes.where((n) => n.projectId == project.id).length;
    }

    if (mounted) {
      setState(() {
        _projects = projects;
        _projectCounts = counts;
        _isLoading = false;
      });
    }
  }

  // ... (_openCreateSheet unchanged but calls _loadData) ...
  void _openCreateSheet() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true, 
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5), 
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const CreateProjectSheet();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
    _loadData(); 
  }

  @override
  Widget build(BuildContext context) {
    // ... theme ...
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final dialogBg = isDark ? const Color(0xFF1E1B19) : theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final hintColor = theme.hintColor;
    final bronzeColor = const Color(0xFFA48566);
    final itemColor = isDark ? const Color(0xFF353230) : theme.colorScheme.surface;

    return Dialog(
      backgroundColor: dialogBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: bronzeColor, shape: BoxShape.circle),
                  child: const Icon(Icons.account_tree_outlined, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select project',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Serif'),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_projects.length} project${_projects.length == 1 ? '' : 's'}',
                        style: TextStyle(fontSize: 14, color: hintColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // --- Project List ---
            Flexible(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator()) 
                  : _projects.isEmpty 
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text("No projects found", style: TextStyle(color: hintColor)),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _projects.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final project = _projects[index];
                            final count = _projectCounts[project.id] ?? 0;
                            return _buildProjectItem(project, count, itemColor, textColor, hintColor);
                          },
                        ),
            ),

            const SizedBox(height: 32),

            // --- Buttons ---
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        foregroundColor: textColor,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _openCreateSheet,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create\nproject', textAlign: TextAlign.center, style: TextStyle(height: 1.1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bronzeColor,
                        foregroundColor: const Color(0xFF1C1918),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectItem(Project project, int count, Color bgColor, Color textColor, Color subColor) {
    // Dynamic subtitle
    final String subtitle = count == 0 ? 'Empty project' : '$count note${count == 1 ? '' : 's'}';

    return GestureDetector(
      onTap: () => Navigator.pop(context, project),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: Color(project.colorValue), shape: BoxShape.circle),
              child: Icon(_getIconData(project.iconKey), color: Colors.white.withOpacity(0.9), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        count == 0 ? Icons.not_interested_rounded : Icons.description_outlined, 
                        size: 12, 
                        color: subColor
                      ),
                      const SizedBox(width: 4),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: subColor)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subColor, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String key) {
    switch (key) {
      case 'network': return Icons.account_tree_outlined;
      case 'hub': return Icons.hub_outlined;
      case 'ideas': return Icons.lightbulb_outline;
      case 'favorites': return Icons.star_outline;
      default: return Icons.folder_outlined;
    }
  }
}