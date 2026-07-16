import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_report_detail.dart';
import 'admin_delete_confirm_dialog.dart' show showDeleteConfirmDialog;
import '../services/admin_service.dart';

import '../../shared/constants/emas_colors.dart';
import '../../shared/constants/report_constants.dart';

// Which reports to show — drives the ทั้งหมด/ผู้ใช้/แอดมิน sub-tabs. [ReportScopeFilter]
enum ReportScopeFilter { all, user, admin }

extension ReportScopeFilterLabel on ReportScopeFilter {
  String get label {
    switch (this) {
      case ReportScopeFilter.all: return 'ทั้งหมด';
      case ReportScopeFilter.user: return 'ผู้ใช้';
      case ReportScopeFilter.admin: return 'แอดมิน';
    }
  }
}

// Report list, tabbed by status (รอดำเนินการ / กำลังดำเนินการ / เสร็จสิ้น).
// Each status tab has its own ทั้งหมด/ผู้ใช้/แอดมิน sub-tabs, so user and
// admin reports live in one place. [AdminReportListPage]
//
// showAppBar: false (default) — used inside AdminMainPage's bottom nav,
// which already has its own AppBar.
// showAppBar: true — used standalone (e.g. from dashboard cards), shows
// its own AppBar with a back button.
class AdminReportListPage extends StatefulWidget {
  final int initialTabIndex;
  final ReportScopeFilter initialScope;
  final bool showAppBar;

  const AdminReportListPage({
    super.key,
    this.initialTabIndex = 0,
    this.initialScope = ReportScopeFilter.all,
    this.showAppBar = false,
  });

  @override
  State<AdminReportListPage> createState() => _AdminReportListPageState();
}

class _AdminReportListPageState extends State<AdminReportListPage>
    with SingleTickerProviderStateMixin {

  /// ============================== [Controllers & Services] ==============================
  late final TabController _tabController;

  /// ============================== [State] ==============================
  // Shared by all 3 status tabs — pick "ผู้ใช้" on one tab, it stays picked
  // when you swipe to another. [_scope]
  late ReportScopeFilter _scope = widget.initialScope;

  /// ============================== [Life Cycle] ==============================
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
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
      appBar: widget.showAppBar ? _buildAppBar() : null,
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
              children: [
                _StatusTabContent(
                  status: 'รอดำเนินการ',
                  scope: _scope,
                  onScopeChanged: (s) => setState(() => _scope = s),
                ),
                _StatusTabContent(
                  status: 'กำลังดำเนินการ',
                  scope: _scope,
                  onScopeChanged: (s) => setState(() => _scope = s),
                ),
                _StatusTabContent(
                  status: 'เสร็จสิ้น',
                  scope: _scope,
                  onScopeChanged: (s) => setState(() => _scope = s),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ============================== [Widgets] ==============================
  // AppBar shown only when pushed standalone [_buildAppBar]
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'รายการแจ้งซ่อม',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      centerTitle: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [emasColor, emasColorDarker],
          ),
        ),
      ),
      foregroundColor: Colors.white,
    );
  }
}

// One status tab: scope sub-tabs (ทั้งหมด/ผู้ใช้/แอดมิน) on top, list below.
// `scope` is owned by AdminReportListPage so it stays the same across all
// 3 status tabs. [_StatusTabContent]
class _StatusTabContent extends StatelessWidget {
  final String status;
  final ReportScopeFilter scope;
  final ValueChanged<ReportScopeFilter> onScopeChanged;

  const _StatusTabContent({
    required this.status,
    required this.scope,
    required this.onScopeChanged,
  });

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: _buildScopeTabs(),
        ),
        Expanded(
          child: _FilteredList(status: status, scope: scope),
        ),
      ],
    );
  }

  /// ============================== [Widgets] ==============================
  // Small tab bar for ทั้งหมด/ผู้ใช้/แอดมิน — an emasColor pill slides between
  // options, text fades white/grey. [_buildScopeTabs]
  Widget _buildScopeTabs() {
    final selectedIndex = ReportScopeFilter.values.indexOf(scope);

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / ReportScopeFilter.values.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: segmentWidth * selectedIndex,
                width: segmentWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: emasColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: emasColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final s in ReportScopeFilter.values) Expanded(child: _buildScopeChip(s)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScopeChip(ReportScopeFilter s) {
    final isSelected = scope == s;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onScopeChanged(s),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade500,
          ),
          child: Text(s.label),
        ),
      ),
    );
  }
}

// List of reports, filtered by status + scope, newest first [_FilteredList]
class _FilteredList extends StatelessWidget {
  final String status;
  final ReportScopeFilter scope;
  const _FilteredList({required this.status, required this.scope});

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

  // Apply the ทั้งหมด/ผู้ใช้/แอดมิน filter on top of the status list [_filterByScope]
  List<QueryDocumentSnapshot> _filterByScope(List<QueryDocumentSnapshot> docs) {
    if (scope == ReportScopeFilter.all) return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final isAdminCreated = data['createdBy'] == 'admin';
      return scope == ReportScopeFilter.admin ? isAdminCreated : !isAdminCreated;
    }).toList();
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt is! Timestamp) return '-';
    final d = createdAt.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  // "ใหม่" badge for reports made in the last 24 hours [_isRecent]
  bool _isRecent(dynamic createdAt) {
    if (createdAt is! Timestamp) return false;
    final diff = DateTime.now().difference(createdAt.toDate());
    return diff.inHours < 24 && !diff.isNegative;
  }

  /// ============================== [Report Actions Logic] ==============================
  // Ask for password, then delete — trash icon in the list [_deleteReport]
  Future<void> _deleteReport(BuildContext context, String docId) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'ยืนยันการลบ',
      message: 'กรุณากรอกรหัสผ่านเพื่อยืนยันการลบรายการนี้ การกระทำนี้ไม่สามารถย้อนกลับได้',
    );

    if (!confirmed) return;
    await _adminService.deleteReport(docId);
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

        final docs = _filterByScope(snapshot.data?.docs ?? []);

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
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
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
  // One report card: thumbnail, severity badge, status chip + date. Tags
  // admin-made reports with a small "Admin" pill. Pencil icon opens detail,
  // trash icon deletes — no more whole-card tap. [_buildReportCard]
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
    final isAdminCreated = data['createdBy'] == 'admin';

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
                      if (isAdminCreated) ...[
                        const SizedBox(width: 6),
                        _buildAdminBadge(),
                      ],
                      const SizedBox(width: 6),
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
                      if (isRecent) ...[
                        const SizedBox(width: 6),
                        _buildNewBadge(),
                      ],
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminReportDetailPage(reportId: docId, data: data),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.edit_rounded, size: 19, color: Colors.grey.shade500),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _deleteReport(context, docId),
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

  // Small pink "ใหม่" pill, sits next to the status chip [_buildNewBadge]
  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: emasColor, borderRadius: BorderRadius.circular(20)),
      child: const Text('ใหม่', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  // Small "Admin" pill for admin-made reports [_buildAdminBadge]
  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: emasColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Admin',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: emasColorDarker),
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
}
