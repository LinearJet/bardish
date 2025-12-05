import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
import 'nav_bar_icon.dart';
import 'option_item.dart';

class FloatingNavbar extends StatefulWidget {
  // Navigation Props
  final VoidCallback onAddPressed;
  final VoidCallback? onBlockPressed;
  final VoidCallback? onListPressed;
  final int currentIndex;
  final Function(int) onTabChanged;

  // Context Mode Props
  final bool isContextMode;
  final int selectedCount;
  final bool areAllPinned; 
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onLink;
  final VoidCallback? onMoveToBlock;
  final VoidCallback? onCopy;
  final VoidCallback? onDuplicate;
  final VoidCallback? onEdit;
  final VoidCallback? onSetColor;
  final VoidCallback? onPrivate;

  const FloatingNavbar({
    super.key, 
    required this.onAddPressed,
    this.onBlockPressed,
    this.onListPressed,
    required this.currentIndex,
    required this.onTabChanged,
    this.isContextMode = false,
    this.selectedCount = 0,
    this.areAllPinned = false, 
    this.onDelete,
    this.onPin,
    this.onLink,
    this.onMoveToBlock,
    this.onCopy,
    this.onDuplicate,
    this.onEdit,
    this.onSetColor,
    this.onPrivate,
  });

  @override
  State<FloatingNavbar> createState() => _FloatingNavbarState();
}

class _FloatingNavbarState extends State<FloatingNavbar> with TickerProviderStateMixin {
  bool isMenuExpanded = false;
  bool isContextExpanded = false; 
  
  late AnimationController _fadeController;
  late AnimationController _tabController;
  late AnimationController _contextExpandController;

  late Animation<double> _tabsFadeAnimation;
  late Animation<double> _tabSwitchAnimation;
  late Animation<double> _contextExpandAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _tabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contextExpandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _tabsFadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _tabSwitchAnimation = CurvedAnimation(
      parent: _tabController,
      curve: Curves.easeInOutCubic,
    );
    _contextExpandAnimation = CurvedAnimation(
      parent: _contextExpandController,
      curve: Curves.elasticOut,
    );
    
