import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../models/project.dart';
import '../services/note_database.dart';
import '../services/project_database.dart';
import '../screens/note_editor_screen.dart';
import '../theme/colors.dart';
import '../widgets/move_to_block_dialog.dart';
import '../widgets/note_color_picker.dart';
// Import the new dialog
import '../widgets/project_selection_dialog.dart';
import '../services/security_service.dart';
import '../screens/security_settings_screen.dart';

class DashboardActions {
  final BuildContext context;
  final List<Note> selectedNotes;
  final VoidCallback onExit;
  final VoidCallback onRefresh;

  DashboardActions({
    required this.context,
    required this.selectedNotes,
    required this.onExit,
    required this.onRefresh,
  });

  // ... (handleDelete, handleDuplicate, handleEdit, handlePin, handleMoveToBlock, handleSetColor, handleCopy UNCHANGED) ...
  Future<void> handleDelete() async {
      if (selectedNotes.isEmpty) return;
      
      final count = selectedNotes.length;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);
          return AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Delete ${count > 1 ? "$count Notes" : "Note"}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontFamily: 'Serif',
                fontSize: 20,
              ),
            ),
            content: Text(
              'Are you sure you want to delete selected items? This action cannot be undone.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        for (var note in selectedNotes) {
          await NoteDatabase.deleteNote(note.id);
        }
        onExit();
        onRefresh();
      }
    }

  Future<void> handleDuplicate() async {
    if (selectedNotes.length != 1) return; 

    final note = selectedNotes.first;
    final duplicatedNote = Note()
      ..id = const Uuid().v4()
      ..title = "${note.title} (Copy)"
      ..content = note.content
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..blockId = note.blockId
      ..isPinned = note.isPinned
      ..colorValue = note.colorValue
      ..projectId = note.projectId;

    await NoteDatabase.saveNote(duplicatedNote);
    onExit();
    onRefresh();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Note duplicated'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void handleEdit() {
    if (selectedNotes.length != 1) return;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NoteEditorScreen(note: selectedNotes.first),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) {
      onExit();
      onRefresh();
    });
  }

  Future<void> handlePin() async {
    if (selectedNotes.isEmpty) return;

    bool allPinned = selectedNotes.every((n) => n.isPinned);
    bool newState = !allPinned;

    for (var note in selectedNotes) {
      note.isPinned = newState;
      await note.save();
    }
    
    onExit();
    onRefresh();
  }

  Future<void> handleMoveToBlock() async {
    if (selectedNotes.isEmpty) return;

    final blockId = await showDialog<String?>(
      context: context,
      builder: (context) => MoveToBlockDialog(onBlockSelected: () {}),
    );
    
    if (blockId != null) {
      final targetId = blockId.isEmpty ? null : blockId;
      for (var note in selectedNotes) {
        note.blockId = targetId;
        await note.save();
      }
      
      onExit();
      onRefresh();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(targetId == null ? 'Moved to Others' : 'Moved to block'),
            backgroundColor: Theme.of(context).colorScheme.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void handleCopy() {
    onExit();
    _showComingSoonSnackbar('Copy feature coming soon');
  }

  void handleSetColor() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteColorPicker(
        onColorSelected: (colorValue) async {
          Navigator.pop(context);
          for (var note in selectedNotes) {
            note.colorValue = colorValue;
            await note.save();
          }
          onExit();
          onRefresh();
        },
      ),
    );
  }

  // --- UPDATED: handleLink with Custom Dialog ---
  Future<void> handleLink() async {
    if (selectedNotes.isEmpty) return;

    // Open the new ProjectSelectionDialog
    final Project? selectedProject = await showDialog<Project>(
      context: context,
      builder: (context) => const ProjectSelectionDialog(),
    );

    if (selectedProject != null) {
      // Assign project ID to notes
      for (var note in selectedNotes) {
        note.projectId = selectedProject.id;
        await note.save();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Linked ${selectedNotes.length} note(s) to "${selectedProject.name}"'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    
    // Always exit selection mode after action
    onExit();
    onRefresh();
  }

  Future<void> handlePrivate() async {
    if (selectedNotes.isEmpty) return;

    final securityService = SecurityService();
    final hasPin = await securityService.hasPin();

    if (!context.mounted) return;

    if (!hasPin) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Setup Security'),
          content: const Text('You need to set up a PIN to use Private Space.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecuritySettingsScreen()),
                );
              },
              child: const Text('Setup'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Private Space'),
        content: Text('Move ${selectedNotes.length} note(s) to Private Space? They will be hidden from the main view.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Move'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (var note in selectedNotes) {
        note.isPrivate = true;
        await note.save();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes moved to Private Space')),
        );
      }
      onExit();
      onRefresh();
    }
  }

  void _showComingSoonSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BardishColors.surface,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}