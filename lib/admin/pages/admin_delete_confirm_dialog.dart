import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../../shared/constants/emas_colors.dart';

/// Dialog for news and reports. Admin must re-enter password before the
/// action happens. Returns true only if the password was correct.
/// [confirmLabel]/[icon]/[isDanger] let callers reuse this for both
/// destructive actions (delete, red) and non-destructive confirmations
/// (save changes, emasColor). [showDeleteConfirmDialog]
Future<bool> showDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'ยืนยันลบ',
  IconData icon = Icons.delete_outline_rounded,
  bool isDanger = true,
}) async {
  final passwordCtrl = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => _DeleteConfirmDialog(
      title: title,
      message: message,
      passwordCtrl: passwordCtrl,
      confirmLabel: confirmLabel,
      icon: icon,
      isDanger: isDanger,
    ),
  );

  return confirmed ?? false;
}

class _DeleteConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final TextEditingController passwordCtrl;
  final String confirmLabel;
  final IconData icon;
  final bool isDanger;

  const _DeleteConfirmDialog({
    required this.title,
    required this.message,
    required this.passwordCtrl,
    required this.confirmLabel,
    required this.icon,
    required this.isDanger,
  });

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  /// ============================== [Controllers & Services] ==============================
  final _adminService = AdminService();
  final _focusNode = FocusNode();

  /// ============================== [State] ==============================
  bool _isChecking = false;
  bool _obscure = true;
  String? _errorText;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// ============================== [Delete Confirm Logic] ==============================
  /// Check password with Firebase before confirming [_confirm]
  Future<void> _confirm() async {
    final password = widget.passwordCtrl.text;
    if (password.isEmpty) {
      setState(() => _errorText = 'กรุณากรอกรหัสผ่าน');
      _focusNode.requestFocus();
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
      _focusNode.requestFocus();
      return;
    }

    Navigator.pop(context, true);
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isDanger ? const Color(0xFFE53935) : emasColor;
    final accentBgColor =
        widget.isDanger ? const Color(0xFFFFEBEE) : emasColor.withValues(alpha: 0.1);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accentBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: accentColor,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),

            // Message
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 22),

            // Password field
            TextField(
              controller: widget.passwordCtrl,
              focusNode: _focusNode,
              obscureText: _obscure,
              autofocus: true,
              enabled: !_isChecking,
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              onSubmitted: (_) => _confirm(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                errorText: _errorText,
                filled: true,
                fillColor: const Color(0xFFF7F7F8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                suffixIcon: IconButton(
                  splashRadius: 18,
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 19,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: emasColor, width: 1.6),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isChecking ? null : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ยกเลิก', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      disabledBackgroundColor: accentColor.withValues(alpha: 0.6),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isChecking ? null : _confirm,
                    child: _isChecking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.confirmLabel,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      }
