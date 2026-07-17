import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared/constants/emas_colors.dart';

/// One news item shown in the announcements list [_NewsItem]
class _NewsItem {
  final QueryDocumentSnapshot doc;
  final String title;
  final String content;
  final String? imageUrl;
  final String? link;
  final DateTime? createdAt;

  _NewsItem({
    required this.doc,
    required this.title,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    this.link,
  });
}

/// Announcements feed: realtime news list.
/// News items open a bottom sheet with full content + optional image/link. [AnnouncementPage]
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
  /// News stream, newest first [_newsStream]
  Stream<QuerySnapshot> _newsStream() {
    return FirebaseFirestore.instance
        .collection('news')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Map raw docs into display-ready items [_buildNewsFeed]
  List<_NewsItem> _buildNewsFeed(List<QueryDocumentSnapshot> newsDocs) {
    final items = <_NewsItem>[];

    for (final doc in newsDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'];

      items.add(
        _NewsItem(
          doc: doc,
          title: data['title'] ?? '-',
          content: data['content'] ?? '',
          imageUrl: data['imageUrl'] as String?,
          link: data['link'] as String?,
          createdAt: ts is Timestamp ? ts.toDate() : null,
        ),
      );
    }

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

  /// Opens an external/attached link in the browser [_openLink]
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
  /// News items → bottom sheet with image (if any), content, and link (if any) [_openNewsDetail]
  void _openNewsDetail(_NewsItem item) {
    final date = item.createdAt != null ? _formatDate(item.createdAt) : null;
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final hasLink = item.link != null && item.link!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: hasImage ? 0.7 : 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
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
                      if (hasImage) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 32),
                                ),
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
                            if (hasLink) ...[
                              const SizedBox(height: 20),
                              _buildLinkButton(item.link!),
                            ],
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

          if (newsSnap.connectionState == ConnectionState.waiting) {
            return _buildSkeletonList();
          }

          final newsDocs = newsSnap.data?.docs ?? [];
          final items = _buildNewsFeed(newsDocs);

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
                    child: _buildNewsCard(items[index]),
                  ),
                );
              },
            ),
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

  /// News card. Two layouts depending on whether an image is attached:
  /// - With image: full-width banner on top, text block below (editorial feel)
  /// - Without image: compact icon-row layout
  /// A link chip is shown whenever the news item has one. [_buildNewsCard]
  Widget _buildNewsCard(_NewsItem item) {
    final isRecent = _isRecent(item.createdAt);
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final hasLink = item.link != null && item.link!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: emasColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openNewsDetail(item),
          child: hasImage
              ? _buildNewsCardWithImage(item, isRecent, hasLink)
              : _buildNewsCardCompact(item, isRecent, hasLink),
        ),
      ),
    );
  }

  /// Editorial-style card: banner image on top, title/badge/content/date below [_buildNewsCardWithImage]
  Widget _buildNewsCardWithImage(_NewsItem item, bool isRecent, bool hasLink) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              item.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 32),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3)),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(_formatDate(item.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  if (hasLink) ...[
                    const Spacer(),
                    Icon(Icons.link_rounded, size: 14, color: Colors.blue.shade400),
                    const SizedBox(width: 3),
                    Text('มีลิงก์แนบ',
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade400, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Compact icon-row layout, used when the news item has no attached image [_buildNewsCardCompact]
  Widget _buildNewsCardCompact(_NewsItem item, bool isRecent, bool hasLink) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: emasColor.withValues(alpha: 0.1), shape: BoxShape.circle),
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
                    if (hasLink) ...[
                      const Spacer(),
                      Icon(Icons.link_rounded, size: 13, color: Colors.blue.shade400),
                      const SizedBox(width: 3),
                      Text('มีลิงก์แนบ',
                          style: TextStyle(fontSize: 10.5, color: Colors.blue.shade400, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
        ],
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

  /// Tappable link button shown inside the news detail sheet [_buildLinkButton]
  Widget _buildLinkButton(String link) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openLink(link),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: emasColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: emasColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.link_rounded, size: 18, color: emasColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                link,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, color: emasColor, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.open_in_new_rounded, size: 16, color: emasColor),
          ],
        ),
      ),
    );
  }
}
