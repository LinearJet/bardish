import 'package:flutter/material.dart';

class MarkdownSyntaxTextEditingController extends TextEditingController {
  MarkdownSyntaxTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> children = [];
    final String text = value.text;
    
    if (text.isEmpty) {
      return TextSpan(style: style, text: text);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Define colors
    final headingColor = isDark ? const Color(0xFFE6E1E5) : theme.colorScheme.primary;
    final boldColor = isDark ? const Color(0xFFFFDDB3) : theme.colorScheme.secondary; 
    final italicColor = isDark ? const Color(0xFFD0BCFF) : (theme.colorScheme.tertiary ?? Colors.blueAccent);
    final linkColor = theme.colorScheme.secondary; // Color for [[Links]]

    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final headingMatch = RegExp(r'^(#{1,6})\s+(.*)').firstMatch(line);
      
      final lineTerminator = (i < lines.length - 1 ? '\n' : '');

      if (headingMatch != null) {
        children.add(TextSpan(
          text: line + lineTerminator,
          style: style?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: (style.fontSize ?? 16) * 1.5,
            color: headingColor,
          ),
        ));
      } else {
        children.add(_parseInlineStyles(
          line + lineTerminator, 
          style, 
          boldColor, 
          italicColor,
          linkColor
        ));
      }
    }

    return TextSpan(style: style, children: children);
  }

  TextSpan _parseInlineStyles(
    String text, 
    TextStyle? baseStyle, 
    Color boldColor, 
    Color italicColor, 
    Color linkColor
  ) {
    final List<TextSpan> spans = [];
    
    // Added [[...]] to regex
    final pattern = RegExp(r'(\*\*.*?\*\*)|(\*.*?\*)|(\[\[.*?\]\])');
    
    int currentIndex = 0;
    
    for (final match in pattern.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }
      
      final fullMatch = match.group(0)!;
      
      if (fullMatch.startsWith('[[')) {
        // Obsidian Link Style
        spans.add(TextSpan(
          text: fullMatch,
          style: baseStyle?.copyWith(
            color: linkColor,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
            decorationColor: linkColor.withOpacity(0.5),
          ),
        ));
      } else if (fullMatch.startsWith('**')) {
        // Bold
        spans.add(TextSpan(
          text: fullMatch,
          style: baseStyle?.copyWith(
            fontWeight: FontWeight.bold, 
            color: boldColor,
          ),
        ));
      } else {
        // Italic
        spans.add(TextSpan(
          text: fullMatch,
          style: baseStyle?.copyWith(
            fontStyle: FontStyle.italic, 
            color: italicColor,
          ),
        ));
      }
      
      currentIndex = match.end;
    }
    
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }
    
    return TextSpan(style: baseStyle, children: spans);
  }
}
