import 'package:flutter/material.dart';
import '../theme/colors.dart';

class ContextActionBar extends StatefulWidget {
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onLink;
  final VoidCallback onMoveToBlock;
  final VoidCallback onCopy;
  final VoidCallback onDuplicate;
  final VoidCallback onEdit;
  final VoidCallback onSetColor;

  const ContextActionBar({
    super.key,
    required this.onDelete,
    required this.onPin,
    required this.onLink,
    required this.onMoveToBlock,
    required this.onCopy,
    required this.onDuplicate,
    required this.onEdit,
    required this.onSetColor,
  });

  @override
  State<ContextActionBar> createState() => _ContextActionBarState();
}

class _ContextActionBarState extends State<ContextActionBar> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Aesthetic specific to the requested design (Dark Matte)
    final backgroundColor = isDark ? const Color(0xFF23201E) : const Color(0xFFEEEBE6);
    final buttonColor = isDark ? const Color(0xFF332F2C) : const Color(0xFFE0DCD5);
    final deleteButtonColor = isDark ? const Color(0xFF3F2B2B) : const Color(0xFFFFE5E5);
    final deleteIconColor = isDark ? const Color(0xFFE57373) : Colors.redAccent;
    final iconColor = theme.colorScheme.secondary;
    final textColor = theme.colorScheme.secondary;

    // Define all actions
    final List<Widget> allActions = [
      _ContextButton(
        icon: Icons.more_horiz,
        label: 'More',
        bgColor: buttonColor,
        iconColor: iconColor,
        textColor: textColor,
        onTap: _toggleExpanded,
      ),
      _ContextButton(
        icon: Icons.delete_outline,
        label: 'Delete',
        bgColor: deleteButtonColor,
        iconColor: deleteIconColor,
        textColor: deleteIconColor, // Reddish label for delete
        onTap: widget.onDelete,
      ),
      _ContextButton(
        icon: Icons.push_pin, // Filled pin
        label: 'Pin',
        bgColor: buttonColor,
        iconColor: iconColor,
        textColor: textColor,
        onTap: widget.onPin,
      ),
      _ContextButton(
        icon: Icons.link,
        label: 'Link',
        bgColor: buttonColor,
        iconColor: iconColor,
        textColor: textColor,
        onTap: widget.onLink,
      ),
      _ContextButton(
        icon: Icons.drive_file_move_outlined,
        label: 'Move to Block',
        bgColor: buttonColor,
        iconColor: iconColor,
        textColor: textColor,
        onTap: widget.onMoveToBlock,
      ),
      _ContextButton(
        icon: Icons.edit_outlined,
        label: 'Edit',
        bgColor: buttonColor,
        iconColor: iconColor,
        textColor: textColor,
        onTap: widget.onEdit,
      ),
      _ContextButton(
        icon: Icons.content_copy,
        label: 'Copy',
        bgColor: buttonColor,
        iconColor: iconColor,
        textColor: textColor,
        onTap: widget.onCopy,
      ),
      _ContextButton(
        icon: Icons.file_copy_outlined,
        label: 'Duplicate',
        bgColor: buttonColor,
        iconColor: iconColor,
        textColor: textColor,
        onTap: widget.onDuplicate,
      ),
      _ContextButton(
        icon: Icons.palette_outlined,
        label: 'Set Color',
        bgColor: buttonColor,
        iconColor: iconColor,
        textColor: textColor,
        onTap: widget.onSetColor,
      ),
    ];

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          // Swipe Up -> Expand
          setState(() => _isExpanded = true);
        } else if (details.primaryVelocity! > 0) {
          // Swipe Down -> Collapse
          setState(() => _isExpanded = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _isExpanded
            ? Wrap(
                spacing: 12,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: allActions,
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: allActions.take(5).map((e) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: e,
                  )).toList(),
                ),
              ),
      ),
    );
  }
}

class _ContextButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ContextButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