    _fadeController.value = 1.0;
  }

  @override
  void didUpdateWidget(FloatingNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _tabController.forward(from: 0.0);
    }
    if (oldWidget.isContextMode && !widget.isContextMode) {
      setState(() {
        isContextExpanded = false;
        _contextExpandController.reset();
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    _contextExpandController.dispose();
    super.dispose();
  }

  void _toggleAddMenu() async {
    if (!isMenuExpanded) {
      await _fadeController.reverse();
    }
    setState(() => isMenuExpanded = !isMenuExpanded);
    if (!isMenuExpanded) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) _fadeController.forward();
    }
  }

  void _toggleContextExpansion() {
    setState(() => isContextExpanded = !isContextExpanded);
    if (isContextExpanded) {
      _contextExpandController.forward(from: 0.0);
    } else {
      _contextExpandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Increased heights slightly to allow for bouncy growth
    final double navHeight = widget.isContextMode ? (isContextExpanded ? 190 : 110) : 78;
    final EdgeInsets navMargin = widget.isContextMode
        ? const EdgeInsets.fromLTRB(20, 0, 20, 50) 
        : const EdgeInsets.fromLTRB(42, 0, 42, 60);
    final navBarColor = (isMenuExpanded || widget.isContextMode)
        ? theme.cardColor.withOpacity(0.95)
        : theme.cardColor;
    final accentColor = theme.colorScheme.secondary;
    final buttonColor = isMenuExpanded ? theme.colorScheme.primary : accentColor;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      height: navHeight,
      margin: navMargin,
      alignment: Alignment.bottomCenter, 
      decoration: BoxDecoration(
        color: navBarColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), 
            blurRadius: 24, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: widget.isContextMode 
          ? _buildContextContent(theme) 
          : _buildNormalContent(theme, accentColor, buttonColor),
    );
  }

  Widget _buildContextContent(ThemeData theme) {
    final iconColor = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;
    final deleteIconColor = isDark ? const Color(0xFFE57373) : Colors.redAccent;
    final deleteBgColor = isDark ? const Color(0xFF3F2B2B) : const Color(0xFFFFE5E5);
    final bool isMulti = widget.selectedCount > 1;
    
    Color getColor(bool enabled) => enabled ? iconColor : iconColor.withOpacity(0.3);

    final topRow = [
      _ExpressiveContextBtn(icon: Icons.more_horiz, label: "More", onTap: _toggleContextExpansion, color: iconColor),
      _ExpressiveContextBtn(icon: Icons.delete_outline, label: "Delete", onTap: widget.onDelete, color: deleteIconColor, backgroundColor: deleteBgColor),
      _ExpressiveContextBtn(
        icon: widget.areAllPinned ? Icons.bookmark : Icons.bookmark_border, 
        label: widget.areAllPinned ? "Unpin" : "Pin", 
        onTap: widget.onPin, 
        color: iconColor
      ),
      _ExpressiveContextBtn(icon: Icons.link, label: "Link", onTap: widget.onLink, color: iconColor), 
      _ExpressiveContextBtn(icon: Icons.drive_file_move_outlined, label: "Block", onTap: widget.onMoveToBlock, color: iconColor),
      _ExpressiveContextBtn(icon: Icons.edit_outlined, label: "Edit", onTap: isMulti ? null : widget.onEdit, color: getColor(!isMulti)),
    ];

    final bottomRow = [
      _ExpressiveContextBtn(icon: Icons.content_copy, label: "Copy", onTap: isMulti ? null : widget.onCopy, color: getColor(!isMulti)),
      _ExpressiveContextBtn(icon: Icons.file_copy_outlined, label: "Duplicate", onTap: isMulti ? null : widget.onDuplicate, color: getColor(!isMulti)),
      _ExpressiveContextBtn(icon: Icons.palette_outlined, label: "Color", onTap: widget.onSetColor, color: iconColor),
      _ExpressiveContextBtn(icon: Icons.security, label: "Private", onTap: widget.onPrivate, color: iconColor),
    ];

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Top Row (Scrollable horizontally)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 90, 
            padding: const EdgeInsets.only(left: 4, right: 8, bottom: 12),
            alignment: Alignment.center,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Always bounce physics for satisfaction
              physics: const BouncingScrollPhysics(), 
              child: Row(
                mainAxisAlignment: isContextExpanded ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.start,
                children: topRow.map((e) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: e)).toList(),
              ),
            ),
          ),
          
          // Expanded Row
          if (isContextExpanded)
            ScaleTransition(
              scale: _contextExpandAnimation,
              child: Container(
                height: 90,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: bottomRow.map((e) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: e)).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNormalContent(ThemeData theme, Color accentColor, Color buttonColor) {
    return SizedBox(
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: _tabsFadeAnimation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(_tabsFadeAnimation),
              child: IgnorePointer(
                ignoring: isMenuExpanded,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 3),
                    GestureDetector(onTap: () => widget.onTabChanged(0), behavior: HitTestBehavior.opaque, child: NavBarIcon(iconType: NavIconType.notes, label: 'Notes', isActive: widget.currentIndex == 0, accentColor: accentColor, theme: theme, animation: _tabSwitchAnimation)),
                    const SizedBox(width: 80), 
                    GestureDetector(onTap: () => widget.onTabChanged(1), behavior: HitTestBehavior.opaque, child: NavBarIcon(iconType: NavIconType.checklist, label: 'Lists', isActive: widget.currentIndex == 1, accentColor: accentColor, theme: theme, animation: _tabSwitchAnimation)),
                    const SizedBox(width: 3),
                  ],
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            right: isMenuExpanded ? 12 : (MediaQuery.of(context).size.width - 96 - 56) / 2, 
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: SizedBox(
                    width: isMenuExpanded ? (MediaQuery.of(context).size.width - 96) - 80 : 0, 
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0), 
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                        children: [
                          OptionItem(iconType: OptionIconType.note, label: "Note", theme: theme, onTap: () { _toggleAddMenu(); widget.onAddPressed(); }),
                          OptionItem(iconType: OptionIconType.folder, label: "Block", theme: theme, onTap: () { _toggleAddMenu(); widget.onBlockPressed?.call(); }),
                          OptionItem(iconType: OptionIconType.checklist, label: "List", theme: theme, onTap: () { _toggleAddMenu(); widget.onListPressed?.call(); }),
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleAddMenu,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    width: isMenuExpanded ? 48 : 56, 
                    height: 48,
                    decoration: BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(isMenuExpanded ? 16 : 24), boxShadow: [BoxShadow(color: buttonColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))]),
                    child: AnimatedRotation(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic, turns: isMenuExpanded ? 0.125 : 0, child: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 28)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpressiveContextBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color? backgroundColor;

  const _ExpressiveContextBtn({
    required this.icon, 
    required this.label, 
    required this.onTap, 
    required this.color, 
    this.backgroundColor
  });

  @override
  State<_ExpressiveContextBtn> createState() => _ExpressiveContextBtnState();
}

class _ExpressiveContextBtnState extends State<_ExpressiveContextBtn> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      HapticFeedback.mediumImpact();
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
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
    // Resting size 44, Pressed size 56 (The Shove)
    final double currentSize = _isPressed ? 56 : 44;
    final bool isDisabled = widget.onTap == null;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Container(
        // Dynamic width to allow shoving neighbors
        constraints: BoxConstraints(minWidth: 56), 
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              width: currentSize,
              height: currentSize,
              decoration: BoxDecoration(
                // Use background color if provided, else use grey/opacity
                color: isDisabled
                    ? Colors.grey.withOpacity(0.1)
                    : (widget.backgroundColor ?? widget.color.withOpacity(0.1)),
                shape: BoxShape.circle,
                border: _isPressed && !isDisabled
                    ? Border.all(color: widget.color.withOpacity(0.3), width: 2)
                    : null,
              ),
              child: AnimatedRotation(
                turns: _isPressed ? -0.05 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: AnimatedScale(
                  scale: _isPressed ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    widget.icon, 
                    color: isDisabled ? widget.color.withOpacity(0.3) : widget.color, 
                    size: 20
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isDisabled ? widget.color.withOpacity(0.3) : widget.color,
                fontSize: _isPressed ? 11 : 10,
                fontWeight: _isPressed ? FontWeight.bold : FontWeight.w600,
                fontFamily: 'Serif',
              ),
              child: Text(
                widget.label, 
                maxLines: 1, 
                overflow: TextOverflow.visible, // Allow overflow during shove
                textAlign: TextAlign.center
              ),
            ),
          ],
        ),
      ),
    );
  }
}