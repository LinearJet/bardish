import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Needed to save the "Done" flag
import '../theme/colors.dart';
import 'dashboard_screen.dart'; 

class BetaWarningScreen extends StatefulWidget {
  const BetaWarningScreen({super.key});

  @override
  State<BetaWarningScreen> createState() => _BetaWarningScreenState();
}

class _BetaWarningScreenState extends State<BetaWarningScreen> with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Reveal Controller (Content enters)
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 2. Pulse Controller (Beta symbol breathes)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Animation Definitions
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOutCubic),
    );

    _buttonScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController, 
        // Button appears last with a bounce
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Start the show
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _revealController.forward();
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BardishColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // THE BETA SYMBOL (Breathing)
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Subtle glow behind the beta
                      boxShadow: [
                        BoxShadow(
                          color: BardishColors.bronze.withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'β',
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 48,
                        color: BardishColors.bronze,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // TEXT CONTENT (Slides Up)
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'Beta Version',
                        style: TextStyle(
                          fontSize: 24,
                          fontFamily: 'Serif',
                          color: BardishColors.textPrimary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'This is a beta version of the app.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: BardishColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'There may be bugs and malfunctions. We are actively working on improvements.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: BardishColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // USAGE POLICY LINK
                      GestureDetector(
                        onTap: () {
                           // Link logic would go here
                           print("Usage Policy Clicked");
                        },
                        child: const Text(
                          'usage policy',
                          style: TextStyle(
                            fontSize: 14,
                            color: BardishColors.bronze,
                            decoration: TextDecoration.underline,
                            decorationColor: BardishColors.bronze,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // MAIN ACTION BUTTON (Elastic Pop)
              ScaleTransition(
                scale: _buttonScaleAnimation,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      // 1. Open Settings Box
                      var settings = await Hive.openBox('settings');
                      
                      // 2. Set the flag so we don't show onboarding again
                      await settings.put('hasSeenOnboarding', true);

                      // 3. Navigate to Dashboard (Replace so back button doesn't work)
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(builder: (context) => const DashboardScreen())
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BardishColors.bronze, 
                      foregroundColor: const Color(0xFF1C1918), // Dark text on bronze
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Accept and Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
