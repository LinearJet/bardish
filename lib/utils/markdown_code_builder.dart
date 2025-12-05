import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

class CodeElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;

  CodeElementBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Explicit styling to match the aesthetic
    final bgColor = isDark ? const Color(0xFF353230) : Colors.grey.shade200;
    final textColor = isDark ? const Color(0xFFE9E9E9) : Colors.black87;

    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 12),
                const Text('Code copied', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
            backgroundColor: theme.colorScheme.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'monospace',
            color: textColor,
            fontSize: (preferredStyle?.fontSize ?? 14) * 0.9,
          ),
        ),
      ),
    );
  }
}
