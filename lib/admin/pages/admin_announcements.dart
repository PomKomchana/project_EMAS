import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin_report_detail.dart';
import 'admin_report_form.dart';
import '../services/admin_service.dart';
import '../../shared/constants/emas_colors.dart';
import '../../shared/constants/report_constants.dart';

// Filter for the merged feed — owned by AdminMainPage, passed down [FeedFilter]
enum FeedFilter { all, news, report }

// Display label per filter option [feedFilterLabel]
String feedFilterLabel(FeedFilter f) {
  switch (f) {
    case FeedFilter.all:
      return 'ทั้งหมด';
    case FeedFilter.news:
      return 'ข่าวสาร';
    case FeedFilter.report:
      return 'แจ้งปัญหา';
  }
}

// Opens the filter sheet. Called from AdminMainPage's AppBar action [showFeedFilterSheet]
void showFeedFilterSheet(
  BuildContext context,
  FeedFilter current,
  ValueChanged<FeedFilter> onSelect,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              const Text('กรองประเภทประกาศ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              for (final f in FeedFilter.values)
                ListTile(
                  leading: Icon(
                    current == f ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: emasColor,
                  ),
                  title: Text(feedFilterLabel(f)),
                  onTap: () {
                    onSelect(f);
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
}

// Announcements tab: merges 'news' + admin-created 'reports' into one feed.
// Filter is owned by AdminMainPage and rendered in the shared AppBar. [AdminAnnouncementsPage]
class AdminAnnouncementsPage extends StatelessWidget {
  final FeedFilter filter;

  const AdminAnnouncementsPage({super.key, required this.filter});

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
        label: const Text('เพิ่มประกาศ', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () => _showCreateChooser(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _adminService.newsStream(),
        builder: (context, newsSnap) {
          if (newsSnap.hasError) {
            return Center(
              child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล',
                  style: TextStyle(color: Colors.red.shade400)),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _adminService.adminReportsStream(),
            builder: (context, reportSnap) {
              if (reportSnap.hasError) {
                return Center(
                  child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล',
                      style: TextStyle(color: Colors.red.shade400)),
                );
              }

              if (newsSnap.connectionState == ConnectionState.waiting ||
                  reportSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final newsDocs = newsSnap.data?.docs ?? [];
              final reportDocs = reportSnap.data?.docs ?? [];
              final items = _mergeFeed(newsDocs, reportDocs);

              if (items.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                itemCount: items.length,
                itemBuilder: (context, index) => _buildFeedCard(context, items[index]),
              );
            },
          );
        },
      ),
    );
  }

  /// ============================== [Data] ==============================
  // Merge news + admin reports into one feed, filtered by `filter`, newest first [_mergeFeed]
  List<_FeedItem> _mergeFeed(
    List<QueryDocumentSnapshot> newsDocs,
    List<QueryDocumentSnapshot> reportDocs,
  ) {
    final items = <_FeedItem>[];

    if (filter != FeedFilter.report) {
      for (final doc in newsDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['createdAt'];
        items.add(_FeedItem(
          type: _FeedType.news,
          doc: doc,
          title: data['title'] ?? '-',
          subtitle: data['content'] ?? '-',
          time: ts is Timestamp ? ts.toDate() : null,
          imageUrl: data['imageUrl'] as String?,
          link: data['link'] as String?,
        ));
      }
    }

    if (filter != FeedFilter.news) {
      for (final doc in reportDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['createdAt'];
        final room = (data['room'] ?? '').toString();
        final location = room.isEmpty
            ? '${data['building'] ?? '-'} · ${data['floor'] ?? '-'}'
            : '${data['building'] ?? '-'} · ${data['floor'] ?? '-'} · ห้อง $room';

        items.add(_FeedItem(
          type: _FeedType.report,
          doc: doc,
          title: location,
          subtitle: data['description'] ?? '-',
          time: ts is Timestamp ? ts.toDate() : null,
          severity: data['severity'],
          status: data['status'],
          imageUrl: data['imageUrl'] as String?,
        ));
      }
    }

    items.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;
      return b.time!.compareTo(a.time!);
    });

    return items;
  }

  /// ============================== [UI Helpers] ==============================
  String _formatDate(DateTime? time) {
    if (time == null) return '-';
    return '${time.day}/${time.month}/${time.year}';
  }

  Future<void> _openLink(String url) async {
    var normalized = url.trim();
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }
    final uri = Uri.tryParse(normalized);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// ============================== [Navigation Logic] ==============================
  // Open the admin management detail page — lets admin change status/severity or delete [_openReportDetail]
  void _openReportDetail(BuildContext context, _FeedItem item) {
    final data = item.doc.data() as Map<String, dynamic>;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminReportDetailPage(
          reportId: item.doc.id,
          data: data,
        ),
      ),
    );
  }

  // Bottom sheet: choose "ข่าวสาร" or "แจ้งปัญหา" before creating [_showCreateChooser]
  void _showCreateChooser(BuildContext context) {
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
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            ),
            const Text('เพิ่มประกาศใหม่', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            _buildChooserOption(
              icon: Icons.campaign_rounded,
              label: 'ข่าวสาร',
              subtitle: 'ประกาศทั่วไปสำหรับผู้ใช้',
              onTap: () {
                Navigator.pop(ctx);
                _openNewsForm(context);
              },
            ),
            const SizedBox(height: 12),
            _buildChooserOption(
              icon: Icons.report_rounded,
              label: 'แจ้งปัญหา',
              subtitle: 'สร้างรายการแจ้งซ่อม',
              onTap: () {
                Navigator.pop(ctx);
                showAdminReportForm(context);
              },
            ),
          ],
        ),
      ),
    );
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
            child: Icon(Icons.campaign_outlined, size: 40, color: emasColor.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 14),
          Text('ยังไม่มีประกาศ',
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFeedCard(BuildContext context, _FeedItem item) {
    if (item.type == _FeedType.news) {
      return _buildNewsCard(context, item);
    }
    return _buildReportCard(context, item);
  }

  Widget _buildNewsCard(BuildContext context, _FeedItem item) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final hasLink = item.link != null && item.link!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: emasColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
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
                    decoration: BoxDecoration(color: emasColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.campaign_rounded, color: emasColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(item.subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(_formatDate(item.time), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
                        child: Icon(Icons.edit_rounded, size: 19, color: Colors.grey.shade500),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _deleteNews(context, item.doc.id),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.delete_outline_rounded, size: 19, color: Colors.red.shade400),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.link!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, color: Colors.blue, decoration: TextDecoration.underline),
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

  Widget _buildReportCard(BuildContext context, _FeedItem item) {
    final data = item.doc.data() as Map<String, dynamic>;
    final isAdminCreated = data['createdBy'] == 'admin';
    final statusColor = getStatusColors(item.status ?? ReportStatus.pending).fg;
    final severity = getSeverityInfo(item.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openReportDetail(context, item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(item.imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          if (isAdminCreated) ...[
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: emasColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: emasColorDarker,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          _buildSeverityBadge(severity),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusChip(item.status ?? ReportStatus.pending),
                          const SizedBox(width: 8),
                          Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(_formatDate(item.time), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 24),
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
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 24),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(SeverityInfo severity) {
    final isHigh = severity.label == severityLevels['high']!.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: severity.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: severity.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isHigh
              ? Text('!', style: TextStyle(color: severity.color, fontSize: 12, fontWeight: FontWeight.w900, height: 1))
              : Container(width: 7, height: 7, decoration: BoxDecoration(color: severity.color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(severity.label, style: TextStyle(color: severity.color, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final colors = getStatusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: colors.fg, fontSize: 10.5, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildChooserOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: emasColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: emasColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  /// ============================== [News Logic] ==============================
  // Opens the full-page news composer (create or edit) instead of the old small AlertDialog [_openNewsForm]
  void _openNewsForm(BuildContext context, {QueryDocumentSnapshot? doc}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NewsFormPage(adminService: _adminService, doc: doc),
      ),
    );
  }

  void _deleteNews(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
        ),
        title: const Text('ยืนยันการลบ'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await _adminService.deleteNews(docId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// ============================== [Feed Model] ==============================
enum _FeedType { news, report }

class _FeedItem {
  final _FeedType type;
  final QueryDocumentSnapshot doc;
  final String title;
  final String subtitle;
  final DateTime? time;
  final String? severity;
  final String? status;
  final String? imageUrl;
  final String? link;

  _FeedItem({
    required this.type,
    required this.doc,
    required this.title,
    required this.subtitle,
    required this.time,
    this.severity,
    this.status,
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
  String? _originalImageUrl; // image already on the doc when editing (immutable snapshot)
  bool _imageRemoved = false; // true if the admin cleared the existing image without picking a new one
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
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1600);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
        _imageRemoved = false; // a freshly picked image supersedes any "removed" state
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
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: emasColor),
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

  /// ============================== [Save] ==============================
  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกหัวข้อ')),
      );
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

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
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
        title: Text(_isEdit ? 'แก้ไขประกาศ' : 'เพิ่มประกาศ',
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                        )
                      : Text(_isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มประกาศ',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Colors.black87));
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
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
          prefixIcon: icon != null ? Icon(icon, color: emasColor, size: 20) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: emasColor, width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final hasNewImage = _pickedImage != null;
    final hasExistingImage = !hasNewImage &&
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
            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 34, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text('เพิ่มรูปภาพ', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
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
          top: 8,
          right: 8,
          child: Row(
            children: [
              _buildImageActionButton(Icons.edit_rounded, _showImageSourceSheet),
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
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
        child: Icon(icon, size: 17, color: Colors.white),
      ),
    );
  }
}