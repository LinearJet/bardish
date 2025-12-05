import 'package:flutter/material.dart';
import '../theme/colors.dart';
// We will create the Dashboard next, for now this is a placeholder
import 'dashboard_screen.dart'; 
import 'beta_warning_screen.dart'; 

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _btnController;
  
  final List<AnimationController> _itemControllers = [];
  final int _itemCount = 5;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    for (int i = 0; i < _itemCount; i++) {
      _itemControllers.add(AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ));
    }

    _runSequence();
  }

  void _runSequence() async {
    _headerController.forward();
    
    // Stagger the list
    for (int i = 0; i < _itemCount; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) _itemControllers[i].forward();
    }

    // Bounce the button
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _btnController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _btnController.dispose();
    for (var c in _itemControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BardishColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Spacing
            const SizedBox(height: 60), 
            
            // Header
            FadeTransition(
              opacity: _headerController,
              child: const Text(
                'What awaits you',
                style: TextStyle(
                  fontSize: 26,
                  fontFamily: 'Serif',
                  color: BardishColors.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            // Middle Content (The Scrollable List)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildAnimatedRow(0, '01', 'Personal Space', 'Hide your notes'),
                      _buildAnimatedRow(1, '02', 'Connection Graph', 'View your notes visually'),
                      _buildAnimatedRow(2, '03', 'Synchronization', 'Export and Import all your Notes'),
                      _buildAnimatedRow(3, '04', 'Local Functionality', 'Android 13+: OCR and speech to text'),
                      _buildAnimatedRow(4, '05', 'Blocks', 'Store your notes in blocks, not folders'),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Area - Matching Welcome Screen Layout
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
                CurvedAnimation(parent: _btnController, curve: Curves.elasticOut),
              ),
              child: FadeTransition(
                opacity: _btnController,
                child: Padding(
                  // This combined with the SizedBox below mimics the "Spacer" from Welcome Screen
                  padding: const EdgeInsets.only(top: 20.0), 
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 200, // Matching Pill Width
                      height: 52, // Matching Height
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to Dashboard
                           Navigator.pushReplacement(
                            context, 
                            MaterialPageRoute(builder: (context) => const BetaWarningScreen())
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BardishColors.surface,
                          foregroundColor: BardishColors.textPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Next',
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
            ),

            // Bottom Buffer (Matches the Spacer(flex: 1) roughly)
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedRow(int index, String number, String title, String subtitle) {
    return AnimatedBuilder(
      animation: _itemControllers[index],
      builder: (context, child) {
        final slide = Tween<Offset>(begin: const Offset(-0.5, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _itemControllers[index], curve: Curves.easeOutQuart),
        );
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _itemControllers[index], curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: Color(0xFF8D7F71),
                        fontSize: 14,
                        fontFamily: 'Serif',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: BardishColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: BardishColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
