import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_announcements.dart';
import 'admin_report_list.dart';
import 'admin_report_form.dart';
import 'admin_report_detail.dart';
import '../services/admin_service.dart';

import '../../shared/constants/emas_colors.dart';

// Admin shell: bottom nav across Dashboard / Report List / Announcements [AdminMainPage]
class AdminMainPage extends StatefulWidget {
  final bool autoOpenReportForm;

  const AdminMainPage({super.key, this.autoOpenReportForm = false});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {

  /// ============================== [State] ==============================
  int _selectedIndex = 0;

  // Which status tab AdminReportListPage should open on, and which scope
  // (ทั้งหมด/ผู้ใช้/แอดมิน) sub-tab it starts on. Both set together from the
  // dashboard's scope-chooser bottom sheet (_openReportList). Bumping either
  // changes the page's key below, forcing a fresh TabController + sub-tab
  // state with the new initial values. [_reportListTabIndex, _reportListScope]
  int _reportListTabIndex = 0;
  ReportScopeFilter _reportListScope = ReportScopeFilter.all;

  // Nav item metadata, used to build both destinations + track label [_navItems]
  static const _navItems = [
    (icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded, label: 'แดชบอร์ด'),
    (icon: Icons.list_alt_outlined, selectedIcon: Icons.list_alt_rounded, label: 'รายการแจ้งซ่อม'),
    (icon: Icons.newspaper_outlined, selectedIcon: Icons.newspaper_rounded, label: 'ประกาศ'),
  ];

  /// ============================== [Life Cycle] ==============================
  @override
  void initState() {
    super.initState();
    if (widget.autoOpenReportForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showAdminReportForm(context);
      });
    }
  }

  /// ============================== [Navigation Logic] ==============================
  // Current tab's page [_currentPage]
  Widget _currentPage() {
    switch (_selectedIndex) {
      case 0:
        return _AdminDashboard(onOpenReportList: _openReportList);
      case 1:
        return AdminReportListPage(
          key: ValueKey('$_reportListTabIndex-$_reportListScope'),
          initialTabIndex: _reportListTabIndex,
          initialScope: _reportListScope,
        );
      case 2:
      default:
        return const AdminAnnouncementsPage();
    }
  }

  // Called after the dashboard's scope-chooser bottom sheet resolves — switch
  // to the "รายการแจ้งซ่อม" bottom-nav tab directly on the matching status +
  // scope. No push, no back button — the bottom nav bar stays visible, same
  // as tapping the nav item manually. [_openReportList]
  void _openReportList(int tabIndex, ReportScopeFilter scope) {
    setState(() {
      _selectedIndex = 1;
      _reportListTabIndex = tabIndex;
      _reportListScope = scope;
    });
  }

  // Global "เพิ่มประกาศ" bottom sheet — reachable from every admin tab (the
  // FAB below is at the Scaffold level, not per-page). Finishing either flow
  // switches straight to the page showing what was just created: a news post
  // lands on "ประกาศ", a report lands on "รายการแจ้งซ่อม". [_showCreateChooser]
  void _showCreateChooser() {
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
                _createNews();
              },
            ),
            const SizedBox(height: 12),
            _buildChooserOption(
              icon: Icons.report_rounded,
              label: 'แจ้งปัญหา',
              subtitle: 'สร้างรายการแจ้งซ่อม',
              onTap: () {
                Navigator.pop(ctx);
                _createReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Push NewsFormPage; it pops `true` on successful save, so land on ประกาศ [_createNews]
  Future<void> _createNews() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NewsFormPage(adminService: AdminService())),
    );
    if (saved == true && mounted) {
      setState(() => _selectedIndex = 2);
    }
  }

  // showAdminReportForm now resolves `true` only on a real save (its
  // _submit pops with true; closing via the X button pops null) — so this
  // only switches tabs when a report was actually created. [_createReport]
  Future<void> _createReport() async {
    final saved = await showAdminReportForm(context);
    if (saved == true && mounted) {
      setState(() => _selectedIndex = 1);
    }
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Admin Dashboard',
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
      ),
      body: _currentPage(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: emasColor,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('เพิ่มประกาศ', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: _showCreateChooser,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// ============================== [Widgets] ==============================
  // Row inside the create-chooser bottom sheet [_buildChooserOption]
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

  // Themed bottom nav bar, pill-style selected indicator matching brand color [_buildBottomNav]
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < _navItems.length; i++)
                Expanded(child: _buildNavItem(i)),
            ],
          ),
        ),
      ),
    );
  }

  // Single bottom nav destination [_buildNavItem]
  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? emasColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.selectedIcon : item.icon,
              color: isSelected ? emasColor : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? emasColor : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Per-status counts split by who created the report — feeds the stat card's
