import 'package:flutter/material.dart';
import 'create_project_sheet.dart';
import 'project_detail_screen.dart'; 
import '../../models/project.dart';
import '../../services/project_database.dart';
import '../../services/note_database.dart'; // Added NoteDatabase

// New Imports
import '../../widgets/projects/project_card.dart';
import '../../widgets/projects/rename_project_dialog.dart';
import '../../widgets/projects/project_selection_bar.dart';
import '../../widgets/projects/project_standard_bar.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> with SingleTickerProviderStateMixin {
  List<Project> _projects = [];
  Map<String, int> _projectCounts = {}; // Store counts here
  final Set<String> _selectedProjectIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool get _isSelectionMode => _selectedProjectIds.isNotEmpty;

  Future<void> _loadData() async {
    final projects = ProjectDatabase.getProjects();
    final notes = await NoteDatabase.getNotes();
    
    // Calculate counts
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

  // ... (Methods: _toggleSelection, _exitSelectionMode, _deleteSelected, _showRenameDialog, _openCreateSheet unchanged but calling _loadData instead of _loadProjects) ...

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedProjectIds.contains(id)) {
        _selectedProjectIds.remove(id);
      } else {
        _selectedProjectIds.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedProjectIds.clear();
    });
  }

  void _deleteSelected() async {
    for (var id in _selectedProjectIds) {
      await ProjectDatabase.deleteProject(id);
    }
    _exitSelectionMode();
    _loadData();
  }

  void _showRenameDialog() {
    if (_selectedProjectIds.length != 1) return;
    
    final projectId = _selectedProjectIds.first;
    final project = _projects.firstWhere((p) => p.id == projectId);
    final textController = TextEditingController(text: project.name);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return RenameProjectDialog(
          project: project,
          controller: textController,
          onCancel: () => Navigator.pop(context),
          onSave: () async {
            if (textController.text.trim().isNotEmpty) {
              project.name = textController.text.trim();
              await ProjectDatabase.saveProject(project);
              _loadData();
              _exitSelectionMode();
              if (mounted) Navigator.pop(context);
            }
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack).value,
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

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
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );

        return ScaleTransition(
          scale: curvedAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
    _loadData(); 
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = theme.hintColor;
    final cardColor = theme.cardColor;

    final projectCount = _projects.length;
    final selectionCount = _selectedProjectIds.length;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                _buildHeader(textColor, subTextColor, cardColor, projectCount, selectionCount, theme),

                // --- Content List ---
                Expanded(
                  child: _isLoading 
                      ? const Center(child: CircularProgressIndicator()) 
                      : _projects.isEmpty 
                          ? _buildEmptyState(textColor, subTextColor) 
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              color: theme.colorScheme.secondary,
                              backgroundColor: theme.scaffoldBackgroundColor,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                                itemCount: _projects.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final project = _projects[index];
                                  final count = _projectCounts[project.id] ?? 0;
                                  return ProjectCard(
                                    project: project,
                                    noteCount: count, // Pass count here
                                    isSelected: _selectedProjectIds.contains(project.id),
                                    isSelectionMode: _isSelectionMode,
                                    onLongPress: () {
                                      if (!_isSelectionMode) _toggleSelection(project.id);
                                    },
                                    onTap: () {
                                      if (_isSelectionMode) {
                                        _toggleSelection(project.id);
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => ProjectDetailScreen(project: project)),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),

            // --- Bottom Bar ---
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInBack,
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _isSelectionMode 
                    ? ProjectSelectionBar(
                        onEdit: _selectedProjectIds.length == 1 ? _showRenameDialog : null,
                        onDelete: _deleteSelected,
                        onExport: () {
                           ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Export coming soon")),
                           );
                        },
                      )
                    : ProjectStandardBar(
                        onBack: () => Navigator.pop(context),
                        onCreate: _openCreateSheet,
                        onMenuSelected: (value) {
                          if (value == 'import') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Import feature coming soon")),
                            );
                          }
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (Header and Empty State widgets same as before) ...
  Widget _buildHeader(Color textColor, Color subTextColor, Color cardColor, int projectCount, int selectionCount, ThemeData theme) {
    if (_isSelectionMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$selectionCount selected',
                  style: TextStyle(fontSize: 28, fontFamily: 'Serif', fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  '$projectCount project${projectCount != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 14, color: subTextColor),
                ),
              ],
            ),
            IconButton(
              onPressed: _exitSelectionMode,
              icon: Icon(Icons.close, color: subTextColor, size: 28),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Projects',
                style: TextStyle(fontSize: 32, fontFamily: 'Serif', fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 4),
              Text(
                projectCount == 1 ? '1 project' : '$projectCount projects',
                style: TextStyle(fontSize: 16, color: subTextColor),
              ),
            ],
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
            alignment: Alignment.center,
            child: Text('$projectCount', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color hintColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 64, color: hintColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No projects yet', style: TextStyle(color: hintColor, fontSize: 16)),
        ],
      ),
    );
  }
}