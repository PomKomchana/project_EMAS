import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/login.dart';

// Splash screen: fade in logo, hold, then transition to LoginPage [LoadingPage]
class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {

  /// ============================== [Controllers & Services] ==============================
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  /// ============================== [Life Cycle] ==============================
  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fade = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeIn,
    );

    _fadeCtrl.forward();

    Future.delayed(const Duration(seconds: 2), _go);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// ============================== [Navigation Logic] ==============================
  // Fade-transition to LoginPage after the splash delay [_go]
  void _go() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            // Logo center
            Center(
              child: Image.asset(
                'assets/images/emas_logo.png',
                width: 240,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
