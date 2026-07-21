import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/login.dart';
import 'main_page.dart';

// Splash screen: fade in logo, hold, then transition to LoginPage or MainPage [LoadingPage]
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

    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _fadeCtrl.forward();

    _go(); // Navigate to the next page after the fade-in animation
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// ============================== [Navigation Logic] ==============================
  // Fade-transition to MainPage if already logged in, otherwise LoginPage [_go]
  void _go() {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final destination = user != null ? const MainPage() : const LoginPage();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
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
              child: Image.asset('assets/images/emas_logo.png', width: 240),
            ),
          ],
        ),
      ),
    );
  }
}
