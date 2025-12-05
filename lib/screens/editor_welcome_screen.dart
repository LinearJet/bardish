import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/colors.dart';
import '../models/note.dart';
import 'note_editor_screen.dart';

class EditorWelcomeScreen extends StatelessWidget {
  final Note note; // Pass the note to the editor eventually

  const EditorWelcomeScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Title
              Text(
                "Welcome to Editor!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontFamily: 'Serif',
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                "Here you can create:",
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Features List
              _buildFeatureRow(context, Icons.camera_alt_outlined, "Text recognition from photos (OCR)"),
              _buildFeatureRow(context, Icons.mic_none_outlined, "Speech to text conversion"),
              _buildFeatureRow(context, Icons.notifications_none_outlined, "Set reminders for notes"),
              _buildFeatureRow(context, Icons.lock_outline, "Generate secure passwords"),
              _buildFeatureRow(context, Icons.lightbulb_outline, "Ready-made note templates"),
              _buildFeatureRow(context, Icons.format_align_left, "Text formatting"), 

              const Spacer(),
              
              // Start Creating Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    // Set flag
                    final box = Hive.box('settings');
                    await box.put('hasSeenEditorWelcome', true);

                    // Replace current screen with Editor
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              NoteEditorScreen(note: note),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                    shape: const StadiumBorder(), 
                    elevation: 0,
                  ),
                  child: const Text(
                    "Start creating",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
