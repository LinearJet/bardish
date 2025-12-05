import 'package:flutter/material.dart';

class WebLinkForm extends StatefulWidget {
  final Function(String text, String url) onLinkCreated;

  const WebLinkForm({super.key, required this.onLinkCreated});

  @override
  State<WebLinkForm> createState() => _WebLinkFormState();
}

class _WebLinkFormState extends State<WebLinkForm> {
  final _urlController = TextEditingController();
  final _textController = TextEditingController();

  void _submit() {
    final url = _urlController.text.trim();
    final text = _textController.text.trim();
    
    if (url.isNotEmpty) {
      widget.onLinkCreated(text.isEmpty ? url : text, url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com',
              prefixIcon: Icon(Icons.link, color: theme.colorScheme.secondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Display Text (Optional)',
              prefixIcon: Icon(Icons.text_fields, color: theme.colorScheme.secondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Insert Web Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
