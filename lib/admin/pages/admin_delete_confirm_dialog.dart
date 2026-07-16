import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../../shared/constants/emas_colors.dart';

/// Dialog for news and reports. Admin must re-enter password before delete
/// happens. Returns true only if the password was correct. [showDeleteConfirmDialog]
Future<bool> showDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final passwordCtrl = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => _DeleteConfirmDialog(
      title: title,
      message: message,
      passwordCtrl: passwordCtrl,
    ),
  );

  return confirmed ?? false;
}

class _DeleteConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final TextEditingController passwordCtrl;

  const _DeleteConfirmDialog({
    required this.title,
    required this.message,
    required this.passwordCtrl,
  });

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  /// ============================== [Controllers & Services] ==============================
  final _adminService = AdminService();

  /// ============================== [State] ==============================
  bool _isChecking = false;
  String? _errorText;

  /// ============================== [Delete Confirm Logic] ==============================
  /// Check password with Firebase before deleting [_confirm]
  Future<void> _confirm() async {
    final password = widget.passwordCtrl.text;
    if (password.isEmpty) {
      setState(() => _errorText = 'กรุณากรอกรหัสผ่าน');
      return;
    }

    setState(() {
      _isChecking = true;
      _errorText = null;
    });

    final ok = await _adminService.reauthenticate(password);

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _isChecking = false;
        _errorText = 'รหัสผ่านไม่ถูกต้อง';
      });
      return;
    }

    Navigator.pop(context, true);
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      title: Text(widget.title, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: widget.passwordCtrl,
            obscureText: true,
            autofocus: true,
            enabled: !_isChecking,
            onSubmitted: (_) => _confirm(),
            decoration: InputDecoration(
              labelText: 'รหัสผ่านของคุณ',
              errorText: _errorText,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: emasColor, width: 2),
              ),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: _isChecking ? null : () => Navigator.pop(context, false),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isChecking ? null : _confirm,
          child: _isChecking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('ยืนยันลบ', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
