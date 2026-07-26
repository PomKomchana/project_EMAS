import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared/constants/emas_colors.dart';
import '../shared/utils/thai_date.dart';

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
/// News items open a full-page detail view with image/title/date/content/link. [AnnouncementPage]
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

  static const _thaiMonths = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  /// Builds a full Thai date string ("25 กรกฎาคม 2026 เวลา 12:27") from a
  /// DateTime, then shortens it with shortenThaiDate — same display format
  /// used on the admin pages. [_formatDate]
  String _formatDate(DateTime? createdAt) {
    if (createdAt == null) return '-';
    final month = _thaiMonths[createdAt.month - 1];
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final full = '${createdAt.day} $month ${createdAt.year} เวลา $hour:$minute';
    return shortenThaiDate(full);
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  /// Opens an external/attached link in the browser [_openLink]
  static Future<void> _openLink(String url) async {
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
  /// News items → เปิดหน้ารายละเอียดแบบเต็มจอ [_openNewsDetail]
  void _openNewsDetail(_NewsItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _NewsDetailPage(
          item: item,
          formatDate: _formatDate,
          openLink: _openLink,
        ),
      ),
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

  /// Editorial-style card: banner image on top with the date badge overlaid
  /// on the image itself (bottom-left, dark pill) — matching the image
  /// preview badge style on the admin news form. Title/content follow below,
  /// and the link (when present) renders as its own full-width chip at the
  /// bottom. [_buildNewsCardWithImage]
  Widget _buildNewsCardWithImage(_NewsItem item, bool isRecent, bool hasLink) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
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
            Positioned(
              left: 10,
              bottom: 10,
              child: _buildDateBadgeOnImage(item.createdAt),
            ),
          ],
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
            ],
          ),
        ),
        if (hasLink)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _buildLinkChip(item.link!),
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }

  /// Compact icon-row layout, used when the news item has no attached image.
  /// Date badge sits alone on its own row, and the link (when present)
  /// renders as its own full-width chip below the row — matching the
  /// admin announcement card layout. [_buildNewsCardCompact]
  Widget _buildNewsCardCompact(_NewsItem item, bool isRecent, bool hasLink) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
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
                    const SizedBox(height: 6),
                    _buildDateBadge(item.createdAt),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
        if (hasLink)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _buildLinkChip(item.link!),
          ),
      ],
    );
  }

  /// Date pill badge, styled like the status/date chips on the admin pages,
  /// instead of a plain icon+text row. [_buildDateBadge]
  Widget _buildDateBadge(DateTime? createdAt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade400.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            _formatDate(createdAt),
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// Date pill badge overlaid on top of an image — dark semi-transparent
  /// background with white text, matching the image preview badge style
  /// used on the admin news form. [_buildDateBadgeOnImage]
  Widget _buildDateBadgeOnImage(DateTime? createdAt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _formatDate(createdAt),
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Link chip shown as its own full-width row below the card content —
  /// matches the link container style used on the admin announcement
  /// card. [_buildLinkChip]
  Widget _buildLinkChip(String link) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _openLink(link),
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
                link,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
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
}

/// [NEWS-DETAIL-PAGE] หน้ารายละเอียดข่าวแบบเต็มจอ พร้อมปุ่มย้อนกลับ
/// ลำดับ: รูป -> ชื่อเรื่อง+วันที่ (บรรทัดเดียวกัน) -> การ์ดรายละเอียด+ลิงก์ (จัดกึ่งกลางจอ)
class _NewsDetailPage extends StatelessWidget {
  final _NewsItem item;
  final String Function(DateTime?) formatDate;
  final Future<void> Function(String) openLink;

  const _NewsDetailPage({
    required this.item,
    required this.formatDate,
    required this.openLink,
  });

  /// Opens the image at real/full size in a fullscreen zoomable viewer [_openFullImage]
  void _openFullImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _FullScreenImageViewer(imageUrl: imageUrl),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final hasLink = item.link != null && item.link!.isNotEmpty;
    final date = formatDate(item.createdAt);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: emasColor,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'รายละเอียดประกาศ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------- รูป -------
                if (hasImage)
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.image_outlined,
                                color: Colors.grey.shade400, size: 32),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: _buildDateBadgeOnImage(date, dark: true),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: GestureDetector(
                          onTap: () => _openFullImage(context, item.imageUrl!),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.zoom_out_map_rounded,
                                size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),

                // ------- เนื้อหาจัดกึ่งกลางจอ -------
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ------- ชื่อเรื่อง (วันที่ย้ายไปแสดงทับบนรูปแล้ว) -------
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1.3,
                                  ),
                                ),
                                if (!hasImage) ...[
                                  const SizedBox(height: 8),
                                  _buildDateBadgeOnImage(date, dark: false),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ------- การ์ดรายละเอียด + ลิงก์ -------
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.notes_rounded, size: 16, color: emasColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      'รายละเอียดประกาศ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: emasColor,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Divider(color: Colors.grey.shade200, height: 20),
                                Text(
                                  item.content.isNotEmpty
                                      ? item.content
                                      : 'ไม่มีรายละเอียดเพิ่มเติม',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    height: 1.7,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                if (hasLink) ...[
                                  const SizedBox(height: 18),
                                  Divider(color: Colors.grey.shade200, height: 1),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Icon(Icons.attachment_rounded,
                                          size: 14, color: Colors.grey.shade500),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ลิงก์แนบ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildLinkText(item.link!),
                                ],
                              ],
                            ),
                          ),

                          if (!hasLink) ...[
                            const SizedBox(height: 24),
                            Center(
                              child: Icon(Icons.check_circle_outline_rounded,
                                  size: 22, color: Colors.grey.shade300),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Date pill badge. When [dark] is true (default), it's styled to sit on
  /// top of an image — dark semi-transparent background, white text. When
  /// false (used only when there's no image to overlay), it falls back to
  /// a light grey pill. [_buildDateBadgeOnImage]
  Widget _buildDateBadgeOnImage(String date, {bool dark = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? Colors.black.withValues(alpha: 0.45) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 11, color: dark ? Colors.white : Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// ลิงก์แสดงเป็นชิปสี emasColor เต็มความกว้าง กดแล้วเปิดเบราว์เซอร์ —
  /// โทนสีตรงกับธีมแอป (ชมพู/แดง) แทนสีน้ำเงินเดิม [_buildLinkText]
  Widget _buildLinkText(String link) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => openLink(link),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: emasColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.link_rounded, size: 16, color: emasColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                link,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: emasColor,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: emasColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.open_in_new_rounded, size: 14, color: emasColor),
          ],
        ),
      ),
    );
  }
}

/// [FULLSCREEN-IMAGE-VIEWER] แสดงรูปภาพขนาดจริงแบบเต็มจอ พร้อมซูม/ลากได้
/// ปิดได้ด้วยการแตะพื้นหลัง หรือกดปุ่มปิดมุมขวาบน
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 5.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) => const Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
