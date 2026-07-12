import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                _showNewsDialog(context);
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
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(item.subtitle,
                      maxLines: 2,
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
                  onTap: () => _showNewsDialog(context, doc: item.doc),
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

  _FeedItem({
    required this.type,
    required this.doc,
    required this.title,
    required this.subtitle,
    required this.time,
    this.severity,
    this.status,
    this.imageUrl,
  });
}
