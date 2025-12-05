import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/security_service.dart';
import '../services/note_database.dart';
import '../models/note.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';
import 'security_settings_screen.dart';

class PrivateSpaceScreen extends StatefulWidget {
  const PrivateSpaceScreen({super.key});

  @override
  State<PrivateSpaceScreen> createState() => _PrivateSpaceScreenState();
}

class _PrivateSpaceScreenState extends State<PrivateSpaceScreen> {
  final SecurityService _securityService = SecurityService();
  bool _isAuthenticated = false;
  bool _hasPin = false;
  List<Note> _privateNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    // Check if PIN is set at all
    final hasPin = await _securityService.hasPin();
    if (mounted) {
      setState(() {
        _hasPin = hasPin;
      });
    }

    if (!hasPin) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
      return;
    }

    _attemptUnlock();
  }

  Future<void> _attemptUnlock() async {
    bool authenticated = await _securityService.authenticate();
    if (authenticated) {
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
        _loadNotes();
      }
    } else {
      // If biometrics failed or cancelled, show PIN screen (or stay locked with Unlock button)
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showPinDialog() async {
    String enteredPin = '';
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Enter PIN'),
          content: SizedBox(
            width: 200,
            child: TextField(
              autofocus: true,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                counterText: "",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) async {
                enteredPin = value;
                if (value.length == 4) {
                  final isValid = await _securityService.verifyPin(value);
                  if (isValid) {
                    Navigator.pop(context);
                    setState(() {
                      _isAuthenticated = true;
                    });
                    _loadNotes();
                  } else {
                     // Shake or error
                     HapticFeedback.vibrate();
                     // Clear input?
                  }
                }
              },
            ),
          ),
          actions: [
             TextButton(
              onPressed: () => Navigator.of(context).pop(), // Go back effectively
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadNotes() async {
    final notes = await NoteDatabase.getPrivateNotes();
    if (mounted) {
      setState(() {
        _privateNotes = notes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
        title: Text(
          'Private Space',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontFamily: 'Serif',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isAuthenticated)
            IconButton(
              icon: const Icon(Icons.lock_outline),
              onPressed: () {
                setState(() {
                  _isAuthenticated = false;
                  _privateNotes = [];
                });
              },
              tooltip: 'Lock',
            ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _isAuthenticated 
              ? _buildPrivateContent() 
              : _buildLockScreen(),
    );
  }

  Widget _buildLockScreen() {
    final theme = Theme.of(context);
    
    if (!_hasPin) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security_update_warning, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 24),
            Text(
              'Security Setup Required',
              style: TextStyle(fontSize: 20, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'To use Private Space, you must first set up a PIN in Security Settings.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecuritySettingsScreen()),
                );
                _initAuth(); // Re-check after returning from settings
              },
              icon: const Icon(Icons.settings),
              label: const Text('Go to Security Settings'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 64, color: theme.colorScheme.secondary),
          const SizedBox(height: 24),
          Text(
            'Private Space is Locked',
            style: TextStyle(fontSize: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 32),
          FilledButton.tonal(
            onPressed: () async {
               // Check if biometrics available, if so try that, else PIN
               bool bioAvailable = await _securityService.isBiometricsAvailable;
               if (bioAvailable) {
                 _attemptUnlock();
               } else {
                 _showPinDialog();
               }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text('Unlock', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          if (!_isAuthenticated)
            TextButton(
              onPressed: _showPinDialog,
              child: const Text('Use PIN'),
            ),
        ],
      ),
    );
  }

  Widget _buildPrivateContent() {
    if (_privateNotes.isEmpty) {
      return Center(
        child: Text(
          'No private notes yet',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: _privateNotes.length,
      itemBuilder: (context, index) {
        final note = _privateNotes[index];
        return NoteCard(
          note: note,
          isSelected: false,
          onTap: () async {
             await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteEditorScreen(note: note),
                ),
              );
              _loadNotes(); // Refresh after return
          },
          onLongPress: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Remove from Private Space?'),
                content: const Text('This note will be visible in the main list again.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              note.isPrivate = false;
              await note.save();
              _loadNotes();
            }
          },
        );
      },
    );
  }
}