// "user/admin" display. Purely informational now; tapping a card always
// opens "ทั้งหมด" and the admin can switch scope from the sub-tabs there. [_StatusCount]
class _StatusCount {
  final int user;
  final int admin;
  const _StatusCount({this.user = 0, this.admin = 0});
  int get total => user + admin;
}

// Dashboard tab: stats + trend chart + recent activity, all live from Firestore streams [_AdminDashboard]
class _AdminDashboard extends StatelessWidget {
  final void Function(int tabIndex, ReportScopeFilter scope) onOpenReportList;

  const _AdminDashboard({required this.onOpenReportList});

  /// ============================== [Controllers & Services] ==============================
  static final _adminService = AdminService();

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _adminService.reportsStream(),
      builder: (context, reportSnap) {
        if (reportSnap.hasError) {
          return Center(
            child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล',
                style: TextStyle(color: Colors.red.shade400)),
          );
        }

        final reportDocs = reportSnap.data?.docs ?? [];

        // Status counts tallied client-side from the raw stream, split by
        // who created each report (user vs admin) [pending, inProgress, done]
        int pendingUser = 0, pendingAdmin = 0;
        int inProgressUser = 0, inProgressAdmin = 0;
        int doneUser = 0, doneAdmin = 0;

        for (final doc in reportDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';
          final isAdminCreated = data['createdBy'] == 'admin';

          if (status == 'รอดำเนินการ') {
            isAdminCreated ? pendingAdmin++ : pendingUser++;
          } else if (status == 'กำลังดำเนินการ') {
            isAdminCreated ? inProgressAdmin++ : inProgressUser++;
          } else if (status == 'เสร็จสิ้น') {
            isAdminCreated ? doneAdmin++ : doneUser++;
          }
        }

        final pending = _StatusCount(user: pendingUser, admin: pendingAdmin);
        final inProgress = _StatusCount(user: inProgressUser, admin: inProgressAdmin);
        final done = _StatusCount(user: doneUser, admin: doneAdmin);

