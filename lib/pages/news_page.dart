import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../shared/constants/emas_colors.dart';
import '../shared/constants/report_constants.dart';

// Feed entry kind: news post or admin-reported problem [_FeedType]
enum _FeedType { news, report }

// One merged feed entry shown in the announcements list [_FeedItem]
class _FeedItem {
  final _FeedType type;
  final String docId;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime? createdAt;
  final String? severity;
  final String? status;

  _FeedItem({
    required this.type,
    required this.docId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    this.severity,
    this.status,
  });
}

// Announcements feed: realtime list (news + admin reports) + tap-to-expand bottom sheet detail [NewsPage]
class NewsPage extends StatefulWidget {
  final VoidCallback onMenuTap;

  const NewsPage({super.key, required this.onMenuTap});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage>
    with TickerProviderStateMixin {

  /// ============================== [Controllers & Services] ==============================
  late final AnimationController _fadeController;
  late final AnimationController _shimmerController;
  late final List<Animation<double>> _fadeList;
  late final List<Animation<Offset>> _slideList;

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

    for (final doc in newsDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'];
      items.add(_FeedItem(
        type: _FeedType.news,
        docId: doc.id,
        title: data['title'] ?? '-',
        content: data['content'] ?? '',
        imageUrl: data['imageUrl'] as String?,
        createdAt: ts is Timestamp ? ts.toDate() : null,
      ));
    }

    for (final doc in reportDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'];
      final room = (data['room'] ?? '').toString();
      final location = room.isEmpty
          ? '${data['building'] ?? '-'} · ${data['floor'] ?? '-'}'
          : '${data['building'] ?? '-'} · ${data['floor'] ?? '-'} · ห้อง $room';

      items.add(_FeedItem(
        type: _FeedType.report,
        docId: doc.id,
        title: location,
        content: data['description'] ?? '-',
        createdAt: ts is Timestamp ? ts.toDate() : null,
        severity: data['severity'],
        status: data['status'],
      ));
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
    return diff.inHours < 48 && !diff.isNegative;
  }

  String? _formatDate(DateTime? createdAt) {
    if (createdAt == null) return null;
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  /// ============================== [Navigation Logic] ==============================
  // Bottom sheet showing full news content [_openNewsDetail]
  void _openNewsDetail(_FeedItem item) {
    final heroTag = 'news_image_${item.docId}';
    final date = _formatDate(item.createdAt);

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
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Hero(
                            tag: heroTag,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                item.imageUrl!,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            if (item.type == _FeedType.report) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _buildStatusChip(item.status ?? ReportStatus.pending),
                                  const SizedBox(width: 8),
                                  _buildSeverityChip(item.severity),
                                ],
                              ),
                            ],
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
        title: const Text('ประกาศ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [emasColor, emasColorDarker],
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
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
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

  // One feed card: thumbnail/icon, title, "ใหม่" badge, preview, date, status/severity for reports [_buildFeedCard]
  Widget _buildFeedCard(_FeedItem item) {
    final isReport = item.type == _FeedType.report;
    final isRecent = _isRecent(item.createdAt);
    final date = _formatDate(item.createdAt);
    final heroTag = 'news_image_${item.docId}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openNewsDetail(item),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.78),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isReport
                      ? _buildReportIcon(item.severity)
                      : _buildNewsThumbnail(heroTag, item.imageUrl),
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
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87)),
                            ),
                            if (isRecent) ...[
                              const SizedBox(width: 6),
                              _buildNewBadge(),
                            ],
                          ],
                        ),
                        if (item.content.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(item.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5)),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (isReport) ...[
                              _buildStatusChip(item.status ?? ReportStatus.pending),
                              const SizedBox(width: 8),
                            ],
                            if (date != null) ...[
                              Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
                ],
              ),
            ),
          ),
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

  Widget _buildStatusChip(String status) {
    final colors = getStatusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: colors.fg, fontSize: 10.5, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSeverityChip(String? severity) {
    final info = getSeverityInfo(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: info.color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(info.label, style: TextStyle(color: info.color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildNewsThumbnail(String heroTag, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildIconBadge(Icons.campaign_rounded, emasColor);
    }
    return Hero(
      tag: heroTag,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(width: 48, height: 48, color: Colors.grey.shade200);
          },
          errorBuilder: (context, error, stackTrace) => _buildIconBadge(Icons.campaign_rounded, emasColor),
        ),
      ),
    );
  }

  Widget _buildReportIcon(String? severity) {
    final info = getSeverityInfo(severity);
    return _buildIconBadge(Icons.report_rounded, info.color);
  }

  Widget _buildIconBadge(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
