import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../services/note_database.dart';
import '../utils/dashboard_actions.dart';
import '../screens/note_editor_screen.dart';
import '../screens/editor_welcome_screen.dart';
import '../screens/create_todo_dialog.dart';
import '../screens/create_block_dialog.dart';
import 'floating_navbar/floating_navbar.dart';

class DashboardBottomArea extends StatelessWidget {
  final bool isContextMode;
  final DashboardActions actions;
  final int currentIndex;
  final Function(int) onTabChanged;
  final VoidCallback onRefreshNotes;
  final VoidCallback onRefreshTodoList;

  const DashboardBottomArea({
    super.key,
    required this.isContextMode,
    required this.actions,
    required this.currentIndex,
    required this.onTabChanged,
    required this.onRefreshNotes,
    required this.onRefreshTodoList,
  });

  @override
  Widget build(BuildContext context) {
    // Check if all selected notes are pinned
    final bool areAllPinned = actions.selectedNotes.isNotEmpty && 
                              actions.selectedNotes.every((n) => n.isPinned);

    return FloatingNavbar(
      key: const ValueKey('navbar'),
      currentIndex: currentIndex,
      onTabChanged: onTabChanged,
      
      // Context Mode Props
      isContextMode: isContextMode,
      selectedCount: actions.selectedNotes.length,
      areAllPinned: areAllPinned, // Pass state
      onDelete: actions.handleDelete,
      onPin: actions.handlePin,
      onLink: actions.handleLink,
      onMoveToBlock: actions.handleMoveToBlock,
      onCopy: actions.handleCopy,
      onDuplicate: actions.handleDuplicate,
      onEdit: actions.handleEdit,
      onSetColor: actions.handleSetColor,
      onPrivate: actions.handlePrivate,

      // Normal Mode Props
      onAddPressed: () async {
        final newNote = Note()
          ..id = const Uuid().v4()
          ..title = ""
          ..content = ""
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        
        await NoteDatabase.saveNote(newNote);
        
        final settingsBox = Hive.box('settings');
        bool hasSeenWelcome = settingsBox.get('hasSeenEditorWelcome', defaultValue: false);

        if (context.mounted) {
          await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  hasSeenWelcome 
                      ? NoteEditorScreen(note: newNote)
                      : EditorWelcomeScreen(note: newNote),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.ease;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
          onRefreshNotes();
        }
      },
      onBlockPressed: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => const CreateBlockDialog(),
        );
        
        if (result == true) {
          onRefreshNotes();
        }
      },
      onListPressed: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => const CreateTodoDialog(),
        );
        
        if (result == true) {
          onRefreshTodoList();
        }
      },
    );
  }
}
