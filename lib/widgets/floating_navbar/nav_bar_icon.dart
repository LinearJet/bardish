import 'package:flutter/material.dart';
import 'nav_icon_painter.dart';

enum NavIconType { notes, checklist }

class NavBarIcon extends StatelessWidget {
  final NavIconType iconType;
  final String label;
  final bool isActive;
  final Color accentColor;
  final ThemeData theme;
  final Animation<double> animation;

  const NavBarIcon({
    super.key,
    required this.iconType,
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.theme,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive
        ? accentColor
        : theme.iconTheme.color?.withOpacity(0.4) ?? Colors.grey;
    final textColor = isActive
        ? accentColor
        : theme.iconTheme.color?.withOpacity(0.5) ?? Colors.grey;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = isActive ? 1.0 + (animation.value * 0.15) : 1.0;

        return Transform.scale(
          scale: scale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  // UPDATED: Uses theme.highlightColor which can be set to matte color
                  color: isActive ? theme.highlightColor : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: CustomPaint(
                  size: const Size(24, 24),
                  painter: NavIconPainter(
                    iconType: iconType,
                    color: iconColor,
                    isActive: isActive,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
