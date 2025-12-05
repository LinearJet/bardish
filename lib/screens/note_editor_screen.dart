import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../models/note.dart';
import '../services/note_database.dart';
import '../utils/markdown_controller.dart';
import 'link_note/link_note_sheet.dart'; 
import '../widgets/note_editor/editor_bottom_bar.dart';
import '../services/media/media_helper.dart';
import '../utils/markdown_code_builder.dart';
import '../widgets/ai_chat_dialog.dart';
import '../utils/note_templates.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note note;

  const NoteEditorScreen({super.key, required this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final UndoHistoryController _undoController = UndoHistoryController();
  final MediaHelper _mediaHelper = getMediaHelper();
  
  bool _isPreviewMode = false;
  bool _canUndo = false;
  bool _canRedo = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = MarkdownSyntaxTextEditingController(text: widget.note.content);
    
    _undoController.addListener(_handleUndoHistoryChange);
  }

  void _handleUndoHistoryChange() {
    if (mounted) {
      setState(() {
        _canUndo = _undoController.value.canUndo;
        _canRedo = _undoController.value.canRedo;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _undoController.removeListener(_handleUndoHistoryChange);
    _undoController.dispose();
    _mediaHelper.stopListening(); 
    super.dispose();
  }

  void _saveNote() {
    widget.note.title = _titleController.text.trim();
    widget.note.content = _contentController.text;
    widget.note.updatedAt = DateTime.now();
    NoteDatabase.saveNote(widget.note);
  }

  Color _getTextColor(ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      return theme.colorScheme.onSurface;
    } else {
      return theme.colorScheme.onSurface.computeLuminance() > 0.5
          ? Colors.black87
          : theme.colorScheme.onSurface;
    }
  }

  Color _getHintColor(ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      return theme.hintColor;
    } else {
      return Colors.black54;
    }
  }

  Future<void> _openLinkSheet() async {
    final String? linkText = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LinkNoteSheet(),
    );

    if (linkText != null) {
      _insertText(linkText);
    }
  }

  void _insertText(String text) {
    final selection = _contentController.selection;
    final currentText = _contentController.text;
    
    final start = selection.start >= 0 ? selection.start : currentText.length;
    final end = selection.end >= 0 ? selection.end : currentText.length;

    final newText = currentText.replaceRange(start, end, text);
    
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + text.length),
    );
  }

  // --- MEDIA HANDLERS ---

  Future<void> _handleOcr() async {
    final text = await _mediaHelper.pickImageAndExtractText();
    if (text != null && text.isNotEmpty) {
      _insertText(text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Text extracted from image")),
        );
      }
    }
  }

  Future<void> _handleImage() async {
    final imageMarkdown = await _mediaHelper.pickImage();
    if (imageMarkdown != null) {
      _insertText('\n$imageMarkdown\n');
    }
  }

  Future<void> _toggleMic() async {
    if (_isRecording) {
      await _mediaHelper.stopListening();
      setState(() => _isRecording = false);
    } else {
      await _mediaHelper.startListening(
        onResult: (text) {
          _insertText(" $text");
        },
        onStateChanged: (isListening) {
          if (mounted) setState(() => _isRecording = isListening);
        }
      );
    }
  }

  String _processForDisplay(String text) {
    String processed = text.replaceAll(RegExp(r'^\[ \]', multiLine: true), '- [ ]');
    processed = processed.replaceAll(RegExp(r'^\[x\]', multiLine: true), '- [x]');
    processed = processed.replaceAll('\n', '  \n');
    return processed;
  }

  void _showTemplatesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Choose a Template',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: NoteTemplates.all.length,
                    itemBuilder: (context, index) {
                      final template = NoteTemplates.all[index];
                      return ListTile(
                        leading: Icon(Icons.description_outlined, color: theme.colorScheme.secondary),
                        title: Text(template.name),
                        onTap: () {
                          Navigator.pop(context);
                          _applyTemplate(template);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _applyTemplate(NoteTemplate template) {
    if (_contentController.text.trim().isNotEmpty) {
      // Confirm overwrite or append
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Apply Template?'),
          content: const Text('This note is not empty. Do you want to append the template or replace existing content?'),
          actions: [
             TextButton(
              onPressed: () {
                Navigator.pop(context); // Cancel
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _insertText('\n\n${template.content}');
              },
              child: const Text('Append'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (_titleController.text.isEmpty || _titleController.text == 'Untitled') {
                   _titleController.text = template.name; // Auto-set title if empty
                }
                _contentController.text = template.content;
              },
              child: const Text('Replace', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      // Empty note, just apply
      if (_titleController.text.isEmpty || _titleController.text == 'Untitled') {
         _titleController.text = template.name;
      }
      _contentController.text = template.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = _getTextColor(theme);
    final hintColor = _getHintColor(theme);
    
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        _saveNote();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _titleController.text.isEmpty ? 'Untitled' : _titleController.text,
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          leading: _ExpressiveIconBtn(
            icon: Icons.arrow_back,
            color: theme.colorScheme.primary,
            onTap: () {
              _saveNote();
              Navigator.pop(context);
            },
          ),
          actions: [
            _ExpressiveIconBtn(
              icon: Icons.smart_toy_outlined,
              color: theme.colorScheme.secondary,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => AiChatDialog(
                    note: widget.note,
                    allowFullReplacement: false, // Explicitly insertion mode
                    onApplyChange: (newText) {
                      _insertText(newText);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Text applied at cursor")),
                      );
                    },
                  ),
                );
              },
            ),
            _ExpressiveIconBtn(
              icon: Icons.undo,
              color: _canUndo ? theme.colorScheme.primary : theme.disabledColor,
              onTap: _canUndo ? _undoController.undo : null,
            ),
            _ExpressiveIconBtn(
              icon: Icons.redo,
              color: _canRedo ? theme.colorScheme.primary : theme.disabledColor,
              onTap: _canRedo ? _undoController.redo : null,
            ),
            _ExpressiveIconBtn(
              icon: _isPreviewMode ? Icons.edit_outlined : Icons.remove_red_eye_outlined,
              color: theme.colorScheme.primary,
              onTap: () => setState(() => _isPreviewMode = !_isPreviewMode),
            ),
            _ExpressiveIconBtn(
              icon: Icons.check,
              color: theme.colorScheme.secondary,
              onTap: () {
                _saveNote();
                Navigator.pop(context);
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      onChanged: (val) { if (mounted) setState(() {}); },
                      style: TextStyle(
                        fontSize: 32,
                        fontFamily: 'Serif',
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Serif',
                        ),
                        border: InputBorder.none,
                      ),
                    ),
      
                    const SizedBox(height: 8),
      
                    Expanded(
                      child: _isPreviewMode 
                        ? Markdown(
                            data: _processForDisplay(_contentController.text),
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(color: textColor, fontSize: 16, height: 1.5),
                              h1: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
                              h2: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                              strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                              em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
                              checkbox: TextStyle(color: theme.colorScheme.secondary),
                            ),
                            builders: {
                              'code': CodeElementBuilder(context), // Enable copy in preview
                            },
                          )
                        : TextField(
                            controller: _contentController,
                            undoController: _undoController,
                            maxLines: null,
                            expands: true,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: textColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Write something...',
                              hintStyle: TextStyle(color: hintColor),
                              border: InputBorder.none,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (!_isPreviewMode)
              EditorBottomBar(
                isRecording: _isRecording,
                onBold: () => _insertText('**Bold**'),
                onItalic: () => _insertText('*Italic*'),
                onLink: _openLinkSheet,
                onCheckbox: () => _insertText('- [ ] '),
                onMic: _toggleMic,
                onOcr: _handleOcr,
                onImage: _handleImage,
                onCode: () => _insertText('```\n\n```'),
                onQuote: () => _insertText('> '),
                onTemplate: _showTemplatesSheet,
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpressiveIconBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ExpressiveIconBtn({required this.icon, required this.color, required this.onTap});

  @override
  State<_ExpressiveIconBtn> createState() => _ExpressiveIconBtnState();
}

class _ExpressiveIconBtnState extends State<_ExpressiveIconBtn> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) {
      return Icon(widget.icon, color: widget.color.withOpacity(0.3));
    }

    final double scale = _isPressed ? 0.8 : 1.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap!();
      },
      onTapDown: (_) {
        HapticFeedback.mediumImpact();
        if (mounted) setState(() => _isPressed = true);
      },
      onTapCancel: () { if (mounted) setState(() => _isPressed = false); },
      onTapUp: (_) { if (mounted) setState(() => _isPressed = false); },
      child: Container(
        width: 48,
        height: 48,
        color: Colors.transparent, 
        alignment: Alignment.center,
        child: AnimatedScale(
          scale: scale, 
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: Icon(widget.icon, color: widget.color),
        ),
      ),
    );
  }
}
