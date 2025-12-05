import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for Haptics

class ProjectSelectionBar extends StatefulWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onExport;
  final VoidCallback? onDelete;
  
  const ProjectSelectionBar({
    super.key,
    this.onEdit,
    this.onExport,
    this.onDelete,
  });

  @override
  State<ProjectSelectionBar> createState() => _ProjectSelectionBarState();
}

class _ProjectSelectionBarState extends State<ProjectSelectionBar> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.cardColor;
    
    return Container(
      key: const ValueKey('selectionBar'),
      height: 125, // Increased height slightly to accommodate the bouncy growth
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        // Aligns items to the center so they push outwards evenly
        crossAxisAlignment: CrossAxisAlignment.center, 
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: _ActionButton(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: widget.onEdit,
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: _ActionButton(
              icon: Icons.file_download_outlined,
              label: 'Export',
              onTap: widget.onExport,
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: _ActionButton(
              icon: Icons.delete_outline,
              label: 'Delete',
              isDestructive: true,
              onTap: widget.onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;
  
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      // 1. Physical Feedback
      HapticFeedback.mediumImpact(); 
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      // Light feedback on release
      HapticFeedback.lightImpact();
      setState(() => _isPressed = false);
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.onTap == null 
        ? theme.disabledColor 
        : (widget.isDestructive ? Colors.redAccent : theme.colorScheme.onSurface);
    
    // Calculate size: Resting is 48, Pressed is 64 (Big Jump!)
    final double currentSize = _isPressed ? 64 : 48;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // THE PHYSICS ENGINE OF THE ROW
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            // "easeOutBack" makes it overshoot and settle, creating a bounce effect
            curve: Curves.easeOutBack, 
            width: currentSize,
            height: currentSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isPressed 
                  ? (widget.isDestructive 
                      ? Colors.redAccent.withOpacity(0.2)
                      : theme.colorScheme.primary.withOpacity(0.2))
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              border: _isPressed 
                  ? Border.all(
                      color: widget.isDestructive 
                          ? Colors.redAccent.withOpacity(0.5)
                          : theme.colorScheme.primary.withOpacity(0.5),
                      width: 2,
                    )
                  : null,
            ),
            child: AnimatedRotation(
              // Slight rotation for character
              turns: _isPressed ? -0.05 : 0, 
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: AnimatedScale(
                // Icon grows slightly inside the bubble
                scale: _isPressed ? 1.2 : 1.0, 
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(
                  widget.icon, 
                  color: color, 
                  size: 24
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Text also animates slightly to get out of the way
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: color,
              // Font gets slightly bolder/larger when pressed
              fontSize: _isPressed ? 13 : 12,
              fontWeight: _isPressed ? FontWeight.bold : FontWeight.w500,
              fontFamily: 'Serif', // Assuming your app font
            ),
            child: Text(widget.label),
          ),
        ],
      ),
    );
  }
}