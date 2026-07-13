import 'dart:ui';
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

  // Filter for the announcements feed — owned here so it can be shown in the shared AppBar [_feedFilter]
  FeedFilter _feedFilter = FeedFilter.all;

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
  // Current tab's page, rebuilt so _AdminAnnouncementsPage gets the latest filter [_currentPage]
  Widget _currentPage() {
    switch (_selectedIndex) {
      case 0:
        return const _AdminDashboard();
      case 1:
        return const AdminReportListPage();
      case 2:
      default:
        return AdminAnnouncementsPage(filter: _feedFilter);
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
          'Admin Panel',
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
        actions: [
          // Filter pill only shows on the "ประกาศ" tab [_selectedIndex == 2]
          if (_selectedIndex == 2)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildFeedFilterButton(),
            ),
        ],
      ),
      body: _currentPage(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// ============================== [Widgets] ==============================
  // Glass filter pill, matches ReportListPage's status filter button style [_buildFeedFilterButton]
  Widget _buildFeedFilterButton() {
    return GestureDetector(
      onTap: () => showFeedFilterSheet(
        context,
        _feedFilter,
        (f) => setState(() => _feedFilter = f),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  feedFilterLabel(_feedFilter),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
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

// Dashboard tab: stats + trend chart + recent activity, all live from Firestore streams [_AdminDashboard]
class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard();

  /// ============================== [Controllers & Services] ==============================
  static final _adminService = AdminService();

  // Thai short weekday labels, index 0 = Monday, used by the trend chart [_weekdayLabels]
  static const _weekdayLabels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

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

        // Status counts tallied client-side from the raw stream [pending, inProgress, done]
        int pending = 0, inProgress = 0, done = 0;
        for (final doc in reportDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';
          if (status == 'รอดำเนินการ') {
            pending++;
          } else if (status == 'กำลังดำเนินการ') {
            inProgress++;
          } else if (status == 'เสร็จสิ้น') {
            done++;
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _adminService.newsStream(),
          builder: (context, newsSnap) {
            final newsDocs = newsSnap.data?.docs ?? [];
            final activity = _buildActivityItems(reportDocs, newsDocs);
            final trend = _buildTrendData(reportDocs);

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
                            count: pending,
                            color: Colors.orange,
                            icon: Icons.pending_actions_rounded),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                            title: 'กำลังดำเนินการ',
                            count: inProgress,
                            color: Colors.blue,
                            icon: Icons.engineering_rounded),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                            title: 'เสร็จสิ้น',
                            count: done,
                            color: Colors.green,
                            icon: Icons.check_circle_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('แนวโน้มการแจ้งซ่อม (7 วันล่าสุด)',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTrendCard(trend),
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

  // Bucket report counts by day for the last 7 days (oldest → newest) [_buildTrendData]
  List<int> _buildTrendData(List<QueryDocumentSnapshot> reportDocs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final counts = List<int>.filled(7, 0);

    for (final doc in reportDocs) {
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

    return counts;
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

  // Trend chart card wrapping the custom-painted bar chart [_buildTrendCard]
  Widget _buildTrendCard(List<int> counts) {
    final maxVal = counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b);
    final now = DateTime.now();

    // Weekday label for each of the last 7 days, oldest → newest [labels]
    final labels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return _weekdayLabels[d.weekday - 1];
    });

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
            child: CustomPaint(
              size: Size.infinite,
              painter: _TrendChartPainter(
                counts: counts,
                maxVal: maxVal == 0 ? 1 : maxVal,
                barColor: emasColor,
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

// Single stat tile: icon + count + label [_StatCard]
class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Text('$count',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
