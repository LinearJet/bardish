import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../models/note.dart';

class NotePreviewDialog extends StatefulWidget {
  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const NotePreviewDialog({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  State<NotePreviewDialog> createState() => _NotePreviewDialogState();
}

class _NotePreviewDialogState extends State<NotePreviewDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper to fix Markdown display issues
  String _processForDisplay(String text) {
    String processed = text.replaceAll(RegExp(r'^\[ \]', multiLine: true), '- [ ]');
    processed = processed.replaceAll(RegExp(r'^\[x\]', multiLine: true), '- [x]');
    processed = processed.replaceAll('\n', '  \n');
    return processed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final backgroundColor = isDark ? const Color(0xFF231F1D) : theme.cardColor; 
    final textColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.secondary; 
    final mutedColor = theme.hintColor;
    
    // Explicit colors for code blocks to ensure contrast
    final codeBgColor = isDark ? const Color(0xFF353230) : Colors.grey.shade200;
    final codeTextColor = isDark ? const Color(0xFFE9E9E9) : Colors.black87;

    final scrollController = ScrollController();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.75, 
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: secondaryColor.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.description_outlined, size: 18, color: secondaryColor),
                        const SizedBox(width: 12),
                        Text(
                          'Note preview',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor.withOpacity(0.9),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, size: 20, color: mutedColor),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, thickness: 0.5),

                  // --- Content Area (Expanded to fill space) ---
                  Expanded(
                    child: Stack(
                      children: [
                        // We wrap SingleChildScrollView in Positioned.fill to ensure it knows its bounds
                        Positioned.fill(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(24),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.note.title.isEmpty ? "Untitled" : widget.note.title,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Serif',
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  MarkdownBody(
                                    data: _processForDisplay(widget.note.content),
                                    styleSheet: MarkdownStyleSheet(
                                      p: TextStyle(color: textColor.withOpacity(0.8), fontSize: 15, height: 1.5),
                                      h1: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                                      h2: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                                      strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                                      listBullet: TextStyle(color: secondaryColor),
                                      checkbox: TextStyle(color: secondaryColor),
                                      // Styles for code to fix visibility
                                      code: TextStyle(
                                        color: codeTextColor,
                                        backgroundColor: codeBgColor,
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                      ),
                                      codeblockDecoration: BoxDecoration(
                                        color: codeBgColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      blockquote: TextStyle(
                                        color: mutedColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      blockquoteDecoration: BoxDecoration(
                                        border: Border(left: BorderSide(color: secondaryColor, width: 4)),
                                        color: codeBgColor.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Scroll Indicator
                        Positioned(
                          right: 6, 
                          top: 0,
                          bottom: 0,
                          child: _SquishScrollIndicator(
                            controller: scrollController,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Bottom Actions ---
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onEdit();
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryColor,
                              foregroundColor: const Color(0xFF1C1918),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onRemove();
                            },
                            icon: Icon(Icons.link_off, size: 18, color: Colors.redAccent.withOpacity(0.8)),
                            label: Text(
                              'Remove', 
                              style: TextStyle(color: Colors.redAccent.withOpacity(0.8), fontWeight: FontWeight.w600)
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              backgroundColor: Colors.redAccent.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide.none, 
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SquishScrollIndicator extends StatefulWidget {
  final ScrollController controller;
  final Color color;

  const _SquishScrollIndicator({
    required this.controller,
    required this.color,
  });

  @override
  State<_SquishScrollIndicator> createState() => _SquishScrollIndicatorState();
}

class _SquishScrollIndicatorState extends State<_SquishScrollIndicator> {
  double _scrollFraction = 0.0;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateScroll);
    super.dispose();
  }

  void _updateScroll() {
    if (!mounted) return;
    
    // Safety check to prevent red screen (NaN errors)
    if (!widget.controller.hasClients) return;

    final maxScroll = widget.controller.position.maxScrollExtent;
    
    if (maxScroll <= 0) {
      if (_isVisible) setState(() => _isVisible = false);
      return;
    } else {
      if (!_isVisible) setState(() => _isVisible = true);
    }

    final currentScroll = widget.controller.position.pixels;
    
    // Avoid division by zero
    final fraction = maxScroll > 0 ? (currentScroll / maxScroll).clamp(0.0, 1.0) : 0.0;
    
    setState(() {
      _scrollFraction = fraction;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Morphing Logic (Squish):
        // Base: 8x8 circle
        // Edge: 24 width x 4 height (Horizontal Line)
        
        const baseSize = 8.0;
        const maxStretchWidth = 16.0; // Adds to width
        const maxSquishHeight = 4.0;  // Subtracts from height
        
        double stretch = 0.0;
        
        // Calculate stretch based on proximity to edges
        if (_scrollFraction < 0.1) {
          // Near Top -> Squish
          stretch = (0.1 - _scrollFraction) / 0.1;
        } else if (_scrollFraction > 0.9) {
          // Near Bottom -> Squish
          stretch = (_scrollFraction - 0.9) / 0.1;
        }
        
        stretch = Curves.easeOut.transform(stretch);
        
        final currentWidth = baseSize + (maxStretchWidth * stretch); 
        final currentHeight = baseSize - (maxSquishHeight * stretch);
        
        // Calculate Top Position
        final trackHeight = constraints.maxHeight - baseSize; // Use base size for track calc to keep it centered properly
        final topPos = _scrollFraction * trackHeight + (baseSize - currentHeight) / 2;

        return SizedBox(
          width: 30, // Container width to allow horizontal expansion
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 50),
                top: topPos,
                right: 4, 
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  width: currentWidth,
                  height: currentHeight,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(currentHeight / 2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ]
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}