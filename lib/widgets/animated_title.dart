import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart'; // Import colors

class AnimatedTitle extends StatefulWidget {
  final VoidCallback? onFinished;
  const AnimatedTitle({super.key, this.onFinished});

  @override
  State<AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<AnimatedTitle> {
  final String _targetText = "Bard-ish";
  String _currentText = "";
  bool _showCursor = true;
  Timer? _cursorTimer;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _startAnimationSequence() async {
    _startCursorBlinking();
    await Future.delayed(const Duration(milliseconds: 1000));
    _typeText();
  }

  void _startCursorBlinking() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) setState(() => _showCursor = !_showCursor);
    });
  }

  void _typeText() {
    int charIndex = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (charIndex < _targetText.length) {
        if (mounted) {
          setState(() {
            charIndex++;
            _currentText = _targetText.substring(0, charIndex);
            _showCursor = true;
          });
        }
      } else {
        timer.cancel();
        _finishSequence();
      }
    });
  }

  void _finishSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _cursorTimer?.cancel();
      setState(() => _showCursor = false);
      widget.onFinished?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _currentText,
          style: const TextStyle(
            fontFamily: 'Serif',
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: BardishColors.textPrimary, // UPDATED
            letterSpacing: 3.0,
          ),
        ),
        Opacity(
          opacity: _showCursor ? 1.0 : 0.0,
          child: const Text(
            '|', 
            style: TextStyle(
              fontFamily: 'Serif',
              fontSize: 48,
              fontWeight: FontWeight.w200,
              color: BardishColors.cursor, // UPDATED
            ),
          ),
        ),
      ],
    );
  }
}
