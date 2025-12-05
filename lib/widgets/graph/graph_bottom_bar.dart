import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GraphBottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onReset;
  final VoidCallback onClear;
  final VoidCallback onAnnotation;
  final VoidCallback onStickyNote; // Renamed from Names/Hide logic
  final VoidCallback onSearch; 
  final VoidCallback onToggleLight; 
  final VoidCallback onAskAi;

  const GraphBottomBar({
    super.key,
    required this.onBack,
    required this.onEdit,
    required this.onReset,
    required this.onClear,
    required this.onAnnotation,
    required this.onStickyNote, // New
    required this.onSearch,
    required this.onToggleLight,
    required this.onAskAi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bottomBarColor = isDark ? const Color(0xFF262321) : Colors.white; 
    final hintColor = isDark ? const Color(0xFF9E9E9E) : theme.hintColor;
    final activeColor = const Color(0xFFA48566); 

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: bottomBarColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          _GraphBottomBarItem(icon: Icons.arrow_back, label: 'Back', onTap: onBack, color: hintColor),
          _GraphBottomBarItem(icon: Icons.hub, label: 'Graph', onTap: (){}, color: activeColor, isSelected: true),
          _GraphBottomBarItem(icon: Icons.build_outlined, label: 'Edit', onTap: onEdit, color: hintColor),
          
          // Annotation Button
          _GraphBottomBarItem(icon: Icons.text_fields_rounded, label: 'Text', onTap: onAnnotation, color: hintColor),
          
          // Sticky Note Button (Replaces Names)
          _GraphBottomBarItem(icon: Icons.sticky_note_2_outlined, label: 'Sticky', onTap: onStickyNote, color: hintColor),
          
          _GraphBottomBarItem(icon: Icons.search, label: 'Search', onTap: onSearch, color: hintColor),
          
          _GraphBottomBarItem(icon: Icons.smart_toy_outlined, label: 'Ask AI', onTap: onAskAi, color: hintColor),
          
          _GraphBottomBarItem(icon: Icons.restart_alt, label: 'Reset', onTap: onReset, color: hintColor),
          _GraphBottomBarItem(icon: Icons.light_mode_outlined, label: 'Light', onTap: onToggleLight, color: activeColor),
          
          _GraphBottomBarItem(icon: Icons.delete_outline, label: 'Clear', onTap: onClear, color: Colors.redAccent.withOpacity(0.7)),
        ],
      ),
    );
  }
}

class _GraphBottomBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isSelected;

  const _GraphBottomBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.isSelected = false,
  });

  @override
  State<_GraphBottomBarItem> createState() => _GraphBottomBarItemState();
}

class _GraphBottomBarItemState extends State<_GraphBottomBarItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // This ensures even a quick tap triggers the full animation cycle
    widget.onTap();
    HapticFeedback.lightImpact();
    _controller.forward().then((_) => _controller.reverse());
  }

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.mediumImpact(); 
    _controller.forward();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    // We let _handleTap manage the action and reverse
  }

  void _handleTapCancel() {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDestructive = widget.color.value == Colors.redAccent.withOpacity(0.7).value;
    
    // Base size 50, expands to 70
    // We bind size to the controller value so it animates smoothly on tap or press
    
    return GestureDetector(
      onTap: _handleTap,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4), 
        color: Colors.transparent, 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scaleVal = _controller.value; 
                final currentSize = 50 + (20 * scaleVal);
                final rotation = -0.1 * scaleVal;

                return Container(
                  width: currentSize,
                  height: currentSize,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.isSelected 
                        ? widget.color.withOpacity(0.15) 
                        : (scaleVal > 0.1 
                            ? (isDestructive ? widget.color.withOpacity(0.2) : theme.colorScheme.secondary.withOpacity(0.1)) 
                            : Colors.transparent),
                    shape: BoxShape.circle,
                    border: scaleVal > 0.1 
                        ? Border.all(
                            color: isDestructive ? widget.color.withOpacity(0.5) : widget.color.withOpacity(0.3),
                            width: 2,
                          )
                        : null,
                  ),
                  child: Transform.rotate(
                    angle: rotation,
                    child: Icon(
                      widget.icon, 
                      color: widget.color, 
                      size: 24, 
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 100),
              style: TextStyle(
                color: widget.color,
                fontSize: _isPressed ? 11 : 10,
                fontWeight: _isPressed ? FontWeight.bold : FontWeight.w600,
                fontFamily: 'Serif',
              ),
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}