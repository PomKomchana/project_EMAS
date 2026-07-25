import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/admin_service.dart';
import '../../shared/constants/emas_colors.dart';
import 'admin_delete_confirm_dialog.dart';

// Opens the news composer (create or edit). Returns true if saved. Public
// so other pages (e.g. AdminMainPage's FAB) can open it too. [showNewsForm]
Future<bool?> showNewsForm(
  BuildContext context, {
  required AdminService adminService,
  QueryDocumentSnapshot? doc,
}) {
  return Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => _NewsFormPage(adminService: adminService, doc: doc),
    ),
  );
}

// Announcements tab: merges 'news' + admin-created 'reports' into one feed.
// Filter is owned by AdminMainPage and rendered in the shared AppBar. [AdminAnnouncementsPage]
class AdminAnnouncementsPage extends StatelessWidget {
  const AdminAnnouncementsPage({super.key});

  /// ============================== [Controllers & Services] ==============================
  static final _adminService = AdminService();

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: emasColor,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'เพิ่มประกาศ',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: () => _openNewsForm(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _adminService.newsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'เกิดข้อผิดพลาดในการโหลดข้อมูล',
                style: TextStyle(color: Colors.red.shade400),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          final items = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return _FeedItem(
              doc: doc,
              title: data['title'] ?? '-',
              subtitle: data['content'] ?? '-',
              time: (data['createdAt'] as Timestamp?)?.toDate(),
              imageUrl: data['imageUrl'],
              link: data['link'],
            );
          }).toList();

          items.sort((a, b) => b.time!.compareTo(a.time!));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            itemCount: items.length,
            itemBuilder: (_, i) => _buildNewsCard(context, items[i]),
          );
        },
      ),
    );
  }

  /// ============================== [UI Helpers] ==============================
  String _formatDate(DateTime? time) {
    if (time == null) return '-';
    return '${time.day}/${time.month}/${time.year}';
  }

  Future<void> _openLink(String url) async {
    var normalized = url.trim();
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }
    final uri = Uri.tryParse(normalized);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// ============================== [Widgets] ==============================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: emasColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.campaign_outlined,
              size: 40,
              color: emasColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'ยังไม่มีประกาศ',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, _FeedItem item) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final hasLink = item.link != null && item.link!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage) ...[
                  _buildThumbnail(item.imageUrl),
                  const SizedBox(width: 12),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: emasColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: emasColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(item.time),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openNewsForm(context, doc: item.doc),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 19,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _deleteNews(context, item.doc.id),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (hasLink) ...[
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _openLink(item.link!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.link!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey.shade400,
          size: 24,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.image_outlined,
            color: Colors.grey.shade400,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// ============================== [News Logic] ==============================
  // Opens the full-page news composer (create or edit) instead of the old small AlertDialog [_openNewsForm]
  void _openNewsForm(BuildContext context, {QueryDocumentSnapshot? doc}) {
    showNewsForm(context, adminService: _adminService, doc: doc);
  }

  Future<void> _deleteNews(BuildContext context, String docId) async {
  final confirmed = await showDeleteConfirmDialog(
    context,
    title: 'ยืนยันการลบ',
    message: 'คุณต้องการลบประกาศนี้ใช่หรือไม่? การกระทำนี้ไม่สามารถย้อนกลับได้',
  );

  if (!confirmed) return;

  try {
    await _adminService.deleteNews(docId);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }
 }
} 

/// ============================== [Feed Model] ==============================
class _FeedItem {
  final QueryDocumentSnapshot doc;
  final String title;
  final String subtitle;
  final DateTime? time;
  final String? imageUrl;
  final String? link;

  _FeedItem({
    required this.doc,
    required this.title,
    required this.subtitle,
    required this.time,
    this.imageUrl,
    this.link,
  });
}

/// ============================== [News Form Page] ==============================
// Full-page composer for adding/editing a news item — bigger layout with image + link attachment [_NewsFormPage]
class _NewsFormPage extends StatefulWidget {
  final AdminService adminService;
  final QueryDocumentSnapshot? doc;

  const _NewsFormPage({required this.adminService, this.doc});

  @override
  State<_NewsFormPage> createState() => _NewsFormPageState();
}

class _NewsFormPageState extends State<_NewsFormPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _linkCtrl;

  File? _pickedImage;
  String?
  _originalImageUrl; // image already on the doc when editing (immutable snapshot)
  bool _imageRemoved =
      false; // true if the admin cleared the existing image without picking a new one
  bool _saving = false;

  bool get _isEdit => widget.doc != null;

  @override
  void initState() {
    super.initState();
    final data = widget.doc?.data() as Map<String, dynamic>?;
    _titleCtrl = TextEditingController(text: data?['title'] ?? '');
    _contentCtrl = TextEditingController(text: data?['content'] ?? '');
    _linkCtrl = TextEditingController(text: data?['link'] ?? '');
    _originalImageUrl = data?['imageUrl'] as String?;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  /// ============================== [Image Attachment] ==============================
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
        _imageRemoved =
            false; // a freshly picked image supersedes any "removed" state
      });
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: emasColor,
              ),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: emasColor),
              title: const Text('ถ่ายรูป'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _imageRemoved = true;
    });
  }

  /// Opens the current preview image (new pick or existing network image) at
  /// real/full size in a fullscreen zoomable viewer [_openFullImage]
  void _openFullImage({File? file, String? url}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _FullScreenImageViewer(imageFile: file, imageUrl: url),
          );
        },
      ),
    );
  }

  /// ============================== [Save] ==============================
  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกหัวข้อ')));
      return;
    }

    setState(() => _saving = true);
    try {
      final link = _linkCtrl.text.trim();

      if (_isEdit) {
        await widget.adminService.updateNews(
          docId: widget.doc!.id,
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          link: link.isEmpty ? null : link,
          image: _pickedImage,
          removeImage: _imageRemoved,
          existingImageUrl: _originalImageUrl,
        );
      } else {
        await widget.adminService.addNews(
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          link: link.isEmpty ? null : link,
          image: _pickedImage,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          _isEdit ? 'แก้ไขประกาศ' : 'เพิ่มประกาศ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('รูปภาพประกอบ'),
              const SizedBox(height: 10),
              _buildImagePicker(),
              const SizedBox(height: 22),
              _buildSectionLabel('หัวข้อ'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _titleCtrl,
                hint: 'ระบุหัวข้อข่าวสาร',
              ),
              const SizedBox(height: 22),
              _buildSectionLabel('เนื้อหา'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _contentCtrl,
                hint: 'รายละเอียดของข่าวสาร',
                maxLines: 10,
                minLines: 6,
              ),
              const SizedBox(height: 22),
              _buildSectionLabel('Link'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _linkCtrl,
                hint: 'https://',
                icon: Icons.link_rounded,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emasColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Text(
                          _isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มประกาศ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14.5,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? minLines,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: minLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: icon != null
              ? Icon(icon, color: emasColor, size: 20)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: emasColor, width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final hasNewImage = _pickedImage != null;
    final hasExistingImage =
        !hasNewImage &&
        !_imageRemoved &&
        _originalImageUrl != null &&
        _originalImageUrl!.isNotEmpty;

    if (!hasNewImage && !hasExistingImage) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _showImageSourceSheet,
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade300,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 34,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'เพิ่มรูปภาพ',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: double.infinity,
            height: 180,
            child: hasNewImage
                ? Image.file(_pickedImage!, fit: BoxFit.cover)
                : Image.network(_originalImageUrl!, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: _buildImageActionButton(
            Icons.zoom_out_map_rounded,
            () => _openFullImage(
              file: hasNewImage ? _pickedImage : null,
              url: hasNewImage ? null : _originalImageUrl,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _buildImageActionButton(
                Icons.edit_rounded,
                _showImageSourceSheet,
              ),
              const SizedBox(width: 8),
              _buildImageActionButton(Icons.close_rounded, _removeImage),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageActionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: Colors.white),
      ),
    );
  }
}

/// [FULLSCREEN-IMAGE-VIEWER] แสดงรูปภาพขนาดจริงแบบเต็มจอ พร้อมซูม/ลากได้
/// รองรับทั้งรูปที่เพิ่งเลือก (File) และรูปเดิมที่อยู่บน network (String url)
/// ปิดได้ด้วยการแตะพื้นหลัง หรือกดปุ่มปิดมุมขวาบน
class _FullScreenImageViewer extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;

  const _FullScreenImageViewer({this.imageFile, this.imageUrl});

  Widget _buildImage() {
    if (imageFile != null) {
      return Image.file(imageFile!, fit: BoxFit.contain);
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stack) => const Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: Colors.white54,
        ),
      );
    }
    return const Icon(
      Icons.broken_image_outlined,
      size: 48,
      color: Colors.white54,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 5.0,
                  child: _buildImage(),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}