import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import 'sync_service.dart';

class NoteDatabase {
  static const String _boxName = 'notes';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(NoteAdapter());
    await Hive.openBox<Note>(_boxName);
  }

  static Box<Note> get _box => Hive.box<Note>(_boxName);

  static Future<void> saveNote(Note note, {bool sync = true}) async {
    if (note.isInBox) {
      note.updatedAt = DateTime.now();
      await note.save();
    } else {
      await _box.put(note.id, note);
    }

    if (sync) {
      await SyncService.onNoteSaved(note);
    }
  }

  static Future<List<Note>> getNotes({bool includePrivate = false}) async {
    final notes = _box.values.where((n) => includePrivate || !n.isPrivate).toList();
    notes.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1; 
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }

  static Future<List<Note>> getPrivateNotes() async {
    final notes = _box.values.where((n) => n.isPrivate).toList();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  static Future<List<Note>> searchNotes(String query, {bool includePrivate = false}) async {
    if (query.isEmpty) return getNotes(includePrivate: includePrivate);
    
    final allNotes = _box.values.where((n) => includePrivate || !n.isPrivate).toList();
    final results = allNotes.where((note) {
      final titleMatch = note.title.toLowerCase().contains(query.toLowerCase());
      final contentMatch = note.content.toLowerCase().contains(query.toLowerCase());
      return titleMatch || contentMatch;
    }).toList();

    results.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1; 
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return results;
  }

  static Future<void> deleteNote(String id) async {
    final note = _box.get(id);
    if (note != null) {
      await SyncService.onNoteDeleted(note);
      await _box.delete(id);
    }
  }
}
