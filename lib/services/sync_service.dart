import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:watcher/watcher.dart';
import '../models/note.dart';
import 'note_database.dart';

class SyncService {
  static String? _syncFolderPath;
  static StreamSubscription? _watcherSubscription;
  static bool _isSyncing = false;
  static final Set<String> _ignoredPaths = {};

  static Future<void> initialize(String? folderPath) async {
    if (folderPath == null || folderPath.isEmpty) return;
    
    _syncFolderPath = folderPath;
    final dir = Directory(folderPath);
    if (!await dir.exists()) return;

    await _performInitialSync(dir);
    _startWatching(folderPath);
  }

  static void updateSyncFolder(String? path) {
    _watcherSubscription?.cancel();
    _syncFolderPath = null;
    initialize(path);
  }

  static void _startWatching(String path) {
    _watcherSubscription?.cancel();
    // Watch for file system events (Modify, Create, Delete)
    final watcher = DirectoryWatcher(path);
    _watcherSubscription = watcher.events.listen((event) async {
      if (_ignoredPaths.contains(event.path)) {
        _ignoredPaths.remove(event.path);
        return;
      }

      if (_isSyncing) return;
      _isSyncing = true;

      try {
        if (event.path.endsWith('.md') || event.path.endsWith('.txt')) {
          if (event.type == ChangeType.ADD || event.type == ChangeType.MODIFY) {
            await _importFile(File(event.path));
          }
        }
      } catch (e) {
        print("Sync Watcher Error: $e");
      } finally {
        _isSyncing = false;
      }
    });
  }

  static Future<void> _performInitialSync(Directory dir) async {
    try {
      final List<FileSystemEntity> entities = await dir.list().toList();
      for (var entity in entities) {
        if (entity is File && (entity.path.endsWith('.md') || entity.path.endsWith('.txt'))) {
          await _importFile(entity);
        }
      }
    } catch (e) {
      print("Sync Init Error: $e");
    }
  }

  static Future<void> _importFile(File file) async {
    try {
      final content = await file.readAsString();
      final filename = file.uri.pathSegments.last;
      
      // Extract title from filename
      String title = filename;
      if (title.contains('.')) {
        title = title.substring(0, title.lastIndexOf('.'));
      }
      title = Uri.decodeComponent(title);

      final notes = await NoteDatabase.getNotes();
      final existingIndex = notes.indexWhere((n) => n.title == title);

      if (existingIndex != -1) {
        // Update existing note if content changed
        final note = notes[existingIndex];
        if (note.content != content) {
          note.content = content;
          note.updatedAt = DateTime.now();
          await NoteDatabase.saveNote(note, sync: false);
        }
      } else {
        // Import as new note
        final newNote = Note()
          ..id = const Uuid().v4()
          ..title = title
          ..content = content
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await NoteDatabase.saveNote(newNote, sync: false);
      }
    } catch (e) {
      print("Import Error: $e");
    }
  }

  // --- Export Logic with Conflict Handling ---
  static Future<void> onNoteSaved(Note note) async {
    if (_syncFolderPath == null) return;
    
    String safeTitle = note.title.isEmpty ? "Untitled" : note.title;
    safeTitle = safeTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_'); 
    
    String filePath = '$_syncFolderPath/$safeTitle.md';
    File file = File(filePath);

    try {
      // 1. If file exists, check if we need to resolve conflict or just update
      if (await file.exists()) {
        final currentContent = await file.readAsString();
        // If content is identical, skip write
        if (currentContent == note.content) return;
      } else {
        // This is a NEW file (or title changed). Check for collisions.
        int counter = 1;
        while (await file.exists()) {
          filePath = '$_syncFolderPath/$safeTitle ($counter).md';
          file = File(filePath);
          counter++;
        }
      }

      _ignoredPaths.add(filePath); // Ignore the event we trigger
      await file.writeAsString(note.content);
    } catch (e) {
      _ignoredPaths.remove(filePath);
      print("Sync Write Error: $e");
    }
  }

  static Future<void> onNoteDeleted(Note note) async {
    if (_syncFolderPath == null) return;
    String safeTitle = note.title.isEmpty ? "Untitled" : note.title;
    safeTitle = safeTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    
    final file = File('$_syncFolderPath/$safeTitle.md');
    if (await file.exists()) {
      _ignoredPaths.add(file.path);
      await file.delete();
    }
  }
}
