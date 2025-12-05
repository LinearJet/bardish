import 'package:flutter/material.dart';

class GraphEditMenu extends StatelessWidget {
  final VoidCallback onSwap;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onCancel;
  final bool hasSelection;

  const GraphEditMenu({
    super.key,
    required this.onSwap,
    required this.onConnect,
    required this.onDisconnect,
    required this.onCancel,
    required this.hasSelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF262321) : Colors.white;
    final iconColor = theme.iconTheme.color;
    final disabledColor = iconColor?.withOpacity(0.3);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          _BouncyBtn(icon: Icons.swap_horiz, label: "Swap", onTap: hasSelection ? onSwap : null, color: iconColor, disabledColor: disabledColor),
          const SizedBox(width: 20),
          _BouncyBtn(icon: Icons.linear_scale, label: "Connect", onTap: hasSelection ? onConnect : null, color: iconColor, disabledColor: disabledColor),
          const SizedBox(width: 20),
          _BouncyBtn(icon: Icons.link_off, label: "Disconnect", onTap: hasSelection ? onDisconnect : null, color: iconColor, disabledColor: disabledColor),
          const SizedBox(width: 20),
          Container(width: 1, height: 24, color: theme.dividerColor.withOpacity(0.1)),
          const SizedBox(width: 20),
          _BouncyBtn(icon: Icons.check, label: "Done", onTap: onCancel, color: theme.colorScheme.secondary, disabledColor: disabledColor),
        ],
      ),
    );
  }
}

class _BouncyBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? disabledColor;

  const _BouncyBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.disabledColor,
  });

  @override
  State<_BouncyBtn> createState() => _BouncyBtnState();
}

class _BouncyBtnState extends State<_BouncyBtn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.9).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (widget.onTap == null) return;
    await _controller.forward();
    await _controller.reverse();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: widget.onTap != null ? widget.color : widget.disabledColor, size: 22),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: widget.onTap != null ? widget.color : widget.disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}