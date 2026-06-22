import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main_page.dart';
import '../register/login.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  static const _brand = Color(0xFFE85D6A);

  late final AnimationController _introCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _dotsCtrl;

  late final Animation<double> _scale;
  late final Animation<double> _fadeIn;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat();

    _scale = Tween<double>(begin: 0.28, end: 1.0).animate(
      CurvedAnimation(parent: _introCtrl, curve: Curves.elasticOut),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.0, 0.38, curve: Curves.easeIn),
      ),
    );

    _glow = Tween<double>(begin: 0.08, end: 0.22).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _introCtrl.forward();
    Future.delayed(const Duration(milliseconds: 3200), _go);
  }

  void _go() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _glowCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Subtle brand-tinted radial background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.05),
                  radius: 0.75,
                  colors: [
                    const Color(0xFFFFF0F1),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),

          // Logo — center stage
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_introCtrl, _glowCtrl]),
              builder: (_, child) => Opacity(
                opacity: _fadeIn.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: _brand.withOpacity(_glow.value),
                          blurRadius: 80,
                          spreadRadius: 16,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
              child: Image.asset(
                'assets/images/emas_logo.png',
                width: 260,
              ),
            ),
          ),

          // Bouncing dots loader
          Positioned(
            bottom: 72,
            left: 0,
            right: 0,
            child: _DotsLoader(controller: _dotsCtrl, color: _brand),
          ),

          // Subtle version label
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Text(
              'v1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: _brand.withOpacity(0.28),
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsLoader extends StatelessWidget {
  const _DotsLoader({required this.controller, required this.color});

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = (controller.value + i / 3.0) % 1.0;
            final v = math.sin(phase * math.pi).abs();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Opacity(
                opacity: 0.25 + 0.75 * v,
                child: Transform.translate(
                  offset: Offset(0, -8 * v),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
