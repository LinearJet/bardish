import 'package:flutter/material.dart';

class NoteColorPicker extends StatelessWidget {
  final Function(int? colorValue) onColorSelected;

  const NoteColorPicker({super.key, required this.onColorSelected});

  // Palette colors
  static const List<Color> colors = [
    Color(0xFFFFFFFF), // White (Default/None)
    Color(0xFFFAAFA8), // Light Red
    Color(0xFFF39F76), // Orange
    Color(0xFFFFF8B8), // Yellow
    Color(0xFFE2F6D3), // Green
    Color(0xFFB4DDD3), // Teal
    Color(0xFFD4E4ED), // Blue
    Color(0xFFAECCDC), // Dark Blue
    Color(0xFFD3BFDB), // Purple
    Color(0xFFF6E2DD), // Pink
    Color(0xFFE9E3D4), // Beige
    Color(0xFFEFEFF1), // Grey
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Note Color',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Serif',
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              // 'None' Option (Default Theme Color)
              _ColorCircle(
                color: isDark ? const Color(0xFF262321) : Colors.white,
                isNone: true,
                onTap: () => onColorSelected(null),
                theme: theme,
              ),
              // Color Options
              ...colors.skip(1).map((color) => _ColorCircle(
                color: color, 
                onTap: () => onColorSelected(color.value),
                theme: theme,
              )),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isNone;
  final VoidCallback onTap;
  final ThemeData theme;

  const _ColorCircle({
    required this.color,
    this.isNone = false,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.dividerColor.withOpacity(isNone ? 0.2 : 0.0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isNone 
            ? Icon(Icons.format_color_reset_outlined, size: 20, color: theme.hintColor)
            : null,
      ),
    );
  }
}
