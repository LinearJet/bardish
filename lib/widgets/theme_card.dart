import 'package:flutter/material.dart';

class ThemeCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final Color? color;
  final BoxDecoration? decoration;
  final Color textColor;
  final VoidCallback onTap;

  const ThemeCard({
    super.key,
    required this.label,
    required this.value,
    required this.isSelected,
    this.color,
    this.decoration,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final BoxDecoration effectiveDecoration = decoration ?? BoxDecoration(color: color);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: effectiveDecoration.copyWith(
          borderRadius: BorderRadius.circular(16),
          border: isSelected 
              ? Border.all(color: theme.colorScheme.secondary, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Serif',
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: theme.colorScheme.secondary,
                  child: Icon(Icons.check, size: 14, color: theme.colorScheme.onSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
