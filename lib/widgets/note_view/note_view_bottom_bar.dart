import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NoteViewBottomBar extends StatelessWidget {
  final bool isInverted;
  final VoidCallback onInvertToggle;
  final VoidCallback onSearchTap;
  final VoidCallback onViewModeTap;
  final VoidCallback onTextSizeTap;
  final VoidCallback onMoreTap;

  const NoteViewBottomBar({
    super.key,
    required this.isInverted,
    required this.onInvertToggle,
    required this.onSearchTap,
    required this.onViewModeTap,
    required this.onTextSizeTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final barColor = isDark 
        ? const Color(0xFF23201E) 
        : theme.colorScheme.surfaceContainerHighest;
    final iconColor = theme.iconTheme.color;
    final activeColor = theme.colorScheme.secondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      height: 72, 
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _PhysicsBarButton(
            icon: isInverted ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: isInverted ? activeColor : iconColor,
            onTap: onInvertToggle,
            tooltip: 'Invert Colors',
            isActive: isInverted,
          ),
          _PhysicsBarButton(
            icon: Icons.search_rounded,
            color: iconColor,
            onTap: onSearchTap,
            tooltip: 'Search',
          ),
          _PhysicsBarButton(
            icon: Icons.auto_stories_rounded,
            color: iconColor,
            onTap: onViewModeTap,
            tooltip: 'View Mode',
          ),
          _PhysicsBarButton(
            icon: Icons.format_size_rounded,
            color: iconColor,
            onTap: onTextSizeTap,
            tooltip: 'Text Size',
          ),
          _PhysicsBarButton(
            icon: Icons.more_vert_rounded,
            color: iconColor,
            onTap: onMoreTap,
            tooltip: 'More',
          ),
        ],
      ),
    );
  }
}

class _PhysicsBarButton extends StatefulWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  final String tooltip;
  final bool isActive;

  const _PhysicsBarButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.isActive = false,
  });

  @override
  State<_PhysicsBarButton> createState() => _PhysicsBarButtonState();
}

class _PhysicsBarButtonState extends State<_PhysicsBarButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap(); // Action first
          _controller.forward().then((_) => _controller.reverse()); // Animation second
        },
        onTapDown: (_) {
          HapticFeedback.mediumImpact();
          _controller.forward();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            // Physics: 48 -> 64 (Shove effect)
            final double size = 48 + (16 * _anim.value);
            final double rotation = -0.1 * _anim.value;
            
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: widget.isActive 
                    ? widget.color?.withOpacity(0.15) 
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: _anim.value > 0.1
                    ? Border.all(color: (widget.color ?? Colors.grey).withOpacity(0.1), width: 2)
                    : null,
              ),
              child: Transform.rotate(
                angle: rotation,
                child: Icon(
                  widget.icon, 
                  color: widget.color, 
                  size: 24 + (4 * _anim.value), 
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
