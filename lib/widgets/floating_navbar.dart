import 'package:flutter/material.dart';

class FloatingNavbar extends StatefulWidget {
  final VoidCallback onAddPressed;
  final VoidCallback? onBlockPressed;
  final VoidCallback? onListPressed;
  final int currentIndex;
  final Function(int) onTabChanged;

  const FloatingNavbar({
    super.key, 
    required this.onAddPressed,
    this.onBlockPressed,
    this.onListPressed,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  State<FloatingNavbar> createState() => _FloatingNavbarState();
}

class _FloatingNavbarState extends State<FloatingNavbar> with TickerProviderStateMixin {
  bool isExpanded = false;
  bool _isAnimating = false;
  late AnimationController _fadeController;
  late AnimationController _tabController;
  late Animation<double> _tabsFadeAnimation;
  late Animation<double> _tabSwitchAnimation;

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
    _tabsFadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _tabSwitchAnimation = CurvedAnimation(
      parent: _tabController,
      curve: Curves.easeInOutCubic,
    );
    _fadeController.value = 1.0;
  }

  @override
  void didUpdateWidget(FloatingNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _tabController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleMenu() async {
    if (_isAnimating) return;
    setState(() => _isAnimating = true);
    
    if (!isExpanded) {
      await _fadeController.reverse();
    }
    
    setState(() {
      isExpanded = !isExpanded;
    });
    
    if (!isExpanded) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) _fadeController.forward();
    }
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _isAnimating = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final navBarColor = isExpanded 
        ? (isDark ? const Color(0xFF2C2C2E).withOpacity(0.95) : Colors.white.withOpacity(0.95))
        : (isDark ? const Color(0xFF2C2C2E) : Colors.white);
    
    final accentColor = theme.colorScheme.secondary;
    final buttonColor = isExpanded ? theme.colorScheme.primary : accentColor;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: navBarColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.06),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: 48,
            spreadRadius: -8,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: _tabsFadeAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(_tabsFadeAnimation),
              child: IgnorePointer(
                ignoring: isExpanded,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: () => widget.onTabChanged(0),
                      behavior: HitTestBehavior.opaque,
                      child: _NavBarIcon(
                        iconType: NavIconType.notes,
                        label: 'Notes', 
                        isActive: widget.currentIndex == 0,
                        accentColor: accentColor,
                        theme: theme,
                        animation: _tabSwitchAnimation,
                      ),
                    ),
                    const SizedBox(width: 80), 
                    GestureDetector(
                      onTap: () => widget.onTabChanged(1),
                      behavior: HitTestBehavior.opaque,
                      child: _NavBarIcon(
                        iconType: NavIconType.checklist,
                        label: 'Lists', 
                        isActive: widget.currentIndex == 1,
                        accentColor: accentColor,
                        theme: theme,
                        animation: _tabSwitchAnimation,
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            right: isExpanded 
                ? 12 
                : (MediaQuery.of(context).size.width - 40 - 64) / 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: SizedBox(
                    width: isExpanded ? (MediaQuery.of(context).size.width - 40) - 88 : 0, 
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0), 
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                        children: [
                          _OptionItem(
                            iconType: OptionIconType.note,
                            label: "Note", 
                            theme: theme,
                            onTap: () {
                              _toggleMenu();
                              widget.onAddPressed();
                            }
                          ),
                          _OptionItem(
                            iconType: OptionIconType.folder,
                            label: "Block", 
                            theme: theme,
                            onTap: () {
                              _toggleMenu();
                              widget.onBlockPressed?.call();
                            }
                          ),
                          _OptionItem(
                            iconType: OptionIconType.checklist,
                            label: "List", 
                            theme: theme,
                            onTap: () {
                              _toggleMenu();
                              widget.onListPressed?.call();
                            }
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleMenu,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    width: isExpanded ? 48 : 64,
                    height: 48,
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: buttonColor.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      turns: isExpanded ? 0.125 : 0, 
                      child: Icon(
                        Icons.add, 
                        color: theme.colorScheme.onPrimary,
                        size: 28,
                      ),
                    ),
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

enum NavIconType { notes, checklist }
enum OptionIconType { note, folder, checklist }

class _NavBarIcon extends StatelessWidget {
  final NavIconType iconType;
  final String label;
  final bool isActive;
  final Color accentColor;
  final ThemeData theme;
  final Animation<double> animation;

  const _NavBarIcon({
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive ? accentColor.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomPaint(
                  size: const Size(28, 28),
                  painter: _NavIconPainter(
                    iconType: iconType,
                    color: iconColor,
                    isActive: isActive,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
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

class _NavIconPainter extends CustomPainter {
  final NavIconType iconType;
  final Color color;
  final bool isActive;

  _NavIconPainter({
    required this.iconType,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (iconType) {
      case NavIconType.notes:
        _drawNotesIcon(canvas, size, paint, fillPaint);
        break;
      case NavIconType.checklist:
        _drawChecklistIcon(canvas, size, paint, fillPaint);
        break;
    }
  }

  void _drawNotesIcon(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.15, size.width * 0.6, size.height * 0.7),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, paint);
    
    // Lines
    final lineY1 = size.height * 0.35;
    final lineY2 = size.height * 0.5;
    final lineY3 = size.height * 0.65;
    
    canvas.drawLine(
      Offset(size.width * 0.35, lineY1),
      Offset(size.width * 0.65, lineY1),
      paint..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, lineY2),
      Offset(size.width * 0.65, lineY2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, lineY3),
      Offset(size.width * 0.55, lineY3),
      paint,
    );
  }

  void _drawChecklistIcon(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final checkSize = size.width * 0.16;
    
    // First checkbox
    _drawCheckbox(canvas, size.width * 0.25, size.height * 0.25, checkSize, paint, fillPaint, true);
    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.32),
      Offset(size.width * 0.75, size.height * 0.32),
      paint..strokeWidth = 1.5,
    );
    
    // Second checkbox
    _drawCheckbox(canvas, size.width * 0.25, size.height * 0.5, checkSize, paint, fillPaint, false);
    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.57),
      Offset(size.width * 0.75, size.height * 0.57),
      paint,
    );
    
    // Third checkbox
    _drawCheckbox(canvas, size.width * 0.25, size.height * 0.75, checkSize, paint, fillPaint, true);
    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.82),
      Offset(size.width * 0.65, size.height * 0.82),
      paint,
    );
  }

  void _drawCheckbox(Canvas canvas, double x, double y, double size, Paint paint, Paint fillPaint, bool checked) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, size, size),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(rect, paint..strokeWidth = 1.8);
    
