import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late AnimationController _shimmerController;
  late AnimationController _floatingController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotate;
  late Animation<double> _titleOpacity;
  late Animation<double> _titleTranslateY;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _subtitleTranslateY;
  late Animation<double> _shimmerTranslate;
  late Animation<double> _floatingTranslate;

  // Pastel Color Palette - White, Green, Blue
  static const Color white = Color(0xFFFFFFFF);
  static const Color pastelBlue = Color(0xFFB3D9FF);    // Light pastel blue
  static const Color pastelGreen = Color(0xFFB8E6D5);   // Light pastel green
  static const Color pastelLightGreen = Color(0xFFC8F0DF); // Very light green
  static const Color softSkyBlue = Color(0xFFD5E8F7);   // Soft sky blue
  static const Color darkGreen = Color(0xFF40916C);     // For text
  static const Color darkBlue = Color(0xFF4A7BA7);      // For accents

  @override
  void initState() {
    super.initState();

    // Logo animations (0-1200ms)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.67, curve: Curves.easeOut),
      ),
    );

    _logoRotate = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Title animations (starts after logo, 600ms duration)
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: Curves.easeOut,
      ),
    );

    _titleTranslateY = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Subtitle animations (starts after title, 500ms duration)
    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _subtitleController,
        curve: Curves.easeOut,
      ),
    );

    _subtitleTranslateY = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _subtitleController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Shimmer animation (continuous loop)
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _shimmerTranslate = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.linear,
      ),
    );

    // Floating animation for floating shapes
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _floatingTranslate = Tween<double>(begin: -20.0, end: 20.0).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animation sequence
    _startAnimations();

    // Navigate after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  Future<void> _startAnimations() async {
    await _logoController.forward();
    await _titleController.forward();
    await _subtitleController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _shimmerController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: Stack(
          children: [
            // Floating decorative elements
            _buildFloatingElements(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animations
                  _buildLogo(),
                  const SizedBox(height: 40),

                  // Title
                  _buildTitle(),
                  const SizedBox(height: 16),

                  // Subtitle
                  _buildSubtitle(),
                ],
              ),
            ),

            // Loading indicator at bottom
            _buildLoadingIndicator(size),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          white,
          pastelBlue.withOpacity(0.4),
          pastelGreen.withOpacity(0.3),
          softSkyBlue.withOpacity(0.3),
          white,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ),
    );
  }

  Widget _buildFloatingElements() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _floatingTranslate,
        builder: (context, child) {
          return Stack(
            children: [
              // Top-left blue circle
              Positioned(
                top: 60 + _floatingTranslate.value,
                left: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        pastelBlue.withOpacity(0.3),
                        pastelBlue.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Top-right green circle
              Positioned(
                top: 100 - _floatingTranslate.value * 0.8,
                right: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        pastelGreen.withOpacity(0.25),
                        pastelGreen.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom-left green circle
              Positioned(
                bottom: 100 + _floatingTranslate.value * 0.6,
                left: 20,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        pastelLightGreen.withOpacity(0.3),
                        pastelLightGreen.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom-right blue circle
              Positioned(
                bottom: 80 - _floatingTranslate.value,
                right: 30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        softSkyBlue.withOpacity(0.3),
                        softSkyBlue.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _shimmerController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Transform.rotate(
            angle: _logoRotate.value,
            child: Opacity(
              opacity: _logoOpacity.value,
              child: SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow background
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: pastelBlue.withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: pastelGreen.withOpacity(0.3),
                            blurRadius: 60,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                    ),

                    // Main logo circle with gradient
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            white,
                            pastelBlue.withOpacity(0.3),
                            pastelGreen.withOpacity(0.2),
                          ],
                        ),
                        border: Border.all(
                          color: pastelBlue.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/images/icon.ico',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [pastelBlue, pastelGreen],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.account_balance,
                                  size: 70,
                                  color: white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Shimmer effect
                    Positioned(
                      left: 70 + (_shimmerTranslate.value * 70),
                      child: Transform(
                        transform: Matrix4.skewX(-0.35),
                        child: Container(
                          width: 25,
                          height: 140,
                          decoration: BoxDecoration(
                            color: white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(70),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _titleController,
      builder: (context, child) {
        return Opacity(
          opacity: _titleOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _titleTranslateY.value),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [pastelGreen, darkBlue, pastelBlue],
                  ).createShader(bounds),
                  child: Text(
                    'FinSight',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: pastelBlue.withOpacity(0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 3,
                  width: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [pastelGreen, pastelBlue],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _subtitleController,
      builder: (context, child) {
        return Opacity(
          opacity: _subtitleOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _subtitleTranslateY.value),
            child: Column(
              children: [
                Text(
                  'Prophetic Business Solutions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: darkGreen,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Professional CFO Services',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: darkBlue.withOpacity(0.8),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: pastelBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: pastelBlue.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '✨ Smart Payments • Smart Discounts • Smart Growth ✨',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: darkGreen,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: pastelLightGreen.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: pastelGreen.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    'AI-Powered Cash Flow Intelligence',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: darkGreen.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator(Size size) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: Listenable.merge([_subtitleController, _shimmerController]),
        builder: (context, child) {
          return Opacity(
            opacity: _subtitleController.isCompleted ? 1.0 : 0.0,
            child: Column(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pastelBlue.withOpacity(0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkGreen.withOpacity(0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

    super.initState();

    // Logo animations (0-1200ms)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.67, curve: Curves.easeOut),
      ),
    );

    _logoRotate = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Title animations (starts after logo, 600ms duration)
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: Curves.easeOut,
      ),
    );

    _titleTranslateY = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Subtitle animations (starts after title, 500ms duration)
    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _subtitleController,
        curve: Curves.easeOut,
      ),
    );

    _subtitleTranslateY = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _subtitleController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Shimmer animation (continuous loop)
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _shimmerTranslate = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.linear,
      ),
    );

    // Start animation sequence
    _startAnimations();

    // Navigate after 3 seconds
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  Future<void> _startAnimations() async {
    await _logoController.forward();
    await _titleController.forward();
    await _subtitleController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [white, pastelGreen, pastelLightGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animations
                  _buildLogo(),
                  const SizedBox(height: 36),

                  // Title
                  _buildTitle(),
                  const SizedBox(height: 18),

                  // Subtitle
                  _buildSubtitle(),
                ],
              ),
            ),

            // Loading indicator at bottom
            _buildLoadingIndicator(size),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _shimmerController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Transform.rotate(
            angle: _logoRotate.value,
            child: Opacity(
              opacity: _logoOpacity.value,
              child: SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pastelGreen.withOpacity(0.13),
                        boxShadow: [
                          BoxShadow(
                            color: pastelGreen.withOpacity(0.6),
                            blurRadius: 30,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),

                    // Logo background circle
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [white, pastelGreen, pastelLightGreen],
                        ),
                        border: Border.all(
                          color: white.withOpacity(0.18),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: pastelGreen.withOpacity(0.13),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Image.asset(
                            'assets/images/converted-image.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.account_balance,
                                size: 60,
                                color: darkGreen,
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Shimmer effect
                    Positioned(
                      left: 55 + (_shimmerTranslate.value * 55),
                      child: Transform(
                        transform: Matrix4.skewX(-0.35),
                        child: Container(
                          width: 28,
                          height: 110,
                          decoration: BoxDecoration(
                            color: white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(55),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _titleController,
      builder: (context, child) {
        return Opacity(
          opacity: _titleOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _titleTranslateY.value),
            child: Column(
              children: [
                Text(
                  'FinSight',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: darkGreen,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.10),
                        offset: const Offset(2, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [green, beige],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'by Prophetic Business Solutions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: darkGreen.withOpacity(0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _subtitleController,
      builder: (context, child) {
        return Opacity(
          opacity: _subtitleOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _subtitleTranslateY.value),
            child: Column(
              children: [
                Text(
                  'Professional CFO Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: darkGreen,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI-Powered Cash Flow Analytics',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: darkGreen.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: pastelGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: pastelGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '✨ Smart Payments • Smart Discounts • Smart Growth',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: darkGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator(Size size) {
    return Positioned(
      bottom: 70,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: Listenable.merge([_subtitleController, _shimmerController]),
        builder: (context, child) {
          return Opacity(
            opacity: _subtitleOpacity.value,
            child: Column(
              children: [
                // Loading bar
                Container(
                  width: 150,
                  height: 3,
                  decoration: BoxDecoration(
                    color: pastelGreen.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (_shimmerTranslate.value + 1) / 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: pastelGreen,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Initializing AI Engine...',
                  style: TextStyle(
                    fontSize: 12,
                    color: darkGreen,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}