import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../shared/constants/emas_colors.dart';

// News feed: realtime list + tap-to-expand bottom sheet detail [NewsPage]
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

  // Looping pulse used by the skeleton loading cards [_shimmerController]
  late final AnimationController _shimmerController;

  // Staggered list-item animation [_fadeList, _slideList]
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
  // Staggered fade-in per list item slot [_buildStaggeredFadeList]
  List<Animation<double>> _buildStaggeredFadeList() {
    return List.generate(20, (i) {
      final start = (i * 0.05).clamp(0.0, 0.9);

      return Tween<double>(
        begin: 0,
        end: 1,
      ).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(
            start,
            1.0,
            curve: Curves.easeOut,
          ),
        ),
      );
    });
  }

  // Same as above but slide-up motion [_buildStaggeredSlideList]
  List<Animation<Offset>> _buildStaggeredSlideList() {
    return List.generate(20, (i) {
      final start = (i * 0.05).clamp(0.0, 0.9);

      return Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(
            start,
            1.0,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });
  }

  /// ============================== [Data] ==============================
  // News stream, newest first.
  // NOTE: duplicates the exact same query as AdminService.newsStream() —
  // consider a shared read-only NewsService both pages can call. [_newsStream]
  Stream<QuerySnapshot> _newsStream() {
    return FirebaseFirestore.instance
        .collection('news')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ============================== [UI Helpers] ==============================
  // Check if news was posted within the last 48 hours [_isRecentNews]
  bool _isRecentNews(dynamic createdAt) {
    if (createdAt is! Timestamp) {
      return false;
    }

    final postedAt = createdAt.toDate();
    final diff = DateTime.now().difference(postedAt);

    return diff.inHours < 48 && !diff.isNegative;
  }

  // Format a Firestore Timestamp as d/M/y [_formatNewsDate]
  String? _formatNewsDate(dynamic createdAt) {
    if (createdAt is! Timestamp) {
      return null;
    }

    final d = createdAt.toDate();

    return '${d.day}/${d.month}/${d.year}';
  }

  // Pull-to-refresh handler. Stream is already realtime; short delay just
  // gives the gesture feedback. [_handleRefresh]
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  /// ============================== [Navigation Logic] ==============================
  // Bottom sheet showing full news content [_openNewsDetail]
  void _openNewsDetail({
    required String heroTag,
    required String? imageUrl,
    required String title,
    required String content,
    required String? date,
  }) {
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 20,
                  sigmaY: 20,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                        ),
                      ),

                      if (imageUrl != null &&
                          imageUrl.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          child: Hero(
                            tag: heroTag,
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(16),
                              child: Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error,
                                        stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],

                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          28,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),

                            if (date != null) ...[
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  Icon(
                                    Icons
                                        .calendar_today_outlined,
                                    size: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    date,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 16),

                            Text(
                              content,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Colors.grey.shade800,
                              ),
                            ),
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
          'ข่าวสาร',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
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
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonList();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
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
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final animIndex = index % _fadeList.length;

                return FadeTransition(
                  opacity: _fadeList[animIndex],
                  child: SlideTransition(
                    position: _slideList[animIndex],
                    child: _buildNewsCard(doc.id, data),
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
  // Skeleton placeholder shown while the stream connects [_buildSkeletonList]
  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  // Single pulsing skeleton card [_buildSkeletonCard]
  Widget _buildSkeletonCard() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        // Pulse opacity between 0.4 and 0.9 [_shimmerController]
        final opacity = 0.4 + (_shimmerController.value * 0.5);

        return Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        width: 180,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Container(
                        width: 120,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
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

  // Shown when the news collection is empty [_buildEmptyState]
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),

          const SizedBox(height: 12),

          Text(
            'ยังไม่มีข่าวสาร',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // One news card: thumbnail, title, "ใหม่" badge, preview, date. Tap → detail sheet. [_buildNewsCard]
  Widget _buildNewsCard(
    String docId,
    Map<String, dynamic> data,
  ) {
    final title = data['title'] ?? '-';
    final content = data['content'] ?? '';
    final imageUrl = data['imageUrl'] as String?;
    final date = _formatNewsDate(
      data['createdAt'],
    );
    final isRecent = _isRecentNews(data['createdAt']);
    final heroTag = 'news_image_$docId';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openNewsDetail(
          heroTag: heroTag,
          imageUrl: imageUrl,
          title: title,
          content: content,
          date: date,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 20,
              sigmaY: 20,
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.78),
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color:
                      Colors.white.withOpacity(0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildNewsThumbnail(heroTag, imageUrl),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Title row + "ใหม่" badge [isRecent]
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w700,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ),

                            if (isRecent) ...[
                              const SizedBox(width: 6),
                              _buildNewBadge(),
                            ],
                          ],
                        ),

                        if (content
                            .toString()
                            .isNotEmpty) ...[
                          const SizedBox(height: 6),

                          // Truncated preview, full text shown in bottom sheet
                          Text(
                            content,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  Colors.grey.shade700,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],

                        if (date != null) ...[
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Icon(
                                Icons
                                    .calendar_today_outlined,
                                size: 11,
                                color: Colors
                                    .grey
                                    .shade500,
                              ),

                              const SizedBox(
                                  width: 4),

                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors
                                      .grey
                                      .shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Chevron hints the card is tappable
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Small pink "ใหม่" pill shown on recent news [_buildNewBadge]
  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: emasColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'ใหม่',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // Thumbnail: real image + Hero when available, icon fallback otherwise [_buildNewsThumbnail]
  Widget _buildNewsThumbnail(String heroTag, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildNewsIcon();
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

            return Container(
              width: 48,
              height: 48,
              color: Colors.grey.shade200,
            );
          },
          // Falls back to the default icon if the image fails to load
          errorBuilder: (context, error, stackTrace) =>
              _buildNewsIcon(),
        ),
      ),
    );
  }

  // Default circular icon shown when there's no thumbnail [_buildNewsIcon]
  Widget _buildNewsIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: emasColor.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.campaign_rounded,
        color: emasColor,
        size: 24,
      ),
    );
  }
}
