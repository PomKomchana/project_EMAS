import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const emasColor = Color(0xFFe85d6a);
const emasColorDarker = Color(0xFFc94756);

class ReportNewsPage extends StatefulWidget {
  const ReportNewsPage({super.key});

  @override
  State<ReportNewsPage> createState() => _ReportNewsPageState();
}

class _ReportNewsPageState extends State<ReportNewsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  late final List<Animation<double>> _fadeList;
  late final List<Animation<Offset>> _slideList;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeList = _buildStaggeredFadeList();
    _slideList = _buildStaggeredSlideList();

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

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

  Stream<QuerySnapshot> _newsStream() {
    return FirebaseFirestore.instance
        .collection('news')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [emasColor, emasColorDarker],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 4),

                  const Text(
                    'ข่าวสาร',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _newsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: emasColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'เกิดข้อผิดพลาด: ${snapshot.error}',
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24,
            ),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data =
                  docs[index].data() as Map<String, dynamic>;

              final animIndex =
                  index % _fadeList.length;

              return FadeTransition(
                opacity: _fadeList[animIndex],
                child: SlideTransition(
                  position: _slideList[animIndex],
                  child: _buildNewsCard(data),
                ),
              );
            },
          );
        },
      ),
    );
  }

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

  Widget _buildNewsCard(
    Map<String, dynamic> data,
  ) {
    final title = data['title'] ?? '-';
    final content = data['content'] ?? '';
    final date = _formatNewsDate(
      data['createdAt'],
    );

    return ClipRRect(
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
              _buildNewsIcon(),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),

                    if (content
                        .toString()
                        .isNotEmpty) ...[
                      const SizedBox(height: 6),

                      Text(
                        content,
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
            ],
          ),
        ),
      ),
    );
  }

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

  String? _formatNewsDate(dynamic createdAt) {
    if (createdAt is! Timestamp) {
      return null;
    }

    final d = createdAt.toDate();

    return '${d.day}/${d.month}/${d.year}';
  }
}
