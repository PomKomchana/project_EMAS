import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/constants/emas_colors.dart';

const usersCollection = 'users';
const defaultNewUserRole = 'user';

const minPasswordLength = 6;

String? validateFirstName(String? value) {
  if (value == null || value.trim().isEmpty) return 'กรุณากรอกชื่อ';
  return null;
}

String? validateLastName(String? value) {
  if (value == null || value.trim().isEmpty) return 'กรุณากรอกนามสกุล';
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'กรุณากรอกอีเมล';
  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailPattern.hasMatch(value.trim())) return 'รูปแบบอีเมลไม่ถูกต้อง';
  return null;
}

String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) return 'กรุณากรอกเบอร์โทรศัพท์';
  final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.length < 9 || digitsOnly.length > 10) {
    return 'เบอร์โทรศัพท์ไม่ถูกต้อง';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
  if (value.length < minPasswordLength) {
    return 'ต้องมีอย่างน้อย $minPasswordLength ตัว';
  }
  return null;
}

FormFieldValidator<String> validateConfirmPassword(
  String Function() getOriginalPassword,
) {
  return (value) {
    if (value == null || value.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
    if (value != getOriginalPassword()) return 'รหัสผ่านไม่ตรงกัน';
    return null;
  };
}

String mapAuthErrorToMessage(String code) {
  switch (code) {
    case 'email-already-in-use':
      return 'อีเมลนี้มีผู้ใช้งานแล้ว';
    case 'invalid-email':
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    case 'weak-password':
      return 'รหัสผ่านไม่ปลอดภัยเพียงพอ';
    case 'network-request-failed':
      return 'การเชื่อมต่อเครือข่ายมีปัญหา กรุณาลองใหม่';
    default:
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
  }
}

class SignupHeader extends StatelessWidget {
  const SignupHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /*SizedBox(
          width: 260,
        child: Image.asset(
          'assets/images/signup_emas_logo.png',
          fit: BoxFit.contain,
          ),
        ),*/
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        const Text(
          'Fill your information to get started with EMAS',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),

        const SizedBox(height: 36),
      ],
    );
  }
}

class SignupErrorBanner extends StatelessWidget {
  final String message;

  const SignupErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class SignupTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final FormFieldValidator<String> validator;

  const SignupTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emasColor, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

class SignupPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final FormFieldValidator<String> validator;

  const SignupPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggleObscure,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleObscure,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emasColor, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

class SignupSubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const SignupSubmitButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: emasColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: double.infinity,
                height: 40,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text('Sign Up', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

class SignupLoginLink extends StatelessWidget {
  final VoidCallback onTap;

  const SignupLoginLink({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('มีบัญชีอยู่แล้ว?', style: TextStyle(color: Colors.black54)),
        TextButton(
          onPressed: onTap,
          child: const Text(
            'Login',
            style: TextStyle(color: emasColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  /// ============================== [Controllers] ==============================
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    UserCredential? credential;

    try {
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance
          .collection(usersCollection)
          .doc(uid)
          .set({
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'role': defaultNewUserRole,
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      _showSuccessAndReturnToLogin();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = mapAuthErrorToMessage(e.code));
    } catch (e) {
      // Firestore write (or anything else) failed after Auth succeeded.
      // Roll back the Auth user so we don't leave an orphaned account.
      await _rollbackAuthUser(credential);
      setState(() => _error = 'เกิดข้อผิดพลาดในการบันทึกข้อมูล กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rollbackAuthUser(UserCredential? credential) async {
    try {
      await credential?.user?.delete();
    } catch (_) {}
  }

  void _showSuccessAndReturnToLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('สร้างบัญชีสำเร็จ กรุณาเข้าสู่ระบบ'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SignupHeader(),
                const SizedBox(height: 24),

                if (_error != null) SignupErrorBanner(message: _error!),

                Row(
                  children: [
                    Expanded(
                      child: SignupTextField(
                        controller: _firstNameController,
                        label: 'ชื่อ',
                        icon: Icons.person_outline,
                        validator: validateFirstName,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SignupTextField(
                        controller: _lastNameController,
                        label: 'นามสกุล',
                        icon: Icons.person_outline,
                        validator: validateLastName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SignupTextField(
                  controller: _emailController,
                  label: 'อีเมล',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: validateEmail,
                ),
                const SizedBox(height: 16),

                SignupTextField(
                  controller: _phoneController,
                  label: 'เบอร์โทรศัพท์',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: validatePhone,
                ),
                const SizedBox(height: 16),

                SignupPasswordField(
                  controller: _passwordController,
                  label: 'รหัสผ่าน',
                  obscure: _obscurePassword,
                  onToggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  validator: validatePassword,
                ),
                const SizedBox(height: 16),

                SignupPasswordField(
                  controller: _confirmPasswordController,
                  label: 'ยืนยันรหัสผ่าน',
                  obscure: _obscureConfirmPassword,
                  onToggleObscure: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                  validator: validateConfirmPassword(
                    () => _passwordController.text,
                  ),
                ),
                const SizedBox(height: 24),

                SignupSubmitButton(
                  isLoading: _isLoading,
                  onPressed: _submitSignUp,
                ),
                const SizedBox(height: 16),

                SignupLoginLink(onTap: () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
