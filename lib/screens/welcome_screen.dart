import 'package:flutter/material.dart';
import 'features_screen.dart';
import 'dashboard_screen.dart';
import '../widgets/animated_title.dart';
import '../theme/colors.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Staggered Animations
  late Animation<double> _skipFade;
  late Animation<double> _glowFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _buttonFade;
  late Animation<Offset> _buttonSlide;

  // ✅ Key to measure button position
  final getStartedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _skipFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
    );

    _glowFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.2, 0.5, curve: Curves.easeIn)),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 0.7, curve: Curves.easeOut)),
    );

    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 0.7, curve: Curves.elasticOut)),
    );

    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );

    _buttonSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.6, 1.0, curve: Curves.elasticOut)),
    );

    // 🌐 Force animation reveal on WEB so it doesn't flake
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward(); // skip the "wait for typing" on web
      final gap = _measureGap();
      debugPrint("🌐 (init) Button gap: ${gap.toStringAsFixed(1)} px");
    });
  }

  double _measureGap() {
    final box =
        getStartedKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return 0.0;
    final y = box.localToGlobal(Offset.zero).dy;
    final h = box.size.height;
    final screenH = MediaQuery.of(context).size.height;
    return screenH - (y + h);
  }

  void _startStaggeredReveal() {
    _controller.forward();
    final gap = _measureGap();
    debugPrint("✨ Button gap after reveal: ${gap.toStringAsFixed(1)} px");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 🔍 Measure on every build and print like our life depends on it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final gap = _measureGap();
      debugPrint("🌍 WEB BUTTON GAP: ${gap.toStringAsFixed(1)} px");
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 24,
              child: FadeTransition(
                opacity: _skipFade,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DashboardScreen()),
                    );
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                        color: theme.textTheme.bodySmall?.color, fontSize: 16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  AnimatedTitle(onFinished: _startStaggeredReveal),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _glowFade,
                    child: Container(
                      height: 1,
                      width: 60,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.5),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        children: [
                          Text(
                            'Minimalist Notes',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'for your important and not-so-important ideas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                  FadeTransition(
                    opacity: _buttonFade,
                    child: SlideTransition(
                      position: _buttonSlide,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: 200,
                          height: 52,
                          child: ElevatedButton(
                            key: getStartedKey, // ✅ key stays locked on the button
                            onPressed: () {
                              final gap = _measureGap();
                              debugPrint("🚀 gap = ${gap.toStringAsFixed(1)} px from bottom");
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const FeaturesScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.surface,
                              foregroundColor: theme.colorScheme.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}