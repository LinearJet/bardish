import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../models/note.dart';
import '../services/ai_service.dart';
import '../services/rag_service.dart';

class AiChatDialog extends StatefulWidget {
  final Note? note;
  final List<Note>? contextNotes;
  final Function(String)? onApplyChange;
  final bool allowFullReplacement;

  const AiChatDialog({
    super.key, 
    this.note, 
    this.contextNotes,
    this.onApplyChange,
    this.allowFullReplacement = false,
  });

  @override
  State<AiChatDialog> createState() => _AiChatDialogState();
}

class _AiChatDialogState extends State<AiChatDialog> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  final ScrollController _scrollController = ScrollController();
  
  late Box _settingsBox;
  late AiService _aiService;
  late RagService _ragService;
  
  AiProvider _provider = AiProvider.openai;
  String? _apiKey;
  String? _baseUrl;
  String? _modelName;

  @override
  void initState() {
    super.initState();
    _aiService = AiService();
    _ragService = RagService();
    _loadSettings();
    
    final title = widget.note?.title.isNotEmpty == true ? '"${widget.note!.title}"' : 'this note';
    _messages.add({
      'role': 'assistant',
      'content': 'Hello! Ask me anything about $title.'
          '${widget.onApplyChange != null ? ' I can also help edit or rewrite content.' : ''}',
    });
  }

  void _loadSettings() {
    _settingsBox = Hive.box('settings');
    final providerString = _settingsBox.get('ai_provider', defaultValue: 'openai');
    _provider = AiProvider.values.firstWhere(
      (e) => e.name == providerString,
      orElse: () => AiProvider.openai,
    );
    _apiKey = _settingsBox.get('ai_api_key');
    _baseUrl = _settingsBox.get('ai_base_url');
    _modelName = _settingsBox.get('ai_model');
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text;
    setState(() {
      _messages.add({'role': 'user', 'content': userText});
      _isTyping = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      String contextText = "";
      
      if (widget.note != null) {
        contextText = await _ragService.getRelevantContext(
          widget.note!,
          userText,
          provider: _provider,
          apiKey: _apiKey,
          baseUrl: _baseUrl,
          modelName: _modelName,
        );
      } else if (widget.contextNotes != null) {
         StringBuffer buffer = StringBuffer();
         int totalLen = 0;
         for (var n in widget.contextNotes!) {
           if (totalLen + n.content.length < 20000) {
             buffer.writeln("Note: ${n.title}\n${n.content}\n");
             totalLen += n.content.length;
           } else {
             buffer.writeln("Note: ${n.title}\n(Content too long, skipped)\n");
           }
         }
         contextText = buffer.toString();
      }

      String editInstruction = "";
      if (widget.onApplyChange != null) {
        if (widget.allowFullReplacement) {
          editInstruction = "\n**EDITING MODE:** Use SEARCH/REPLACE blocks to edit. Do NOT rewrite the whole file unless asked.\n"
                            "Format:\n"
                            "<<<<<<< SEARCH\n"
                            "[Exact text to replace]\n"
                            "=======\n"
                            "[New text]\n"
                            ">>>>>>>\n";
        } else {
          editInstruction = "\n**INSERTION MODE:** You are in INSERTION mode. If the user asks to generate text or edit, output only the specific snippet or section they requested in a code block (```). This will be inserted at their cursor position.";
        }
      }

      final List<Map<String, String>> apiMessages = [
        {
          'role': 'system',
          'content': 'You are a helpful assistant for a note-taking app.\n'
                     'Context from the user\'s notes is provided below.\n'
                     '1. **Answering Questions:** If the user asks a specific question about the note\'s content, use the provided context to answer.\n'
                     '2. **Content Generation:** If the user asks you to write, create, or edit content (e.g., "write an essay", "fix grammar", "generate code"), use your general knowledge and capabilities. Do not limit yourself to the context for these tasks.\n'
                     '3. **Empty Context:** If the context is empty, rely entirely on your general knowledge.\n'
                     '$editInstruction\n\n'
                     'Context:\n$contextText'
        },
        ..._messages
      ];

      final response = await _aiService.chat(
        apiMessages,
        _provider,
        apiKey: _apiKey,
        baseUrl: _baseUrl,
        modelName: _modelName,
      );

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': response});
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': 'Error: $e'});
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String? _extractCodeBlock(String content) {
    final RegExp codeBlockRegex = RegExp(r'```[\w]*\n([\s\S]*?)\n```');
    final match = codeBlockRegex.firstMatch(content);
    return match?.group(1);
  }

  String _applyDiffs(String originalContent, String aiResponse) {
    final regex = RegExp(r'<<<<<<< SEARCH\n([\s\S]*?)\n=======\n([\s\S]*?)\n>>>>>>>');
    final matches = regex.allMatches(aiResponse);
    
    if (matches.isEmpty) return originalContent;

    String newContent = originalContent;
    
    // Iterate matches. Note: This simple implementation replaces the *first* occurrence found.
    // A robust implementation would track indices, but this is decent for single-pass edits.
    for (final match in matches) {
      final searchBlock = match.group(1)!.trim();
      final replaceBlock = match.group(2)!.trim();
      
      if (newContent.contains(searchBlock)) {
        newContent = newContent.replaceFirst(searchBlock, replaceBlock);
      } else {
        // If exact match fails, try to be lenient (e.g. ignore whitespace)?
        // For now, just log or ignore. 
        // Maybe we can strip leading/trailing whitespace for better matching.
      }
    }
    return newContent;
  }

  void _handleApply(String content) {
    if (widget.onApplyChange == null) return;

    if (widget.allowFullReplacement) {
      // Check for Search/Replace blocks
      if (content.contains('<<<<<<< SEARCH')) {
        final newContent = _applyDiffs(widget.note?.content ?? "", content);
        if (newContent != (widget.note?.content ?? "")) {
           widget.onApplyChange!(newContent);
           Navigator.pop(context);
           return;
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Could not apply edits. Original text not found.")),
           );
           return;
        }
      }
    }

    // Fallback or Insertion Mode
    final code = _extractCodeBlock(content);
    if (code != null) {
      widget.onApplyChange!(code);
      Navigator.pop(context); 
    } else {
       // Try to use the whole content if no code block?
       // Or just warn?
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("No code block or edit markers found to apply.")),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bubbleColorUser = theme.colorScheme.primary.withOpacity(0.2);
    final bubbleColorAi = theme.colorScheme.surface;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ask AI',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2)),
            
            // Chat Area
            Flexible( 
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                shrinkWrap: true, 
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                     return const Padding(
                       padding: EdgeInsets.all(8.0),
                       child: Align(
                         alignment: Alignment.centerLeft,
                         child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                       ),
                     );
                  }
                  
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  // Detect if we can apply this message
                  bool canApply = !isUser && widget.onApplyChange != null;
                  if (canApply) {
                    if (widget.allowFullReplacement && msg['content']!.contains('<<<<<<< SEARCH')) {
                      // Valid diff block
                    } else if (_extractCodeBlock(msg['content']!) != null) {
                      // Valid code block
                    } else {
                      canApply = false;
                    }
                  }
                  
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                          decoration: BoxDecoration(
                            color: isUser ? bubbleColorUser : bubbleColorAi,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.1),
                            ),
                          ),
                          child: isUser 
                            ? Text(msg['content']!, style: TextStyle(color: theme.colorScheme.onSurface))
                            : MarkdownBody(data: msg['content']!),
                        ),
                        if (canApply)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ElevatedButton.icon(
                              onPressed: () => _handleApply(msg['content']!),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text("Apply Edit"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.secondary,
                                foregroundColor: theme.colorScheme.onSecondary,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Input Area
            Padding(
              padding: const EdgeInsets.only(
                left: 16, 
                right: 16, 
                bottom: 16, 
                top: 8
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null, 
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Ask a question...',
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
