import 'package:flutter/material.dart';

class NewNoteLinkForm extends StatefulWidget {
  final Function(String title) onNewNoteLink;

  const NewNoteLinkForm({super.key, required this.onNewNoteLink});

  @override
  State<NewNoteLinkForm> createState() => _NewNoteLinkFormState();
}

class _NewNoteLinkFormState extends State<NewNoteLinkForm> {
  final _titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Create a link to a new note. The note will be created when you click the link.",
            style: TextStyle(color: theme.hintColor, height: 1.5),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'New Note Title',
              prefixIcon: Icon(Icons.note_add_outlined, color: theme.colorScheme.secondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) widget.onNewNoteLink(val);
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_titleController.text.trim().isNotEmpty) {
                  widget.onNewNoteLink(_titleController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Insert Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
