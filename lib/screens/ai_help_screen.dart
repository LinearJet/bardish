import 'package:flutter/material.dart';

class AiHelpScreen extends StatelessWidget {
  const AiHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("How to use AI"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            context, 
            "Asking Questions",
            "Tap the robot icon (🤖) in the top bar of any note. You can ask general questions or specific questions about the note's content. The AI uses 'Retrieval Augmented Generation' (RAG) to read your note.",
            Icons.question_answer_outlined,
          ),
          _buildSection(
            context,
            "Editing Notes", 
            "To edit a note with AI, tap the robot icon and give an instruction like 'Summarize this' or 'Fix grammar'.\n\n"
            "• If you are in **View Mode**, the AI will rewrite the entire note. You can then tap 'Apply Edit' to replace the current content.\n"
            "• If you are in **Edit Mode**, the AI will provide a snippet. Tapping 'Apply Edit' will insert it at your cursor position.",
            Icons.edit_note_rounded,
          ),
          _buildSection(
            context,
            "Project Graph Chat",
            "In the Project Graph view, tapping the 'Ask AI' button allows you to ask questions across *all* notes in that project. The AI will try to find relevant information from multiple notes to answer you.",
            Icons.hub_outlined,
          ),
          _buildSection(
            context,
            "Speech to Text",
            "In the editor, tap the microphone icon to dictate text directly into your note.",
            Icons.mic_none_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
