import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_report_form.dart';
import '../services/admin_service.dart';
import '../../shared/constants/emas_colors.dart';

// News-only announcements feed. Admin-created reports used to be merged in
// here — they now live in AdminReportListPage alongside user reports, with
// a ทั้งหมด/ผู้ใช้/แอดมิน sub-filter, so this page is a pure news feed. [AdminAnnouncementsPage]
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

          if (newsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final newsDocs = newsSnap.data?.docs ?? [];

          if (newsDocs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            itemCount: newsDocs.length,
            itemBuilder: (context, index) => _buildNewsCard(context, newsDocs[index]),
          );
        },
      ),
    );
  }

  /// ============================== [UI Helpers] ==============================
  String _formatDate(dynamic createdAt) {
    if (createdAt is! Timestamp) return '-';
    final d = createdAt.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  // "ใหม่" badge if posted within the last 24 hours [_isRecent]
  bool _isRecent(dynamic createdAt) {
    if (createdAt is! Timestamp) return false;
    final diff = DateTime.now().difference(createdAt.toDate());
    return diff.inHours < 24 && !diff.isNegative;
  }

  /// ============================== [Navigation Logic] ==============================
  // Bottom sheet: choose "ข่าวสาร" or "แจ้งปัญหา" before creating. The
  // "แจ้งปัญหา" shortcut still creates an admin report (via AdminService) —
  // it just now shows up in AdminReportListPage instead of this feed. [_showCreateChooser]
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
                _showNewsDialog(context);
              },
            ),
            const SizedBox(height: 12),
            _buildChooserOption(
              icon: Icons.report_rounded,
              label: 'แจ้งปัญหา',
              subtitle: 'สร้างรายการแจ้งซ่อม (ไปอยู่ในหน้า "รายการแจ้งซ่อม")',
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

  Widget _buildNewsCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? '-';
    final content = data['content'] ?? '-';
    final createdAt = data['createdAt'];
    final isRecent = _isRecent(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: emasColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.campaign_rounded, color: emasColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      if (isRecent) ...[
                        const SizedBox(width: 6),
                        _buildNewBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(_formatDate(createdAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _showNewsDialog(context, doc: doc),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.edit_rounded, size: 19, color: Colors.grey.shade500),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _deleteNews(context, doc.id),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.delete_outline_rounded, size: 19, color: Colors.red.shade400),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Small pink "ใหม่" pill for news posted within the last 24 hours [_buildNewBadge]
  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: emasColor, borderRadius: BorderRadius.circular(20)),
      child: const Text('ใหม่', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
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
  void _showNewsDialog(BuildContext context, {QueryDocumentSnapshot? doc}) {
    final titleCtrl = TextEditingController(
        text: doc != null ? (doc.data() as Map<String, dynamic>)['title'] ?? '' : '');
    final contentCtrl = TextEditingController(
        text: doc != null ? (doc.data() as Map<String, dynamic>)['content'] ?? '' : '');
    final isEdit = doc != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: emasColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(isEdit ? Icons.edit_rounded : Icons.add_circle_outline_rounded, color: emasColor),
        ),
        title: Text(isEdit ? 'แก้ไขข่าวสาร' : 'เพิ่มข่าวสารใหม่', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'หัวข้อ *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: emasColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'เนื้อหา',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: emasColor, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: emasColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;

              if (isEdit) {
                await _adminService.updateNews(
                  docId: doc!.id,
                  title: titleCtrl.text.trim(),
                  content: contentCtrl.text.trim(),
                );
              } else {
                await _adminService.addNews(
                  title: titleCtrl.text.trim(),
                  content: contentCtrl.text.trim(),
                );
              }

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'บันทึก' : 'เพิ่ม', style: const TextStyle(color: Colors.white)),
          ),
        ],
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
        content: const Text('ต้องการลบข่าวสารนี้หรือไม่?'),
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
