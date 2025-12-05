import 'package:flutter/material.dart';
import '../../models/project.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final int noteCount; // Added noteCount
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ProjectCard({
    super.key,
    required this.project,
    required this.noteCount, // Required now
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = theme.hintColor;
    
    final borderColor = isSelected ? const Color(0xFFA48566) : Colors.transparent; 

    // Dynamic subtitle logic
    final String subtitle;
    if (isSelected) {
      subtitle = 'Selected';
    } else if (noteCount == 0) {
      subtitle = 'Empty project';
    } else {
      subtitle = '$noteCount note${noteCount == 1 ? '' : 's'}';
    }

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(project.colorValue),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(project.iconKey),
                color: Colors.white.withOpacity(0.9),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isSelected 
                            ? Icons.check_circle 
                            : (noteCount == 0 ? Icons.not_interested_rounded : Icons.description_outlined),
                        size: 14, 
                        color: isSelected ? const Color(0xFFA48566) : subTextColor
                      ),
                      const SizedBox(width: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? const Color(0xFFA48566) : subTextColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Trailing Icon
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFA48566), size: 24)
            else
              Icon(
                Icons.chevron_right_rounded,
                color: subTextColor.withOpacity(0.5),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String key) {
    switch (key) {
      case 'network': return Icons.account_tree_outlined;
      case 'hub': return Icons.hub_outlined;
      case 'ideas': return Icons.lightbulb_outline;
      case 'favorites': return Icons.star_outline;
      default: return Icons.folder_outlined;
    }
  }
}