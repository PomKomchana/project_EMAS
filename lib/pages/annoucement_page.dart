import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../report/pages/report_detail_page.dart';
import '../shared/constants/emas_colors.dart';
import '../shared/constants/report_constants.dart';

// Filter for announcement feed [FeedFilter]
enum _FeedType { news, report }

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

// One merged feed entry shown in the announcements list [_FeedItem]
class _FeedItem {
  final _FeedType type;
  final QueryDocumentSnapshot doc;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime? createdAt;
  final String? severity;
  final String? status;

  _FeedItem({
    required this.type,
    required this.doc,
    required this.title,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    this.severity,
    this.status,
  });
}

// Announcements feed: realtime list (news + admin reports).
// Report items open the shared ReportDetailPage; news items open a bottom sheet. [AnnouncementPage]
class AnnouncementPage extends StatefulWidget {
  final VoidCallback onMenuTap;

  const AnnouncementPage({super.key, required this.onMenuTap});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage>
    with TickerProviderStateMixin {

  /// ============================== [Controllers & Services] ==============================
  late final AnimationController _fadeController;
  late final AnimationController _shimmerController;
  late final List<Animation<double>> _fadeList;
  late final List<Animation<Offset>> _slideList;

  // Current selected feed filter [FeedFilter]
  FeedFilter _currentFilter = FeedFilter.all;

  /// ============================== [Life Cycle] ==============================
  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _fadeList = _buildStaggeredFadeList();
    _slideList = _buildStaggeredSlideList();

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  /// ============================== [Animation Logic] ==============================
  List<Animation<double>> _buildStaggeredFadeList() {
    return List.generate(20, (i) {
      final start = (i * 0.05).clamp(0.0, 0.9);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _fadeController, curve: Interval(start, 1.0, curve: Curves.easeOut)),
      );
    });
  }

  List<Animation<Offset>> _buildStaggeredSlideList() {
    return List.generate(20, (i) {
      final start = (i * 0.05).clamp(0.0, 0.9);
      return Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
        CurvedAnimation(parent: _fadeController, curve: Interval(start, 1.0, curve: Curves.easeOutCubic)),
      );
    });
  }

  /// ============================== [Data] ==============================
  // News stream, newest first [_newsStream]
  Stream<QuerySnapshot> _newsStream() {
    return FirebaseFirestore.instance
        .collection('news')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Admin-created reports, newest first [_adminReportsStream]
  Stream<QuerySnapshot> _adminReportsStream() {
    return FirebaseFirestore.instance
        .collection('reports')
        .where('createdBy', isEqualTo: 'admin')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Merge news + admin reports into one feed, newest first [_mergeFeed]
  List<_FeedItem> _mergeFeed(
    List<QueryDocumentSnapshot> newsDocs,
    List<QueryDocumentSnapshot> reportDocs,
  ) {
    final items = <_FeedItem>[];

    if (_currentFilter != FeedFilter.report) {
      for (final doc in newsDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['createdAt'];

        items.add(
          _FeedItem(
            type: _FeedType.news,
            doc: doc,
            title: data['title'] ?? '-',
            content: data['content'] ?? '',
            imageUrl: data['imageUrl'] as String?,
            createdAt: ts is Timestamp ? ts.toDate() : null,
          ),
        );
      }
    }

    if (_currentFilter != FeedFilter.news) {
      for (final doc in reportDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['createdAt'];

        final room = (data['room'] ?? '').toString();

        final location = room.isEmpty
            ? '${data['building'] ?? '-'} · ${data['floor'] ?? '-'}'
            : '${data['building'] ?? '-'} · ${data['floor'] ?? '-'} · ห้อง $room';

        items.add(
          _FeedItem(
            type: _FeedType.report,
            doc: doc,
            title: location,
            content: data['description'] ?? '-',
            imageUrl: data['imageUrl'] as String?,
            createdAt: ts is Timestamp ? ts.toDate() : null,
            severity: data['severity'],
            status: data['status'],
          ),
        );
      }
    }

    items.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return items;
  }

  /// ============================== [UI Helpers] ==============================
  bool _isRecent(DateTime? createdAt) {
    if (createdAt == null) return false;
    final diff = DateTime.now().difference(createdAt);
    return diff.inHours < 24 && !diff.isNegative;
  }

  String _formatDate(DateTime? createdAt) {
    if (createdAt == null) return '-';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  // Opens feed filter sheet [showFeedFilterSheet]
void _showFeedFilterSheet() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(24),
      ),
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
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'กรองประเภทประกาศ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              for (final f in FeedFilter.values)
                ListTile(
                  leading: Icon(
                    _currentFilter == f
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: emasColor,
                  ),
                  title: Text(feedFilterLabel(f)),
                  onTap: () {
                    setState(() {
                      _currentFilter = f;
                    });

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

  /// ============================== [Navigation Logic] ==============================
  // Report items → shared ReportDetailPage (same page the "รายการแจ้งปัญหา" tab uses) [_openReportDetail]
  void _openReportDetail(_FeedItem item) {
    final data = item.doc.data() as Map<String, dynamic>;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailPage(data: data, id: item.doc.id),
      ),
    );
  }

  // News items → bottom sheet (no dedicated news detail page exists) [_openNewsDetail]
  void _openNewsDetail(_FeedItem item) {
    final date = item.createdAt != null ? _formatDate(item.createdAt) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            if (date != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(date, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            Text(item.content,
                                style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey.shade800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: const Color(0xFFF2F2F7),

    appBar: AppBar(
      elevation: 0,
      centerTitle: false,
      foregroundColor: Colors.white,

      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: widget.onMenuTap,
      ),

      title: const Text(
        'ประกาศ',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),

      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list_rounded),
          tooltip: 'กรองประกาศ',
          onPressed: _showFeedFilterSheet,
        ),
      ],

      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              emasColor,
              emasColorDarker,
            ],
          ),
        ),
      ),
    ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _newsStream(),
        builder: (context, newsSnap) {
          if (newsSnap.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${newsSnap.error}'));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _adminReportsStream(),
            builder: (context, reportSnap) {
              if (reportSnap.hasError) {
                return Center(child: Text('เกิดข้อผิดพลาด: ${reportSnap.error}'));
              }

              if (newsSnap.connectionState == ConnectionState.waiting ||
                  reportSnap.connectionState == ConnectionState.waiting) {
                return _buildSkeletonList();
              }

              final newsDocs = newsSnap.data?.docs ?? [];
              final reportDocs = reportSnap.data?.docs ?? [];
              final items = _mergeFeed(newsDocs, reportDocs);

              if (items.isEmpty) {
                return RefreshIndicator(
                  color: emasColor,
                  onRefresh: _handleRefresh,
                  child: ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: _buildEmptyState(),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: emasColor,
                onRefresh: _handleRefresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final animIndex = index % _fadeList.length;
                    return FadeTransition(
                      opacity: _fadeList[animIndex],
                      child: SlideTransition(
                        position: _slideList[animIndex],
                        child: _buildFeedCard(items[index]),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// ============================== [Widgets] ==============================
  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final opacity = 0.4 + (_shimmerController.value * 0.5);
        return Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 180,
                        height: 12,
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 120,
                        height: 12,
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('ยังไม่มีประกาศ',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Dispatch to the right card style [_buildFeedCard]
  Widget _buildFeedCard(_FeedItem item) {
    if (item.type == _FeedType.news) {
      return _buildNewsCard(item);
    }
    return _buildReportCard(item);
  }

  // News card: circle icon, title/content, date. Matches AdminAnnouncementsPage's news card style [_buildNewsCard]
  Widget _buildNewsCard(_FeedItem item) {
    final isRecent = _isRecent(item.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openNewsDetail(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: emasColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.campaign_rounded, color: emasColor, size: 24),
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          if (isRecent) ...[
                            const SizedBox(width: 6),
                            _buildNewBadge(),
                          ],
                        ],
                      ),
                      if (item.content.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(item.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3)),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(_formatDate(item.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Report card: left border by status, thumbnail, admin badge, severity badge, status chip + date.
  // Every report in this feed is admin-created (query filter), so the "Admin" badge is unconditional. [_buildReportCard]
  Widget _buildReportCard(_FeedItem item) {
    final statusColor = getStatusColors(item.status ?? ReportStatus.pending).fg;
    final severity = getSeverityInfo(item.severity);
    final isRecent = _isRecent(item.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openReportDetail(item),
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

                          const SizedBox(width: 6),
                          _buildAdminBadge(),
                          const SizedBox(width: 6),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildSeverityBadge(severity),
                              if (isRecent) ...[
                                const SizedBox(height: 4),
                                _buildNewBadge(),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
                      Text(item.content,
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
                          Text(_formatDate(item.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: emasColor, borderRadius: BorderRadius.circular(20)),
      child: const Text('ใหม่', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  // Static "Admin" badge — every report in this feed is admin-created [_buildAdminBadge]
  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: emasColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Admin',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: emasColorDarker),
      ),
    );
  }

  Widget _buildSeverityBadge(SeverityInfo severity) {
    final isHigh = severity.label == severityLevels['high']!.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: severity.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: severity.color.withOpacity(0.4)),
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
}
