import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
import 'option_icon_painter.dart';

enum OptionIconType { note, folder, checklist }

class OptionItem extends StatefulWidget {
  final OptionIconType iconType;
  final String label;
  final ThemeData theme;
  final VoidCallback onTap;

  const OptionItem({
    super.key,
    required this.iconType,
    required this.label,
    required this.theme,
    required this.onTap
  });

  @override
  State<OptionItem> createState() => _OptionItemState();
}

class _OptionItemState extends State<OptionItem> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    // 1. Physical Feedback
    HapticFeedback.mediumImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.theme.colorScheme.primary;
    
    // Resting size 48, Pressed size 60 (The "Shove" Factor)
    final double currentSize = _isPressed ? 60 : 48;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // THE PHYSICS CONTAINER
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            // "easeOutBack" for that rubber-band bounce
            curve: Curves.easeOutBack,
            width: currentSize,
            height: currentSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Subtle background that darkens on press
              color: _isPressed 
                  ? widget.theme.colorScheme.primary.withOpacity(0.15)
                  : Colors.transparent,
            ),
            child: AnimatedRotation(
              // Tilt the icon slightly
              turns: _isPressed ? -0.05 : 0, 
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: AnimatedScale(
                // Zoom the icon
                scale: _isPressed ? 1.1 : 1.0, 
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Center(
                  child: CustomPaint(
                    size: const Size(28, 28),
                    painter: OptionIconPainter(
                      iconType: widget.iconType,
                      color: effectiveColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Text gets out of the way (boldens)
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: effectiveColor,
              fontSize: _isPressed ? 12 : 11,
              fontWeight: _isPressed ? FontWeight.bold : FontWeight.w600,
              letterSpacing: 0.3,
              fontFamily: 'Serif', 
            ),
            child: Text(widget.label),
          ),
        ],
      ),
    );
  }
}