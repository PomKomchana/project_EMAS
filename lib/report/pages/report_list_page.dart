import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'report_detail_page.dart';

import '../../shared/constants/emas_colors.dart';
import '../../shared/constants/report_constants.dart';

// Lists all submitted reports. Two tabs ("ทั้งหมด" / "ของฉัน") + status filter
// AppBar is now owned by MainPage — this page only renders the tab bar + list body
class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage>
    with TickerProviderStateMixin {

  /// ============================== [State] ==============================
  late final TabController _tabController;
  late final AnimationController _fadeController;

  // Staggered list-item animation, replayed on tab switch [_fadeList, _slideList]
  late final List<Animation<double>> _fadeList;
  late final List<Animation<Offset>> _slideList;

  // Status filter [_filterStatus] — null = show all statuses
  String? _filterStatus;

  /// ============================== [Life Cycle] ==============================
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeList = _buildStaggeredFadeList();
    _slideList = _buildStaggeredSlideList();

    _fadeController.forward();

    // Replay entrance animation on tab switch
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _fadeController.reset();
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// ============================== [Animation Logic] ==============================
  // Staggered fade-in per list item slot [_buildStaggeredFadeList]
  List<Animation<double>> _buildStaggeredFadeList() {
    return List.generate(20, (i) {
      final start = (i * 0.05).clamp(0.0, 0.9);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start, 1.0, curve: Curves.easeOut),
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
          curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  /// ============================== [Data] ==============================
  // Reports stream, newest first [_reportsStream]
  Stream<QuerySnapshot> _reportsStream() {
    return FirebaseFirestore.instance
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Filters docs by _filterStatus (null = no filter) [_applyStatusFilter]
  List<QueryDocumentSnapshot> _applyStatusFilter(
    List<QueryDocumentSnapshot> docs,
  ) {
    if (_filterStatus == null) return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == _filterStatus;
    }).toList();
  }

  /// ============================== [Navigation Logic] ==============================
  // Opens the status filter sheet [_showFilterSheet]
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildFilterSheetContent(),
    );
  }

  // Navigate to detail page with fade + slide-up transition [_openDetailPage]
  void _openDetailPage(
    BuildContext context,
    Map<String, dynamic> data,
    String id,
  ) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => ReportDetailPage(data: data, id: id),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),

      appBar: _buildAppBar(),

      body: Column(
        children: [
          _buildTabBar(),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(myReportsOnly: false),
                _buildList(myReportsOnly: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ============================== [Widgets] ==============================
  // App bar: hamburger (opens MainPage drawer) + title + status filter [_buildAppBar]
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: false,
      foregroundColor: Colors.white,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: const Text(
        'รายการแจ้งปัญหา',
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
      actions: [
        AnimatedBuilder(
          animation: _tabController.animation!,
          builder: (_, __) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildFilterButton(),
          ),
        ),
      ],
    );
  }

  // Tab selector: "ทั้งหมด" / "ของฉัน" [_buildTabBar]
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          Tab(text: 'ทั้งหมด'),
          Tab(text: 'ของฉัน'),
        ],
      ),
    );
  }

  // Filter pill button, opens the filter sheet [_buildFilterButton]
  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: _showFilterSheet,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  _filterStatus ?? 'ทุกสถานะ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // Filter sheet: every status option + "ทุกสถานะ" (all) [_buildFilterSheetContent]
  Widget _buildFilterSheetContent() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: Colors.white.withOpacity(0.9),
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
                  'กรองตามสถานะ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                for (final option in ReportStatus.filterOptions)
                  _buildFilterOptionTile(option),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // One row in the filter sheet. null = "show all". [_buildFilterOptionTile]
  Widget _buildFilterOptionTile(String? option) {
    return ListTile(
      leading: Icon(
        _filterStatus == option
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color: emasColor,
      ),
      title: Text(option ?? 'ทุกสถานะ'),
      onTap: () {
        setState(() => _filterStatus = option);
        Navigator.pop(context);
      },
    );
  }

  // Tab content: loading/error/empty states, or the report list. [_buildList]
  // NOTE: myReportsOnly is unused — both tabs show the same stream.
  Widget _buildList({required bool myReportsOnly}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _reportsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: emasColor),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }

        final docs = _applyStatusFilter(snapshot.data?.docs ?? []);

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return _buildAnimatedListView(docs);
      },
    );
  }

  // Report cards with staggered entrance animation [_buildAnimatedListView]
  Widget _buildAnimatedListView(List<QueryDocumentSnapshot> docs) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final id = docs[index].id;
        final animIndex = index % _fadeList.length;

        return FadeTransition(
          opacity: _fadeList[animIndex],
          child: SlideTransition(
            position: _slideList[animIndex],
            child: _buildReportCard(context, data, id),
          ),
        );
      },
    );
  }

  // Shown when the filtered list has no items [_buildEmptyState]
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'ไม่มีรายการ',
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

  // One report card: thumbnail, title, status, date. Tap → detail page. [_buildReportCard]
  Widget _buildReportCard(
    BuildContext context,
    Map<String, dynamic> data,
    String id,
  ) {
    final building = data['building'] ?? '-';
    final floor = data['floor'] ?? '-';
    final room = data['room'] ?? '-';
    final desc = data['description'] ?? '-';
    final status = data['status'] ?? ReportStatus.pending;
    final date = data['date'] ?? '-';
    final imageUrl = data['imageUrl'] as String?;

    final severityKey = data['severity'] as String?;
    final severity = getSeverityInfo(severityKey);

    return GestureDetector(
      onTap: () => _openDetailPage(context, data, id),
      child: _buildCardGlassContainer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(id, imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardContent(
                building: building,
                floor: floor,
                room: room,
                desc: desc,
                status: status,
                date: date,
                severity: severity,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // Glass background for the card (duplicate of detail page's glass card) [_buildCardGlassContainer]
  Widget _buildCardGlassContainer({required Widget child}) {
    return ClipRRect(
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
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // Thumbnail. Shares a Hero tag with the detail page's hero image. [_buildThumbnail]
  Widget _buildThumbnail(String id, String? imageUrl) {
    return Hero(
      tag: 'img_$id',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 72,
          height: 72,
          color: Colors.grey.shade100,
          child: imageUrl != null
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : Icon(
                  Icons.image_outlined,
                  color: Colors.grey.shade400,
                  size: 28,
                ),
        ),
      ),
    );
  }

  // Text column: title, severity badge, status chip, date [_buildCardContent]
  Widget _buildCardContent({
    required String building,
    required String floor,
    required String room,
    required String desc,
    required String status,
    required String date,
    required SeverityInfo severity,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$building · $floor · ห้อง $room',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            _buildSeverityBadge(severity),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatusChip(status),
            const SizedBox(width: 8),
            Icon(
              Icons.calendar_today_outlined,
              size: 11,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 3),
            Text(
              date,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }

  // Severity dot + label (duplicate of detail page's version) [_buildSeverityBadge]
  Widget _buildSeverityBadge(SeverityInfo severity) {
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
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: severity.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            severity.label,
            style: TextStyle(
              color: severity.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Status pill (pending/in-progress/done) [_buildStatusChip]
  Widget _buildStatusChip(String status) {
    final colors = getStatusColors(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: colors.fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