        return StreamBuilder<QuerySnapshot>(
          stream: _adminService.newsStream(),
          builder: (context, newsSnap) {
            final newsDocs = newsSnap.data?.docs ?? [];
            final activity = _buildActivityItems(reportDocs, newsDocs);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCard(reportDocs.length),
                  const SizedBox(height: 22),

                  const Text('ภาพรวม',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'รอดำเนินการ',
                          counts: pending,
                          color: Colors.orange,
                          icon: Icons.pending_actions_rounded,
                          onTap: () => _openScopeChooser(context, 0, 'รอดำเนินการ', pending),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          title: 'กำลังดำเนินการ',
                          counts: inProgress,
                          color: Colors.blue,
                          icon: Icons.engineering_rounded,
                          onTap: () => _openScopeChooser(context, 1, 'กำลังดำเนินการ', inProgress),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          title: 'เสร็จสิ้น',
                          counts: done,
                          color: Colors.green,
                          icon: Icons.check_circle_rounded,
                          onTap: () => _openScopeChooser(context, 2, 'เสร็จสิ้น', done),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _TrendSection(reportDocs: reportDocs),
                  const SizedBox(height: 24),

                  const Text('กิจกรรมล่าสุด',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildActivityCard(context, activity),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// ============================== [Data] ==============================
  // Merge reports + news into a single feed, newest first, capped at 8 items [_buildActivityItems]
  List<_ActivityItem> _buildActivityItems(
    List<QueryDocumentSnapshot> reportDocs,
    List<QueryDocumentSnapshot> newsDocs,
  ) {
    final items = <_ActivityItem>[];

    for (final doc in reportDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'];
      items.add(_ActivityItem(
        type: _ActivityType.report,
        title: '${data['building'] ?? '-'} · ${data['floor'] ?? '-'}',
        subtitle: data['description'] ?? '-',
        time: ts is Timestamp ? ts.toDate() : null,
        status: data['status'],
        docId: doc.id,
        data: data,
      ));
    }

    for (final doc in newsDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'];
      items.add(_ActivityItem(
        type: _ActivityType.news,
        title: data['title'] ?? '-',
        subtitle: data['content'] ?? '-',
        time: ts is Timestamp ? ts.toDate() : null,
        docId: doc.id,
        data: data,
      ));
    }

    items.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;
      return b.time!.compareTo(a.time!);
    });

    return items.take(8).toList();
  }

  /// ============================== [UI Helpers] ==============================
  // "x นาทีที่แล้ว" / "x ชม.ที่แล้ว" / "x วันที่แล้ว" relative time, no intl dependency [_relativeTime]
  String _relativeTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชม.ที่แล้ว';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
    return '${time.day}/${time.month}/${time.year}';
  }

  // "ใหม่" badge if posted within the last 24 hours [_isRecent]
  bool _isRecent(DateTime? time) {
    if (time == null) return false;
    final diff = DateTime.now().difference(time);
    return diff.inHours < 24 && !diff.isNegative;
  }

  /// ============================== [Navigation Logic] ==============================
  // Report items → AdminReportDetailPage. News items have no dedicated detail page here. [_openActivityDetail]
  void _openActivityDetail(BuildContext context, _ActivityItem item) {
    if (item.type != _ActivityType.report) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminReportDetailPage(reportId: item.docId, data: item.data),
      ),
    );
  }

  // Bottom sheet: choose ทั้งหมด/ผู้ใช้/แอดมิน before switching to the
  // "รายการแจ้งซ่อม" tab on the given status. Skips the sheet when only one
  // scope has any items — no point asking when there's only one place to go. [_openScopeChooser]
  void _openScopeChooser(
    BuildContext context,
    int tabIndex,
    String status,
    _StatusCount counts,
  ) {
    if (counts.total == 0) return;

    if (counts.admin == 0) {
      onOpenReportList(tabIndex, ReportScopeFilter.user);
      return;
    }
    if (counts.user == 0) {
      onOpenReportList(tabIndex, ReportScopeFilter.admin);
      return;
    }

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
            Text('ดูรายการ "$status"', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            _buildScopeOption(
              icon: Icons.apps_rounded,
              label: 'ทั้งหมด',
              subtitle: '${counts.total} รายการทั้งหมด',
              onTap: () {
                Navigator.pop(ctx);
                onOpenReportList(tabIndex, ReportScopeFilter.all);
              },
            ),
            const SizedBox(height: 12),
            _buildScopeOption(
              icon: Icons.person_rounded,
              label: 'ผู้ใช้',
              subtitle: '${counts.user} รายการที่ผู้ใช้แจ้งเข้ามา',
              onTap: () {
                Navigator.pop(ctx);
                onOpenReportList(tabIndex, ReportScopeFilter.user);
              },
            ),
            const SizedBox(height: 12),
            _buildScopeOption(
              icon: Icons.admin_panel_settings_rounded,
              label: 'แอดมิน',
              subtitle: '${counts.admin} รายการที่แอดมินสร้างเอง',
              onTap: () {
                Navigator.pop(ctx);
                onOpenReportList(tabIndex, ReportScopeFilter.admin);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ============================== [Widgets] ==============================
  // Greeting hero card, gradient uses emasColor/emasColorDarker directly [_buildHeroCard]
  Widget _buildHeroCard(int totalCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [emasColor, emasColorDarker],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: emasColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.waving_hand_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('สวัสดี, Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Text('รายการทั้งหมด $totalCount รายการ',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
        ],
      ),
    );
  }

  // Recent activity card: report + news items merged into one feed [_buildActivityCard]
  Widget _buildActivityCard(BuildContext context, List<_ActivityItem> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text('ยังไม่มีกิจกรรม', style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final item in items) ...[
          _buildActivityTile(context, item),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  // Single activity row: left border by status/news, badge for recent items,
  // tappable → detail page for reports only [_buildActivityTile]
  Widget _buildActivityTile(BuildContext context, _ActivityItem item) {
    final isReport = item.type == _ActivityType.report;
    final borderColor = isReport ? _reportStatusColor(item.status) : emasColor;
    final isRecent = _isRecent(item.time);

    return Container(
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
          onTap: isReport ? () => _openActivityDetail(context, item) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isReport ? Icons.report_rounded : Icons.campaign_rounded,
                    size: 17,
                    color: borderColor,
                  ),
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
                            child: Text(item.title,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                          ),
                          if (isRecent) ...[
                            const SizedBox(width: 6),
                            _buildNewBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(_relativeTime(item.time),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                if (isReport) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Small pink "ใหม่" pill for items posted within the last 24 hours [_buildNewBadge]
  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: emasColor, borderRadius: BorderRadius.circular(20)),
      child: const Text('ใหม่', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700)),
    );
  }

  // Accent color per report status, used for the activity icon badge + left border [_reportStatusColor]
  Color _reportStatusColor(String? status) {
    switch (status) {
      case 'รอดำเนินการ': return Colors.orange;
      case 'กำลังดำเนินการ': return Colors.blue;
      case 'เสร็จสิ้น': return Colors.green;
      default: return emasColor;
    }
  }

  // Row inside the scope-chooser bottom sheet — matches _buildChooserOption's
  // style in admin_announcements.dart [_buildScopeOption]
  Widget _buildScopeOption({
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
}

// Feed entry kind: report or news [_ActivityType]
enum _ActivityType { report, news }

// One merged feed entry shown in the activity card [_ActivityItem]
class _ActivityItem {
  final _ActivityType type;
  final String title;
  final String subtitle;
  final DateTime? time;
  final String? status;
  final String docId;
  final Map<String, dynamic> data;

  _ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.docId,
    required this.data,
    this.status,
  });
}

// Simple bar-chart painter for the 7-day trend, avoids adding a chart package dependency [_TrendChartPainter]
class _TrendChartPainter extends CustomPainter {
  final List<int> counts;
  final int maxVal;
  final Color barColor;

  _TrendChartPainter({
    required this.counts,
    required this.maxVal,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (counts.isEmpty) return;

    final barWidth = size.width / counts.length;
    final barPaint = Paint()..color = barColor;
    final trackPaint = Paint()..color = barColor.withValues(alpha: 0.08);

    for (var i = 0; i < counts.length; i++) {
      final ratio = counts[i] / maxVal;
      final barHeight = size.height * ratio.clamp(0.04, 1.0);
      final left = i * barWidth + barWidth * 0.28;
      final right = (i + 1) * barWidth - barWidth * 0.28;

      final trackRect = RRect.fromLTRBR(
        left, 0, right, size.height,
        const Radius.circular(6),
      );
      canvas.drawRRect(trackRect, trackPaint);

      final barRect = RRect.fromLTRBR(
        left, size.height - barHeight, right, size.height,
        const Radius.circular(6),
      );
      canvas.drawRRect(barRect, barPaint);

      if (counts[i] > 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${counts[i]}',
            style: TextStyle(
              color: barColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(
            left + (right - left - textPainter.width) / 2,
            size.height - barHeight - textPainter.height - 4,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.counts != counts || oldDelegate.maxVal != maxVal;
  }
}

// Date range for the trend chart — week buckets by day, month buckets by
// 7-day window within the last 4 weeks. [_TrendPeriod]
enum _TrendPeriod { week, month }

// Bar (existing custom painter) vs line (new below), toggled independently
// of the period. [_ChartMode]
enum _ChartMode { bar, line }

// Bucketed counts + their axis labels for whichever period is selected [_TrendData]
class _TrendData {
  final List<int> counts;
  final List<String> labels;
  const _TrendData({required this.counts, required this.labels});
}

// Trend chart card: period picker (สัปดาห์/เดือน) + chart-mode toggle
// (bar/line) sitting above the custom-painted chart. Holds its own local UI
// state since neither selection needs to survive outside this card. [_TrendSection]
class _TrendSection extends StatefulWidget {
  final List<QueryDocumentSnapshot> reportDocs;

  const _TrendSection({required this.reportDocs});

  @override
  State<_TrendSection> createState() => _TrendSectionState();
}

class _TrendSectionState extends State<_TrendSection> {
  /// ============================== [State] ==============================
  _TrendPeriod _period = _TrendPeriod.week;
  _ChartMode _mode = _ChartMode.bar;

  // Calendar month shown in "เดือน" mode — defaults to the current month,
  // changeable via the month/year picker dialog. Only relevant to
  // _buildMonthData; "สัปดาห์" mode always shows the trailing 7 days. [_selectedMonth]
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // Thai short weekday labels, index 0 = Monday — used in สัปดาห์ mode [_weekdayLabels]
  static const _weekdayLabels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

  // Thai month names, full + 3-letter abbreviation — no intl dependency,
  // same approach as the rest of the app's date formatting. [_thaiMonths, _thaiMonthsShort]
  static const _thaiMonths = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];
  static const _thaiMonthsShort = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  /// ============================== [Data] ==============================
  // Bucket report counts for the selected period [_buildData]
  _TrendData _buildData() {
    return _period == _TrendPeriod.week ? _buildWeekData() : _buildMonthData();
  }

  // Daily buckets for the last 7 days (oldest → newest) [_buildWeekData]
  _TrendData _buildWeekData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final counts = List<int>.filled(7, 0);

    for (final doc in widget.reportDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'];
      if (ts is! Timestamp) continue;

      final d = ts.toDate();
      final day = DateTime(d.year, d.month, d.day);
      final diff = today.difference(day).inDays;

      if (diff >= 0 && diff < 7) {
        counts[6 - diff]++;
      }
    }

    final labels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return _weekdayLabels[d.weekday - 1];
    });

    return _TrendData(counts: counts, labels: labels);
  }

  // Weekly buckets within the selected calendar month (oldest → newest).
  // Number of buckets varies with the month's length (4 or 5). [_buildMonthData]
  _TrendData _buildMonthData() {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final bucketCount = (daysInMonth / 7).ceil();
    final counts = List<int>.filled(bucketCount, 0);

    for (final doc in widget.reportDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'];
      if (ts is! Timestamp) continue;

      final d = ts.toDate();
      if (d.year != year || d.month != month) continue;

      final bucket = ((d.day - 1) ~/ 7).clamp(0, bucketCount - 1);
      counts[bucket]++;
    }

    final labels = List.generate(bucketCount, (i) => 'สัปดาห์ ${i + 1}');
    return _TrendData(counts: counts, labels: labels);
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    final data = _buildData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('แนวโน้มการแจ้งซ่อม',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            _buildModeToggle(),
          ],
        ),
        const SizedBox(height: 10),
        _buildPeriodTabs(),
        if (_period == _TrendPeriod.month) ...[
          const SizedBox(height: 10),
          _buildMonthSelector(),
        ],
        const SizedBox(height: 12),
        _buildChartCard(data.counts, data.labels),
      ],
    );
  }

  /// ============================== [Widgets] ==============================
  // Segmented control for สัปดาห์/เดือน — same sliding-pill pattern as the
  // ทั้งหมด/ผู้ใช้/แอดมิน scope tabs in AdminReportListPage. [_buildPeriodTabs]
  Widget _buildPeriodTabs() {
    final selectedIndex = _TrendPeriod.values.indexOf(_period);

    return Container(
      height: 36,
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
          final segmentWidth = constraints.maxWidth / _TrendPeriod.values.length;
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
                  Expanded(child: _buildPeriodChip(_TrendPeriod.week, 'สัปดาห์')),
                  Expanded(child: _buildPeriodChip(_TrendPeriod.month, 'เดือน')),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodChip(_TrendPeriod p, String label) {
    final isSelected = _period == p;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _period = p),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade500,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  // Chip showing the currently selected calendar month — tap opens the
  // month/year picker dialog. Only shown in "เดือน" mode. [_buildMonthSelector]
  Widget _buildMonthSelector() {
    return GestureDetector(
      onTap: _showMonthYearPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month_rounded, size: 16, color: emasColor),
            const SizedBox(width: 6),
            Text(
              '${_thaiMonths[_selectedMonth.month - 1]} ${_selectedMonth.year}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: emasColorDarker),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // Custom month/year picker — a year stepper above a 3x4 grid of months.
  // No calendar package dependency, matches the app's other custom pickers. [_showMonthYearPicker]
  void _showMonthYearPicker() {
    int pickerYear = _selectedMonth.year;
    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: emasColor,
                      onPressed: () => setDialogState(() => pickerYear--),
                    ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        '$pickerYear',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: emasColor,
                      // Can't view trend data for years that haven't happened yet [pickerYear < now.year]
                      onPressed: pickerYear < now.year ? () => setDialogState(() => pickerYear++) : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.8,
                  children: List.generate(12, (i) {
                    final m = i + 1;
                    final isSelected = pickerYear == _selectedMonth.year && m == _selectedMonth.month;
                    // Same reasoning as the year arrow — no data exists for future months [isFuture]
                    final isFuture = pickerYear == now.year && m > now.month;

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: isFuture
                          ? null
                          : () {
                              setState(() => _selectedMonth = DateTime(pickerYear, m));
                              Navigator.pop(ctx);
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? emasColor : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _thaiMonthsShort[i],
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isFuture ? Colors.grey.shade300 : Colors.grey.shade700),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bar/line toggle — two small icon buttons, active one filled emasColor [_buildModeToggle]
  Widget _buildModeToggle() {
    return Container(
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(_ChartMode.bar, Icons.bar_chart_rounded),
          _buildModeButton(_ChartMode.line, Icons.show_chart_rounded),
        ],
      ),
    );
  }

  Widget _buildModeButton(_ChartMode m, IconData icon) {
    final isSelected = _mode == m;
    return GestureDetector(
      onTap: () => setState(() => _mode = m),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? emasColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey.shade400),
      ),
    );
  }

  // Chart card: swaps between the bar painter and the line painter, labels
  // beneath adapt to whichever period is selected [_buildChartCard]
  Widget _buildChartCard(List<int> counts, List<String> labels) {
    final maxVal = counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 110,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: CustomPaint(
                key: ValueKey('$_mode-$_period'),
                size: Size.infinite,
                painter: _mode == _ChartMode.bar
                    ? _TrendChartPainter(
                        counts: counts,
                        maxVal: maxVal == 0 ? 1 : maxVal,
                        barColor: emasColor,
                      )
                    : _LineChartPainter(
                        counts: counts,
                        maxVal: maxVal == 0 ? 1 : maxVal,
                        lineColor: emasColor,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final label in labels)
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }
}

// Line-chart painter for the trend data: filled area + stroked polyline +
// dots, count labels above each point. Same no-package-dependency approach
// as _TrendChartPainter. [_LineChartPainter]
class _LineChartPainter extends CustomPainter {
  final List<int> counts;
  final int maxVal;
  final Color lineColor;

  _LineChartPainter({
    required this.counts,
    required this.maxVal,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (counts.isEmpty) return;

    const topPadding = 22.0; // room for the count label above the highest point
    final chartHeight = size.height - topPadding;
    final stepX = counts.length > 1 ? size.width / (counts.length - 1) : size.width;

    final points = <Offset>[];
    for (var i = 0; i < counts.length; i++) {
      final ratio = counts[i] / maxVal;
      final y = topPadding + chartHeight * (1 - ratio.clamp(0.0, 1.0));
      final x = counts.length > 1 ? i * stepX : size.width / 2;
      points.add(Offset(x, y));
    }

    // Filled area under the line [fillPath]
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withValues(alpha: 0.18), lineColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Stroked polyline [linePath]
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots + count labels [dots]
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 4, Paint()..color = lineColor);
      canvas.drawCircle(p, 4, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);

      if (counts[i] > 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${counts[i]}',
            style: TextStyle(color: lineColor, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(p.dx - textPainter.width / 2, p.dy - 18));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.counts != counts || oldDelegate.maxVal != maxVal;
  }
}

// Single stat tile: icon + user/admin split count + label. Tappable —
// pushes AdminReportListPage on the matching status tab, "ทั้งหมด" sub-tab. [_StatCard]
class _StatCard extends StatelessWidget {
  final String title;
  final _StatusCount counts;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.counts,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: counts.total == 0 ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text('${counts.user}/${counts.admin}',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text('ผู้ใช้/แอดมิน',
                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
