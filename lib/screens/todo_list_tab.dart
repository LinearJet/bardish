import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart'; 
import '../models/todo.dart';
import '../models/note.dart'; 
import '../services/todo_database.dart';
import '../services/note_database.dart'; 
import '../widgets/todo_card.dart';
import 'create_todo_dialog.dart';

class TodoListTab extends StatefulWidget {
  final int sortOrder; // 0: Newest, 1: Oldest, 2: Alphabetical, 3: Recently Changed

  const TodoListTab({super.key, this.sortOrder = 0});

  @override
  State<TodoListTab> createState() => TodoListTabState();
}

class TodoListTabState extends State<TodoListTab> with SingleTickerProviderStateMixin {
  bool _hasStarted = false;
  final Box _settingsBox = Hive.box('settings');
  List<TodoList> _todoLists = [];
  bool _isLoading = true;

  // Animation Controllers
  late AnimationController _welcomeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _hasStarted = _settingsBox.get('hasStartedTodoList', defaultValue: false);
    
    // Initialize Animation
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Slide from bottom-ish to top-ish
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), 
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _welcomeController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    if (!_hasStarted) {
      _welcomeController.forward();
    }

    loadTodoLists();
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TodoListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortOrder != widget.sortOrder) {
      _sortLists();
    }
  }

  void _sortLists() {
    setState(() {
      switch (widget.sortOrder) {
        case 0: // Newest Created
          _todoLists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 1: // Oldest Created
          _todoLists.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case 2: // Alphabetical
          _todoLists.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          break;
        case 3: // Recently Changed
          _todoLists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          break;
      }
    });
  }

  Future<void> loadTodoLists() async {
    setState(() => _isLoading = true);
    final lists = await TodoDatabase.getTodoLists();
    if (mounted) {
      setState(() {
        _todoLists = lists;
        _isLoading = false;
      });
      _sortLists(); 
    }
  }

  void _onStartOrganizing() async {
    await _settingsBox.put('hasStartedTodoList', true);
    setState(() {
      _hasStarted = true;
    });
    _showCreateDialog();
  }

  Future<void> _showCreateDialog({TodoList? existingList}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateTodoDialog(existingList: existingList),
    );

    if (result == true) {
      loadTodoLists();
    }
  }

  Future<void> _convertListToNote(TodoList list) async {
    final StringBuffer contentBuffer = StringBuffer();
    for (var task in list.tasks) {
      final checkbox = task.isCompleted ? "[x]" : "[ ]";
      contentBuffer.writeln("- $checkbox ${task.text}");
    }

    final newNote = Note()
      ..id = const Uuid().v4()
      ..title = list.title
      ..content = contentBuffer.toString()
      ..createdAt = list.createdAt
      ..updatedAt = DateTime.now();

    await NoteDatabase.saveNote(newNote);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Converted to Note'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (!_hasStarted) return _buildWelcomeState(theme);
    if (_todoLists.isEmpty) return _buildEmptyState(theme);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final todoList = _todoLists[index];
                return TodoCard(
                  todoList: todoList,
                  onDelete: () async {
                    await TodoDatabase.deleteTodoList(todoList.id);
                    loadTodoLists();
                  },
                  onEdit: () {
                    _showCreateDialog(existingList: todoList);
                  },
                  onCreateNote: () {
                    _convertListToNote(todoList);
                  },
                );
              },
              childCount: _todoLists.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildWelcomeState(ThemeData theme) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            // UPDATED: Used Padding instead of Centered Container to push it to top
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // Align to top
              children: [
                const SizedBox(height: 40), // Top spacing to position it "more towards the top"
                
                // Icon Circle
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.playlist_add, 
                    size: 36, 
                    color: theme.colorScheme.secondary
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  "Welcome to To-Do Lists!",
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold, 
                    color: theme.colorScheme.primary, 
                    fontFamily: 'Serif'
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  "Brief overview of features:",
                  style: TextStyle(
                    fontSize: 13, 
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Feature List
                _buildFeatureRow(theme, Icons.tune, "Customize completed tasks display"),
                _buildFeatureRow(theme, Icons.palette_outlined, "Color labels for organizing lists"),
                _buildFeatureRow(theme, Icons.note_alt_outlined, "Convert lists to notes with one tap"),
                _buildFeatureRow(theme, Icons.sort, "Convenient sorting by date and changes"),

                const SizedBox(height: 40),
                
                // Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _onStartOrganizing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      "Start organizing", 
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)
                    ),
                  ),
                ),
                
                // Bottom spacer to ensure scrolling if screen is short
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.playlist_add_check, size: 64, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text("No lists yet", style: TextStyle(color: theme.disabledColor)),
        ],
      ),
    );
  }
}
