import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_report_detail.dart';
import '../services/admin_service.dart';

import '../../shared/constants/emas_colors.dart';
import '../../shared/constants/report_constants.dart';

// Admin report list: tabbed by status ("รอดำเนินการ" / "กำลังดำเนินการ" / "เสร็จสิ้น").
// Shows only user-submitted reports — admin-created ones live in the "ประกาศ" tab. [AdminReportListPage]
class AdminReportListPage extends StatefulWidget {
  const AdminReportListPage({super.key});

  @override
  State<AdminReportListPage> createState() => _AdminReportListPageState();
}

class _AdminReportListPageState extends State<AdminReportListPage>
    with SingleTickerProviderStateMixin {

  /// ============================== [Controllers & Services] ==============================
  late final TabController _tabController;

  /// ============================== [Life Cycle] ==============================
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(vertical: 2),
              indicator: BoxDecoration(
                color: emasColor,
                borderRadius: BorderRadius.circular(10),
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'รอดำเนินการ'),
                Tab(text: 'กำลังดำเนินการ'),
                Tab(text: 'เสร็จสิ้น'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _FilteredList(status: 'รอดำเนินการ'),
                _FilteredList(status: 'กำลังดำเนินการ'),
                _FilteredList(status: 'เสร็จสิ้น'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// One tab's content: reports filtered by status, excludes admin-created, newest first [_FilteredList]
class _FilteredList extends StatelessWidget {
  final String status;
  const _FilteredList({required this.status});

  /// ============================== [Controllers & Services] ==============================
  static final _adminService = AdminService();

  /// ============================== [UI Helpers] ==============================
  Color _statusColor(String s) {
    switch (s) {
      case 'รอดำเนินการ': return Colors.orange;
      case 'กำลังดำเนินการ': return Colors.blue;
      case 'เสร็จสิ้น': return Colors.green;
      default: return emasColor;
    }
  }

  // Admin-created reports live in the "ประกาศ" tab now — exclude them here [_excludeAdminCreated]
  List<QueryDocumentSnapshot> _excludeAdminCreated(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['createdBy'] != 'admin';
    }).toList();
  }

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

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return StreamBuilder<QuerySnapshot>(
      stream: _adminService.reportsByStatusStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล',
                style: TextStyle(color: Colors.red.shade400)),
          );
        }

        final docs = _excludeAdminCreated(snapshot.data?.docs ?? []);

        if (docs.isEmpty) {
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
                  child: Icon(Icons.inbox_rounded, size: 40, color: emasColor.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 14),
                Text('ไม่มีรายการ "$status"',
                    style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildReportCard(context, doc.id, data, color);
          },
        );
      },
    );
  }

  /// ============================== [Widgets] ==============================
  // Full-info card: thumbnail, severity badge, status chip + date [_buildReportCard]
  Widget _buildReportCard(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    Color borderColor,
  ) {
    final building = data['building'] ?? '-';
    final floor = data['floor'] ?? '-';
    final room = data['room'] ?? '-';
    final desc = data['description'] ?? '-';
    final imageUrl = data['imageUrl'] as String?;
    final severity = getSeverityInfo(data['severity'] as String?);
    final date = _formatDate(data['createdAt']);
    final isRecent = _isRecent(data['createdAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminReportDetailPage(reportId: docId, data: data),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '$building · $floor · ห้อง $room',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isRecent) ...[
                            _buildNewBadge(),
                            const SizedBox(width: 6),
                          ],
                          _buildSeverityBadge(severity),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusChip(status),
                          const SizedBox(width: 8),
                          Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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

  // Small pink "ใหม่" pill for reports created within the last 24 hours [_buildNewBadge]
  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: emasColor, borderRadius: BorderRadius.circular(20)),
      child: const Text('ใหม่', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
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
}
