import 'dart:async';
import 'package:flutter/material.dart';
import 'view_mode_sheet.dart';

class AutoModeIndicator extends StatefulWidget {
  final ViewMode viewMode;
  final double autoScrollSpeed;
  final double autoFlipInterval;
  final VoidCallback onClose;
  final int currentPage;
  final int totalPages;

  const AutoModeIndicator({
    super.key,
    required this.viewMode,
    required this.autoScrollSpeed,
    required this.autoFlipInterval,
    required this.onClose,
    this.currentPage = 0,
    this.totalPages = 1,
  });

  @override
  State<AutoModeIndicator> createState() => _AutoModeIndicatorState();
}

class _AutoModeIndicatorState extends State<AutoModeIndicator> 
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    if (widget.viewMode == ViewMode.autoFlip) {
      _startCountdown();
    }
  }

  @override
  void didUpdateWidget(AutoModeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewMode == ViewMode.autoFlip && 
        oldWidget.currentPage != widget.currentPage) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _remainingSeconds = widget.autoFlipInterval.toInt();
    });
    
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _startCountdown();
        }
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAutoScroll = widget.viewMode == ViewMode.autoScroll;
    final isAutoFlip = widget.viewMode == ViewMode.autoFlip;

    return ScaleTransition(
      scale: _pulseAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.secondary.withOpacity(0.3),
              theme.colorScheme.secondary.withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.secondary.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.secondary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAutoScroll 
                  ? Icons.slow_motion_video_rounded 
                  : Icons.auto_stories_rounded,
              color: theme.colorScheme.secondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            
            // Mode Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAutoScroll ? 'Auto Scroll' : 'Auto Flip',
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isAutoScroll)
                  Text(
                    '${widget.autoScrollSpeed.toStringAsFixed(1)}x speed',
                    style: TextStyle(
                      color: theme.colorScheme.secondary.withOpacity(0.8),
                      fontSize: 9,
                    ),
                  ),
                if (isAutoFlip)
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 10,
                        color: theme.colorScheme.secondary.withOpacity(0.8),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${_remainingSeconds}s',
                        style: TextStyle(
                          color: theme.colorScheme.secondary.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            
            const SizedBox(width: 8),
            
            // Progress indicator for auto flip
            if (isAutoFlip) ...[
              SizedBox(
                width: 24,
                height: 24,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: _remainingSeconds / widget.autoFlipInterval,
                        strokeWidth: 2,
                        backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.currentPage + 1}',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            
            // Close Button
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: theme.colorScheme.secondary,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}