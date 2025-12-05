import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditorBottomBar extends StatefulWidget {
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onLink;
  final VoidCallback onCheckbox;
  final VoidCallback onMic;
  final VoidCallback onOcr;
  final VoidCallback onImage;
  final VoidCallback onCode;
  final VoidCallback onQuote;
  final VoidCallback onTemplate;
  final bool isRecording; // Visual feedback for mic

  const EditorBottomBar({
    super.key,
    required this.onBold,
    required this.onItalic,
    required this.onLink,
    required this.onCheckbox,
    required this.onMic,
    required this.onOcr,
    required this.onImage,
    required this.onCode,
    required this.onQuote,
    required this.onTemplate,
    this.isRecording = false,
  });

  @override
  State<EditorBottomBar> createState() => _EditorBottomBarState();
}

class _EditorBottomBarState extends State<EditorBottomBar> {
  bool _isToolbarExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Adjust vertical padding to control height
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Expand Toggle
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isToolbarExpanded = !_isToolbarExpanded);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isToolbarExpanded 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedRotation(
                    turns: _isToolbarExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      _isToolbarExpanded ? Icons.keyboard_arrow_down : Icons.more_horiz,
                      color: theme.colorScheme.onSecondary,
                      size: 24,
                    ),
                  ),
                ),
              ),
              
              _PhysicsToolbarIcon(icon: Icons.format_bold, onPressed: widget.onBold, theme: theme),
              _PhysicsToolbarIcon(icon: Icons.format_italic, onPressed: widget.onItalic, theme: theme),
              _PhysicsToolbarIcon(icon: Icons.link, onPressed: widget.onLink, theme: theme),
              _PhysicsToolbarIcon(icon: Icons.check_box_outlined, onPressed: widget.onCheckbox, theme: theme),
              
              // Mic Icon with Recording State
              _PhysicsToolbarIcon(
                icon: widget.isRecording ? Icons.mic : Icons.mic_none, 
                onPressed: widget.onMic, 
                theme: theme,
                activeColor: widget.isRecording ? Colors.redAccent : null,
                isPulsing: widget.isRecording,
              ),
            ],
          ),
          
          // Expanded Row
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
                          child: SizedBox(
                          height: _isToolbarExpanded ? 64 : 0,
                          child: _isToolbarExpanded 
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _PhysicsToolbarIcon(icon: Icons.camera_alt_outlined, onPressed: widget.onOcr, theme: theme, label: "OCR"),
                                    _PhysicsToolbarIcon(icon: Icons.image_outlined, onPressed: widget.onImage, theme: theme, label: "Image"),
                                    _PhysicsToolbarIcon(icon: Icons.code, onPressed: widget.onCode, theme: theme, label: "Code"),
                                    _PhysicsToolbarIcon(icon: Icons.format_quote, onPressed: widget.onQuote, theme: theme, label: "Quote"),
                                    _PhysicsToolbarIcon(icon: Icons.file_copy_outlined, onPressed: widget.onTemplate, theme: theme, label: "Templ."),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                        ),          ),
        ],
      ),
    );
  }
}

class _PhysicsToolbarIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final ThemeData theme;
  final String? label;
  final Color? activeColor;
  final bool isPulsing;

  const _PhysicsToolbarIcon({
    required this.icon,
    required this.onPressed,
    required this.theme,
    this.label,
    this.activeColor,
    this.isPulsing = false,
  });

  @override
  State<_PhysicsToolbarIcon> createState() => _PhysicsToolbarIconState();
}

class _PhysicsToolbarIconState extends State<_PhysicsToolbarIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _sizeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    
    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PhysicsToolbarIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onPressed();
    HapticFeedback.lightImpact();
    // Only play click animation if not already pulsing
    if (!widget.isPulsing) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onTapDown: (_) {
        if (!widget.isPulsing) {
          HapticFeedback.mediumImpact();
          _controller.forward();
        }
      },
      onTapCancel: () {
        if (!widget.isPulsing) _controller.reverse();
      },
      child: Container(
        color: Colors.transparent, // Hit test area
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _sizeAnimation,
              builder: (context, child) {
                // Physics: 44 -> 60 (Shove effect)
                final double size = 44 + (16 * _sizeAnimation.value); 
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: _sizeAnimation.value > 0.1 
                        ? (widget.activeColor ?? widget.theme.colorScheme.primary).withOpacity(0.15 * _sizeAnimation.value) 
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      widget.icon,
                      color: widget.activeColor ?? widget.theme.iconTheme.color,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
            if (widget.label != null)
              Text(widget.label!, style: TextStyle(fontSize: 9, color: widget.theme.hintColor)),
          ],
        ),
      ),
    );
  }
}
