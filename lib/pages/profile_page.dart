import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/login.dart';
import 'profile_detail_page.dart';

import '../shared/constants/emas_colors.dart';

// User profile: avatar picker (local only, not yet persisted), account info, logout [ProfilePage]
class ProfilePage extends StatefulWidget {
  final VoidCallback onMenuTap;
  final bool isAdmin;

  const ProfilePage({super.key, required this.onMenuTap, this.isAdmin = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  /// ============================== [Controllers & Services] ==============================
  final _imagePicker = ImagePicker();

  /// ============================== [State] ==============================
  File? _profileImage;
  String? _firstName;
  String? _lastName;

  User? get _user => FirebaseAuth.instance.currentUser;

  // Prefer firstName + lastName from Firestore; fall back to a placeholder
  // if the user hasn't filled in their profile yet. [_displayName]
  String get _displayName {
    final full = '${_firstName ?? ''} ${_lastName ?? ''}'.trim();
    return full.isNotEmpty ? full : 'ผู้ใช้งาน';
  }

  String get _email => _user?.email ?? '-';

  /// ============================== [Life Cycle] ==============================
  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  /// ============================== [Data Loading Logic] ==============================
  // Reads users/{uid}.firstName / lastName to build the display name shown
  // under the avatar. Same fields written by ProfileDetailPage. [_loadUserName]
  Future<void> _loadUserName() async {
    final uid = _user?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data == null || !mounted) return;

      setState(() {
        _firstName = data['firstName'] as String?;
        _lastName = data['lastName'] as String?;
      });
    } catch (e) {
      debugPrint('Load profile name error: $e');
    }
  }

  /// ============================== [Image Picker Logic] ==============================
  // Pick a profile image from camera/gallery.
  // NOTE: only sets local state — never uploaded to Storage or saved to
  // Firestore, so it resets on app restart (same gap fixed in ReportService). [_pickProfileImage]
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

  // Bottom sheet: camera / gallery / cancel [_showImageSourceSheet]
  Future<ImageSource?> _showImageSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),

      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: emasColor,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onMenuTap,
        ),
        title: Text(
          widget.isAdmin ? 'ADMIN' : 'USER',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- Header ----------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                decoration: const BoxDecoration(
                  color: emasColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                            child: _profileImage == null
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 52,
                                  )
                                : null,
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: emasColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ---------- โปรไฟล์ ----------
              _CardGroup(
                children: [
                  _InfoTile(
                    icon: Icons.person_outline_rounded,
                    label: 'โปรไฟล์',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFBBBBBB),
                    ),
                    isLast: true,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileDetailPage(),
                        ),
                      );
                      // Refresh name in case it was edited on ProfileDetailPage
                      _loadUserName();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------- Logout ----------
              _CardGroup(
                children: [
                  _InfoTile(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    labelColor: Colors.redAccent,
                    iconColor: Colors.redAccent,
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFBBBBBB),
                    ),
                    isLast: true,
                    onTap: _logout,
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// White rounded card wrapping a group of _InfoTile rows [_CardGroup]
class _CardGroup extends StatelessWidget {
  const _CardGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }
}

// One row in an info card [_InfoTile]
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.isLast,
    this.onTap,
    this.labelColor,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final bool isLast;
  final VoidCallback? onTap;
  final Color? labelColor;
  final Color? iconColor;

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    final iconTint = iconColor ?? const Color(0xFFe85d6a);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.vertical(
            top: isLast ? Radius.zero : const Radius.circular(20),
            bottom: isLast ? const Radius.circular(20) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconTint.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconTint, size: 20),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: labelColor ?? const Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                trailing,
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 70,
            endIndent: 0,
            color: Color(0xFFF0F0F0),
          ),
      ],
    );
  }
}

// Bottom sheet: choose image source or cancel [_ImageSourceSheet]
class _ImageSourceSheet extends StatelessWidget {
  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'เปลี่ยนรูปโปรไฟล์',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
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
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            _SheetTile(
              icon: Icons.close_rounded,
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

// One row in the image source sheet [_SheetTile]
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

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF1A1A1A);
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (color ?? const Color(0xFFe85d6a)).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? const Color(0xFFe85d6a), size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(color: c, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
