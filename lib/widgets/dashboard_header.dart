import 'package:flutter/material.dart';
import '../theme/colors.dart';

class DashboardHeader extends StatelessWidget {
  final bool isContextMode;
  final VoidCallback onExitContextMode;
  final String title;
  final bool isGridView;
  final VoidCallback onViewChange;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onNotesMenuPressed; 
  final Function(int)? onSortSelected;

  const DashboardHeader({
    super.key,
    required this.isContextMode,
    required this.onExitContextMode,
    this.title = 'Notes',
    this.isGridView = true,
    required this.onViewChange,
    this.onSettingsPressed,
    this.onNotesMenuPressed,
    this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color;
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title Section with Menu Trigger
          GestureDetector(
            onTap: title == 'Notes' ? onNotesMenuPressed : null,
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Serif',
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                if (title == 'Notes') 
                  Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: Icon(Icons.arrow_drop_down, color: iconColor, size: 20),
                  ),
                // REMOVED: The hardcoded "1 selected" text block was here.
                // The main 'title' variable now handles the count display (e.g. "2 selected").
              ],
            ),
          ),
          
          // Right Side Actions
          Row(
            children: [
              if (isContextMode)
                IconButton(
                  icon: Icon(Icons.close, color: iconColor),
                  onPressed: onExitContextMode,
                )
              else ...[
                PopupMenuButton<int>(
                  icon: Icon(Icons.sort, color: iconColor),
                  onSelected: onSortSelected,
                  color: theme.colorScheme.surface,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0, child: Text('Newest First')),
                    const PopupMenuItem(value: 1, child: Text('Oldest First')),
                    const PopupMenuItem(value: 2, child: Text('Alphabetical')),
                    const PopupMenuItem(value: 3, child: Text('Recently Changed')),
                  ],
                ),
                const SizedBox(width: 12),
                
                IconButton(
                  onPressed: onViewChange,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return RotationTransition(
                        turns: child.key == const ValueKey('grid') 
                            ? Tween<double>(begin: 0.75, end: 1.0).animate(animation)
                            : Tween<double>(begin: 0.75, end: 1.0).animate(animation),
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: isGridView
                        ? Icon(Icons.grid_view, key: const ValueKey('grid'), color: iconColor)
                        : Icon(Icons.view_stream, key: const ValueKey('list'), color: iconColor),
                  ),
                ),
                
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: iconColor),
                  onPressed: onSettingsPressed,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
