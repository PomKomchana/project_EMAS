import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_page.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {

  static const Color accentColor = Color(0xFFE85D6A);

  late AnimationController scaleController;
  late AnimationController dotsController;

  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: scaleController,
        curve: Curves.easeOut,
      ),
    );

    scaleController.forward();

    Future.delayed(const Duration(milliseconds: 2500), navigateToMain);
  }

  void navigateToMain() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    scaleController.dispose();
    dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, //พื้นขาวล้วน
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          /// LOGO
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: scaleController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: scaleAnimation.value,
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/images/emas_logo.png',
                  width: 180, // เล็กลงให้ดู minimal
                ),
              ),
            ),
          ),

          ///LOADING DOTS
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: DotsLoader(
              controller: dotsController,
              color: accentColor,
            ),
          ),

          /// VERSION
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black38,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DotsLoader extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const DotsLoader({
    Key? key,
    required this.controller,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (controller.value - delay).clamp(0.0, 1.0);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6 + (6 * value),
              height: 6 + (6 * value),
              decoration: BoxDecoration(
                color: color.withOpacity(0.3 + (0.7 * value)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}