import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../services/storage_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _floatingController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _floatingOffset;

  // Beautiful Pastel Palette - Fintech Inspired
  static const Color white = Color(0xFFFFFFFF);
  static const Color softBlue = Color(0xFFE3F2FD);
  static const Color pastelBlue = Color(0xFFBBDEFB);
  static const Color softGreen = Color(0xFFE8F5E9);
  static const Color pastelGreen = Color(0xFFC8E6C9);
  static const Color lightPeach = Color(0xFFFEEDEB);
  static const Color accentBlue = Color(0xFF42A5F5);

  @override
  void initState() {
    super.initState();

    // Logo animation - scale and fade in
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    // Text animation - slide from bottom
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 30), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Floating animation for decorative elements
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _floatingOffset = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _startAnimations();
    _navigateToNextScreen();
  }

  void _startAnimations() async {
    await _logoController.forward();
    _textController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      final storage = StorageService();
      final isAuth = storage.isAuthenticated();

      if (isAuth) {
        context.go('/dashboard');
      } else {
        context.go('/login');
      }
    } catch (e) {
      context.go('/login');
    }
  }

  Widget _buildFloatingCircle(
      {required double size,
      required Color color,
      required Alignment alignment}) {
    return Positioned(
      child: Transform.translate(
        offset: Offset(0, _floatingOffset.value),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [white, softBlue, softGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating decorative circles - background
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: pastelBlue.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -100,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: pastelGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.3,
              right: -60,
              child: AnimatedBuilder(
                animation: _floatingOffset,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _floatingOffset.value),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: accentBlue.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animation
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoController]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  accentBlue,
                                  pastelBlue,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentBlue.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.trending_up,
                                size: 60,
                                color: accentBlue,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // App name with animation
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: _textSlide.value,
                        child: Opacity(
                          opacity: _textOpacity.value,
                          child: Column(
                            children: [
                              Text(
                                AppStrings.appName,
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      color: accentBlue,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 3,
                                width: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [pastelBlue, accentBlue],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Prophetic Business Solutions',
                                style:
                                    Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: accentBlue.withOpacity(0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Professional CFO Services',
                                style:
                                    Theme.of(context).textTheme.labelLarge?.copyWith(
                                          color: accentBlue.withOpacity(0.6),
                                          letterSpacing: 0.5,
                                        ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 60),

                  // Modern loading indicator
                  AnimatedBuilder(
                    animation: _floatingController,
                    builder: (context, child) {
                      return Column(
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(accentBlue),
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading...',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: accentBlue.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom decorative element
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      pastelGreen.withOpacity(0.2),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
