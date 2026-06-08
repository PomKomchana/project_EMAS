import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'main_page.dart';

 
const _appColor = Color(0xFFe85d6a);
 
// ===================================================
// ProfilePage — หน้าข้อมูลส่วนตัว
// ===================================================
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
 
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
 
class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  final _imagePicker = ImagePicker();
 
  // ข้อมูล user (เชื่อมกับ Firebase Auth / Firestore ได้ทีหลัง)
  final String _accountId = '968641516';
  String? _birthDate;
  String? _gender;
  String? _region;
  String? _role;
  String? _thirdPartyAccount;
 
  Future<void> _pickProfileImage() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;
 
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _profileImage = File(picked.path));
  }
 
  Future<ImageSource?> _showImageSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(),
    );
  }
 
  void _editField(String label, String? current, void Function(String?) onSave) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditFieldSheet(
        label: label,
        currentValue: current,
        onSave: (val) {
          setState(() => onSave(val));
        },
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'ข้อมูลส่วนตัว',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
 
          // ──── รูปโปรไฟล์ ────
          _ProfileRow(
            label: 'รูปโปรไฟล์',
            trailing: GestureDetector(
              onTap: _pickProfileImage,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFB39DDB),
                    backgroundImage:
                        _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? const Icon(Icons.person, color: Colors.white, size: 26)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
 
          _divider(),
 
          // ──── บัญชี ────
          _ProfileRow(
            label: 'บัญชี',
            trailing: Text(
              _accountId,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ),
 
          _divider(),
 
          // ──── วันเกิด ────
          _ProfileRow(
            label: 'วันเกิด',
            onTap: () => _editField('วันเกิด', _birthDate, (v) => _birthDate = v),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            valueText: _birthDate,
          ),
 
          _divider(),
 
          // ──── เพศ ────
          _ProfileRow(
            label: 'เพศ',
            onTap: () => _editField('เพศ', _gender, (v) => _gender = v),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            valueText: _gender,
          ),
 
          _divider(),
 
          // ──── ประเทศหรือภูมิภาค ────
          _ProfileRow(
            label: 'ประเทศหรือภูมิภาค',
            onTap: () => _editField('ประเทศหรือภูมิภาค', _region, (v) => _region = v),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            valueText: _region,
          ),
 
          _divider(),
 
          // ──── บทบาท ────
          _ProfileRow(
            label: 'บทบาท',
            onTap: () => _editField('บทบาท', _role, (v) => _role = v),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            valueText: _role,
          ),
 
          _divider(),
 
          // ──── บัญชีบุคคลที่สาม ────
          _ProfileRow(
            label: 'บัญชีบุคคลที่สาม',
            onTap: () => _editField(
                'บัญชีบุคคลที่สาม', _thirdPartyAccount, (v) => _thirdPartyAccount = v),
            valueText: _thirdPartyAccount,
          ),
 
          const SizedBox(height: 32),
        ],
      ),
    );
  }
 
  Widget _divider() => const Divider(height: 1, indent: 20, endIndent: 0);
}
 
// ===================================================
// _ProfileRow — แถวข้อมูลแต่ละรายการ
// ===================================================
class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    this.trailing,
    this.valueText,
    this.onTap,
  });
 
  final String label;
  final Widget? trailing;
  final String? valueText;
  final VoidCallback? onTap;
 
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (valueText != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    valueText!,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
 
// ===================================================
// _ImageSourceSheet — bottom sheet เลือกแหล่งรูป
// ===================================================
class _ImageSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('เปลี่ยนรูปโปรไฟล์',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _SheetTile(
              icon: Icons.camera_alt_rounded,
              label: 'ถ่ายรูป',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            _SheetTile(
              icon: Icons.photo_library_rounded,
              label: 'เลือกจากคลังภาพ',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            _SheetTile(
              icon: Icons.close,
              label: 'ยกเลิก',
              color: Colors.redAccent,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
 
class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
 
  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.black87;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c)),
      onTap: onTap,
    );
  }
}
 
// ===================================================
// _EditFieldSheet — bottom sheet แก้ไขข้อมูลทั่วไป
// ===================================================
class _EditFieldSheet extends StatefulWidget {
  const _EditFieldSheet({
    required this.label,
    required this.currentValue,
    required this.onSave,
  });
  final String label;
  final String? currentValue;
  final void Function(String?) onSave;
 
  @override
  State<_EditFieldSheet> createState() => _EditFieldSheetState();
}
 
class _EditFieldSheetState extends State<_EditFieldSheet> {
  late final TextEditingController _ctrl;
 
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentValue ?? '');
  }
 
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'กรอก${widget.label}',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _appColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _appColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final val = _ctrl.text.trim();
                    widget.onSave(val.isEmpty ? null : val);
                    Navigator.pop(context);
                  },
                  child: const Text('บันทึก',
                      style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 