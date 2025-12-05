import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'view_mode_sheet.dart';
import '../../utils/markdown_code_builder.dart';

class NoteViewContent extends StatelessWidget {
  final String content;
  final ViewMode viewMode;
  final double fontSize;
  final ScrollController? scrollController;
  final PageController? pageController;
  final List<String> pages;
  final Function(int)? onPageChanged;
  final String searchQuery;
  final List<int> searchPositions;
  final Function(String)? onLinkTap;

  const NoteViewContent({
    super.key,
    required this.content,
    required this.viewMode,
    required this.fontSize,
    this.scrollController,
    this.pageController,
    this.pages = const [],
    this.onPageChanged,
    this.searchQuery = '',
    this.searchPositions = const [],
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (viewMode) {
      case ViewMode.vertical:
      case ViewMode.autoScroll:
        return _buildVerticalView(context);
      case ViewMode.horizontal:
      case ViewMode.autoFlip:
        return _buildHorizontalView(context);
    }
  }

  Widget _buildVerticalView(BuildContext context) {
    final theme = Theme.of(context);
    final processedContent = _processContent(content);
    
    return Markdown(
      controller: scrollController,
      data: processedContent,
      padding: const EdgeInsets.only(bottom: 120),
      physics: const BouncingScrollPhysics(),
      styleSheet: _buildStyleSheet(theme),
      selectable: true, // Enable text selection
      builders: {
        'code': CodeElementBuilder(context),
      },
      onTapLink: (text, href, title) {
        if (href != null && href.startsWith('note://')) {
          final noteTitle = Uri.decodeComponent(href.replaceFirst('note://', ''));
          onLinkTap?.call(noteTitle);
        }
      },
    );
  }

  Widget _buildHorizontalView(BuildContext context) {
    final theme = Theme.of(context);
    
    if (pages.isEmpty) {
      return _buildVerticalView(context);
    }

    return PageView.builder(
      controller: pageController,
      itemCount: pages.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        final processedContent = _processContent(pages[index]);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          physics: const BouncingScrollPhysics(),
          child: MarkdownBody(
            data: processedContent,
            styleSheet: _buildStyleSheet(theme),
            selectable: true,
            builders: {
              'code': CodeElementBuilder(context),
            },
            onTapLink: (text, href, title) {
              if (href != null && href.startsWith('note://')) {
                final noteTitle = Uri.decodeComponent(href.replaceFirst('note://', ''));
                onLinkTap?.call(noteTitle);
              }
            },
          ),
        );
      },
    );
  }

  // Pre-process content to fix layout and handle links
  String _processContent(String rawText) {
    String processed = rawText;

    // 1. Fix Checkboxes: Convert "[ ] " to "- [ ] " (Markdown task list)
    processed = processed.replaceAll(RegExp(r'^\[ \]', multiLine: true), '- [ ]');
    processed = processed.replaceAll(RegExp(r'^\[x\]', multiLine: true), '- [x]');

    // 2. Force Line Breaks
    processed = processed.replaceAll('\n', '  \n');
    
    // 3. Highlight search terms
    if (searchQuery.isNotEmpty && searchPositions.isNotEmpty) {
      final regex = RegExp(RegExp.escape(searchQuery), caseSensitive: false);
      processed = processed.replaceAllMapped(regex, (match) {
        return '**${match.group(0)}**'; 
      });
    }

    // 4. Convert [[Link]] to [Link](note://Link)
    final wikiLinkRegex = RegExp(r'\[\[(.*?)\]\]');
    processed = processed.replaceAllMapped(wikiLinkRegex, (match) {
      final linkText = match.group(1) ?? '';
      return '[$linkText](note://${Uri.encodeComponent(linkText)})';
    });

    return processed;
  }

  MarkdownStyleSheet _buildStyleSheet(ThemeData theme) {
    return MarkdownStyleSheet(
      p: TextStyle(
        color: theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface,
        fontSize: fontSize,
        height: 1.6,
      ),
      h1: TextStyle(
        color: theme.colorScheme.primary,
        fontSize: fontSize + 8,
        fontWeight: FontWeight.bold,
      ),
      h2: TextStyle(
        color: theme.colorScheme.primary,
        fontSize: fontSize + 6,
        fontWeight: FontWeight.bold,
      ),
      h3: TextStyle(
        color: theme.colorScheme.primary,
        fontSize: fontSize + 4,
        fontWeight: FontWeight.bold,
      ),
      strong: TextStyle(
        color: searchQuery.isNotEmpty 
            ? theme.colorScheme.secondary  
            : theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
        backgroundColor: searchQuery.isNotEmpty
            ? theme.colorScheme.secondary.withOpacity(0.2)
            : null,
      ),
      em: TextStyle(
        fontStyle: FontStyle.italic,
        color: theme.colorScheme.secondary,
        fontSize: fontSize,
      ),
      a: TextStyle( 
        color: theme.colorScheme.secondary,
        decoration: TextDecoration.underline,
        decorationColor: theme.colorScheme.secondary.withOpacity(0.5),
        fontWeight: FontWeight.w600,
      ),
      blockquote: TextStyle(
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
        fontStyle: FontStyle.italic,
        fontSize: fontSize - 1,
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: theme.colorScheme.secondary, width: 4),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // Styling for blocks of code (not inline)
      code: TextStyle(
        fontFamily: 'monospace',
        color: theme.colorScheme.onSurface,
        backgroundColor: theme.colorScheme.surface,
        fontSize: fontSize - 2,
      ),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      listBullet: TextStyle(
        color: theme.colorScheme.secondary,
        fontSize: fontSize,
      ),
      checkbox: TextStyle(
        color: theme.colorScheme.secondary,
        fontSize: fontSize, 
      ),
    );
  }
}
