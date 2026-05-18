import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:educonnect/features/discovery/presentation/pages/discovery_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const routeName = 'splash';
  static const routePath = '/';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _loadingController.forward();

    Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      context.goNamed(DiscoveryPage.routeName);
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF19072B), // Ultra dark purple
              Color(0xFF0C0317), // Deepest black-violet
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Decorative background glowing spots
            Positioned(
              top: -100,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4B176E).withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4B176E).withValues(alpha: 0.28),
                      blurRadius: 120,
                      spreadRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF1377).withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF1377).withValues(alpha: 0.24),
                      blurRadius: 120,
                      spreadRadius: 16,
                    ),
                  ],
                ),
              ),
            ),

            // Main central premium content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Soft floating glassmorphism card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // High-res logo with stunning bounce, scale & fade effects
                      Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF1377,
                                  ).withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          )
                          .animate()
                          .scale(
                            duration: 1000.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(0.3, 0.3),
                          )
                          .fadeIn(duration: 600.ms),

                      const SizedBox(height: 24),

                      // Brand name "EduConnect" with premium typography & slide-in glow
                      Text(
                            'EduConnect',
                            style: GoogleFonts.outfit(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                              shadows: [
                                Shadow(
                                  color: const Color(
                                    0xFF4B176E,
                                  ).withValues(alpha: 0.8),
                                  offset: const Offset(0, 4),
                                  blurRadius: 12,
                                ),
                                Shadow(
                                  color: const Color(
                                    0xFFFF1377,
                                  ).withValues(alpha: 0.5),
                                  offset: const Offset(0, 6),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 600.ms)
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),

                      const SizedBox(height: 8),

                      // Sub-headline
                      Text(
                            'Belajar Lebih Cerdas, Lebih Dekat',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.65),
                              letterSpacing: 1.2,
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 700.ms, duration: 600.ms)
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Smooth linear premium loading bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: AnimatedBuilder(
                          animation: _loadingController,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _loadingController.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4B176E),
                                      Color(0xFFFF1377),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF1377,
                                      ).withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Memuat Pengalaman Premium...',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1100.ms, duration: 600.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