    if (checked) {
      final checkPath = Path()
        ..moveTo(x + size * 0.25, y + size * 0.5)
        ..lineTo(x + size * 0.45, y + size * 0.7)
        ..lineTo(x + size * 0.75, y + size * 0.3);
      canvas.drawPath(checkPath, paint..strokeWidth = 1.8);
    }
  }

  @override
  bool shouldRepaint(_NavIconPainter oldDelegate) =>
      iconType != oldDelegate.iconType ||
      color != oldDelegate.color ||
      isActive != oldDelegate.isActive;
}

class _OptionItem extends StatefulWidget {
  final OptionIconType iconType;
  final String label;
  final ThemeData theme;
  final VoidCallback onTap;

  const _OptionItem({
    required this.iconType,
    required this.label,
    required this.theme,
    required this.onTap
  });

  @override
  State<_OptionItem> createState() => _OptionItemState();
}

class _OptionItemState extends State<_OptionItem> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.theme.colorScheme.primary;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomPaint(
              size: const Size(32, 32),
              painter: _OptionIconPainter(
                iconType: widget.iconType,
                color: effectiveColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionIconPainter extends CustomPainter {
  final OptionIconType iconType;
  final Color color;

  _OptionIconPainter({
    required this.iconType,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (iconType) {
      case OptionIconType.note:
        _drawNoteIcon(canvas, size, paint);
        break;
      case OptionIconType.folder:
        _drawFolderIcon(canvas, size, paint);
        break;
      case OptionIconType.checklist:
        _drawChecklistIcon(canvas, size, paint);
        break;
    }
  }

  void _drawNoteIcon(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.15)
      ..lineTo(size.width * 0.65, size.height * 0.15)
      ..lineTo(size.width * 0.75, size.height * 0.28)
      ..lineTo(size.width * 0.75, size.height * 0.85)
      ..lineTo(size.width * 0.25, size.height * 0.85)
      ..close();
    
    canvas.drawPath(path, paint);
    
    canvas.drawLine(
      Offset(size.width * 0.65, size.height * 0.15),
      Offset(size.width * 0.65, size.height * 0.28),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, size.height * 0.28),
      Offset(size.width * 0.75, size.height * 0.28),
      paint,
    );
    
    // Content lines
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.45),
      Offset(size.width * 0.65, size.height * 0.45),
      paint..strokeWidth = 1.6,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.6),
      Offset(size.width * 0.65, size.height * 0.6),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.75),
      Offset(size.width * 0.55, size.height * 0.75),
      paint,
    );
  }

  void _drawFolderIcon(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.35)
      ..lineTo(size.width * 0.2, size.height * 0.75)
      ..lineTo(size.width * 0.8, size.height * 0.75)
      ..lineTo(size.width * 0.8, size.height * 0.35)
      ..lineTo(size.width * 0.55, size.height * 0.35)
      ..lineTo(size.width * 0.48, size.height * 0.25)
      ..lineTo(size.width * 0.2, size.height * 0.25)
      ..close();
    
    canvas.drawPath(path, paint);
  }

  void _drawChecklistIcon(Canvas canvas, Size size, Paint paint) {
    final checkSize = size.width * 0.18;
    final Paint fillPaint = Paint()..color = color..style = PaintingStyle.fill;
    
    _drawSmallCheckbox(canvas, size.width * 0.22, size.height * 0.22, checkSize, paint, fillPaint, true);
    canvas.drawLine(
      Offset(size.width * 0.48, size.height * 0.31),
      Offset(size.width * 0.78, size.height * 0.31),
      paint..strokeWidth = 1.8,
    );
    
    _drawSmallCheckbox(canvas, size.width * 0.22, size.height * 0.5, checkSize, paint, fillPaint, false);
    canvas.drawLine(
      Offset(size.width * 0.48, size.height * 0.59),
      Offset(size.width * 0.78, size.height * 0.59),
      paint,
    );
    
    _drawSmallCheckbox(canvas, size.width * 0.22, size.height * 0.78, checkSize, paint, fillPaint, false);
    canvas.drawLine(
      Offset(size.width * 0.48, size.height * 0.87),
      Offset(size.width * 0.68, size.height * 0.87),
      paint,
    );
  }

  void _drawSmallCheckbox(Canvas canvas, double x, double y, double size, Paint paint, Paint fillPaint, bool checked) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, size, size),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, paint..strokeWidth = 2.0);
    
    if (checked) {
      final checkPath = Path()
        ..moveTo(x + size * 0.25, y + size * 0.5)
        ..lineTo(x + size * 0.45, y + size * 0.72)
        ..lineTo(x + size * 0.78, y + size * 0.28);
      canvas.drawPath(checkPath, paint..strokeWidth = 2.0);
    }
  }

  @override
  bool shouldRepaint(_OptionIconPainter oldDelegate) =>
      iconType != oldDelegate.iconType || color != oldDelegate.color;
}