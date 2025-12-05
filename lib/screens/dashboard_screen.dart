import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_bottom_area.dart'; 
import '../models/note.dart';
import '../utils/dashboard_actions.dart';
import 'notes_tab.dart';
import 'todo_list_tab.dart';
import 'settings_screen.dart';
import '../widgets/notes_menu_item.dart';
import 'projects/projects_screen.dart'; // Import Projects Screen
import 'private_space_screen.dart'; // Import Private Space Screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  // ... (State variables: _currentIndex, _animController, etc. unchanged) ...
  int _currentIndex = 0;
  late AnimationController _animController;
  final GlobalKey<NotesTabState> _notesTabKey = GlobalKey();
  final GlobalKey<TodoListTabState> _todoTabKey = GlobalKey();
  final Box _settingsBox = Hive.box('settings');

  Set<Note> selectedNotes = {}; 
  bool isContextMode = false;
  bool _isForwardAnimation = true;
  bool isGridView = true;
  int _currentSortOrder = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ... (Selection and Animation Logic methods unchanged) ...
  void _toggleSelection(Note note) {
    setState(() {
      if (selectedNotes.contains(note)) {
        selectedNotes.remove(note);
        if (selectedNotes.isEmpty) isContextMode = false;
      } else {
        selectedNotes.add(note);
      }
    });
  }

  void _enterContextMode(Note note) {
    setState(() {
      selectedNotes = {note};
      isContextMode = true;
    });
  }

  void _exitContextMode() {
    setState(() {
      selectedNotes.clear();
      isContextMode = false;
    });
  }

  void _onTabChanged(int index) {
    if (_currentIndex == index) return;
    if (_animController.isAnimating) return;

    setState(() {
      if (index != 0) _exitContextMode();
      _isForwardAnimation = index > _currentIndex;
    });

    _runTransition(index);
  }

  Future<void> _runTransition(int nextIndex) async {
    await _animController.animateTo(0.5, curve: Curves.easeIn);
    setState(() {
      _currentIndex = nextIndex;
    });
    await _animController.animateTo(1.0, curve: Curves.easeOut);
    _animController.reset();
  }

  void _showNotesMenu() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              NotesMenuItem(
                icon: Icons.security,
                label: 'Private Space',
                onTap: () { 
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivateSpaceScreen()),
                  );
                },
              ),
              
              // UPDATED: Navigates to Projects Screen
              NotesMenuItem(
                icon: Icons.link,
                label: 'Links', // Renamed to "Links" as per prompt, but concept is Projects
                onTap: () { 
                  Navigator.pop(context); 
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProjectsScreen()),
                  );
                },
              ),
              
              NotesMenuItem(
                icon: Icons.music_note_outlined,
                label: 'Music',
                onTap: () { Navigator.pop(context); },
              ),
              NotesMenuItem(
                icon: Icons.delete_outline,
                label: 'Trash',
                onTap: () { Navigator.pop(context); },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (Build method remains largely the same, logic delegated to _showNotesMenu) ...
    final actions = DashboardActions(
      context: context,
      selectedNotes: selectedNotes.toList(), 
      onExit: _exitContextMode,
      onRefresh: () => _notesTabKey.currentState?.refreshNotes(),
    );

    final String title;
    if (isContextMode) {
      final count = selectedNotes.length;
      title = '$count selected';
    } else {
      title = _currentIndex == 0 ? 'Notes' : 'To-Do Lists';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false, 
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DashboardHeader(
              isContextMode: isContextMode,
              onExitContextMode: _exitContextMode,
              title: title,
              isGridView: isGridView,
              onViewChange: () {
                setState(() => isGridView = !isGridView);
              },
              onSortSelected: (value) {
                setState(() => _currentSortOrder = value);
              },
              onSettingsPressed: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.easeOutCubic;
                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      return SlideTransition(position: animation.drive(tween), child: child);
                    },
                  ),
                );
              },
              onNotesMenuPressed: _showNotesMenu,
            ),
            Expanded(
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      double contentSlide = 0.0;
                      if (_animController.value > 0.5) {
                        final progress = (_animController.value - 0.5) * 2;
                        contentSlide = (1.0 - progress) * (MediaQuery.of(context).size.height * 0.4);
                      }

                      return Transform.translate(
                        offset: Offset(0, contentSlide),
                        child: _buildCurrentTab(),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      final double width = MediaQuery.of(context).size.width;
                      double offsetX = 0;

                      if (_animController.value == 0 || _animController.value == 1) {
                        return const SizedBox.shrink();
                      }

                      if (_isForwardAnimation) {
                        if (_animController.value <= 0.5) {
                          final progress = _animController.value * 2;
                          offsetX = -width + (progress * width);
                        } else {
                          final progress = (_animController.value - 0.5) * 2;
                          offsetX = 0 - (progress * width);
                        }
                      } else {
                        if (_animController.value <= 0.5) {
                          final progress = _animController.value * 2;
                          offsetX = width - (progress * width);
                        } else {
                          final progress = (_animController.value - 0.5) * 2;
                          offsetX = 0 + (progress * width);
                        }
                      }

                      return Transform.translate(
                        offset: Offset(offsetX, 0),
                        child: Container(
                          width: width,
                          height: double.infinity,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DashboardBottomArea(
                      isContextMode: isContextMode,
                      actions: actions,
                      currentIndex: _currentIndex,
                      onTabChanged: _onTabChanged,
                      onRefreshNotes: () => _notesTabKey.currentState?.refreshNotes(),
                      onRefreshTodoList: () => _todoTabKey.currentState?.loadTodoLists(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    if (_currentIndex == 0) {
      return NotesTab(
        key: _notesTabKey,
        isContextMode: isContextMode,
        selectedNotes: selectedNotes, 
        onToggleSelection: _toggleSelection, 
        onEnterContextMode: _enterContextMode,
        onExitContextMode: _exitContextMode,
        onRefresh: () {},
        isGridView: isGridView,
        sortOrder: _currentSortOrder,
      );
    } else {
      return TodoListTab(
        key: _todoTabKey,
        sortOrder: _currentSortOrder,
      );
    }
  }
}
