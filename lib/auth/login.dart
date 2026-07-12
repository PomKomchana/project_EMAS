import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/main_page.dart';
import 'sign_up.dart';

import '../../shared/constants/emas_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _kRememberMeKey = 'remember_me';
  static const _kSavedEmailKey = 'saved_email';

  bool _isLoading = false;
  bool _obscure = true;
  bool _rememberMe = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool(_kRememberMeKey) ?? false;
    final savedEmail = prefs.getString(_kSavedEmailKey);

    if (remembered && savedEmail != null) {
      setState(() {
        _rememberMe = true;
        _emailCtrl.text = savedEmail;
      });
    }
  }

  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool(_kRememberMeKey, true);
      await prefs.setString(_kSavedEmailKey, _emailCtrl.text.trim());
    } else {
      await prefs.setBool(_kRememberMeKey, false);
      await prefs.remove(_kSavedEmailKey);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      final role = doc.data()?['role'] ?? 'user';

      // บันทึกสถานะ remember me หลัง login สำเร็จ
      await _saveRememberMe();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _error = 'ไม่พบบัญชีผู้ใช้นี้';
            break;
          case 'wrong-password':
            _error = 'รหัสผ่านไม่ถูกต้อง';
            break;
          case 'invalid-email':
            _error = 'รูปแบบอีเมลไม่ถูกต้อง';
            break;
          default:
            _error = 'เกิดข้อผิดพลาด: ${e.message}';
        }
      });
    } catch (e) {
      setState(() => _error = 'เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goBackToMain() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [

            ///  เนื้อหาหลัก
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const Text(
                        'Hi welcome to EMAS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF212121),
                        ),
                      ),

                      const SizedBox(height: 36),

                      /// ERROR
                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      /// EMAIL
                      SignupTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'กรุณากรอกอีเมล';
                          if (!v.contains('@')) return 'รูปแบบอีเมลไม่ถูกต้อง';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// PASSWORD
                      SignupPasswordField(
                        controller: _passCtrl,
                        label: 'Password',
                        obscure: _obscure,
                        onToggleObscure: () => setState(() => _obscure = !_obscure),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                          if (v.length < 6) return 'ต้องมีอย่างน้อย 6 ตัว';
                          return null;
                        },
                      ),

                      const SizedBox(height: 8),

                      /// REMEMBER ME
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: emasColor,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (v) {
                                setState(() => _rememberMe = v ?? false);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() => _rememberMe = !_rememberMe);
                            },
                            child: const Text(
                              'Remember me',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: emasColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                              : const Text(
                                  'LOGIN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// SIGN UP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ยังไม่มีบัญชี?',
                            style: TextStyle(color: Colors.black54),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignUpPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                color: emasColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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