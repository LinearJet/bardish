import 'package:flutter/material.dart';

import '../models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note; // Use the model directly for convenience if preferred, but mapped fields are better for separation. 
  // However, to fix the error quickly, we should probably keep mapped fields OR accept the object.
  // The error says: No named parameter with the name 'note'.
  // So the calling code IS passing 'note: note'.
  // We should update NoteCard to accept 'note' and extract fields itself, OR update calling code.
  // Given 'NoteCard' is likely used in many places, updating it to accept 'note' as an alternative or primary is good.
  // Let's switch to taking the Note object since that's what the caller expects.

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isPinnedHighlight; 

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isPinnedHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.secondary;
    final title = note.title;
    final content = note.content;
    // Format date manually or use intl
    final date = "${note.updatedAt.day}/${note.updatedAt.month}"; 
    final isPinned = note.isPinned;
    final colorValue = note.colorValue;

    // Background Color Logic
    Color backgroundColor = colorValue != null ? Color(colorValue) : theme.colorScheme.surface;
    
    if (isSelected) {
      backgroundColor = Color.alphaBlend(accentColor.withOpacity(0.15), backgroundColor);
    } else if (isPinnedHighlight && colorValue == null) {
      // Subtle highlight for pinned notes in default color mode (mimics screenshot)
      backgroundColor = Color.alphaBlend(accentColor.withOpacity(0.05), backgroundColor);
    }

    // Text Color Logic
    final bool isDarkBg = ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark;
    final Color textColor = isDarkBg ? Colors.white : Colors.black87;
    final Color secondaryTextColor = isDarkBg ? Colors.white70 : Colors.black54;

    // Border Logic
    Color borderColor;
    double borderWidth;

    if (isSelected) {
      borderColor = accentColor;
      borderWidth = 2.0;
    } else if (isPinnedHighlight) {
      // Subtle border for pinned items
      borderColor = accentColor.withOpacity(0.3);
      borderWidth = 1.0;
    } else {
      borderColor = colorValue != null ? Colors.transparent : theme.dividerColor.withOpacity(0.1);
      borderWidth = 1.0;
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        clipBehavior: Clip.none, // Allow checkmark to pop out slightly if needed
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20), // Slightly rounder corners like screenshot
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.25),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Date & Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        color: secondaryTextColor.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (isPinned)
                      Icon(
                        Icons.bookmark, // Changed to Bookmark to match screenshot style
                        size: 16,
                        color: secondaryTextColor.withOpacity(0.5),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8), // Tighter spacing for landscape aspect

                // Title
                if (title.isNotEmpty) ...[
                  Text(
                    title,
                    maxLines: 2, // Allow 2 lines for title
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Serif',
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4), // Tighter spacing
                ],

                // Content Summary
                Expanded(
                  child: Text(
                    content.isEmpty ? "..." : content.toUpperCase(), // Uppercase for style if desired
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 11,
                      height: 1.4,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Checkmark Overlay - Moved slightly inward to avoid clipping
          if (isSelected)
            Positioned(
              bottom: 8, // Moved up from edge
              right: 8,  // Moved left from edge
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: backgroundColor, width: 2), // Ring effect
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4)
                  ]
                ),
                child: Icon(
                  Icons.check,
                  size: 12,
                  color: theme.colorScheme.onSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}