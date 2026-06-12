import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _emasColor = Color(0xFFe85d6a);
const _emasColorDarker = Color(0xFFc4394a);

/// >>>>> [Widget Class] <<<<<
class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

/// >>>>> [State Class] <<<<<
class _ReportListPageState extends State<ReportListPage> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final List<Animation<double>> _fadeList;
  late final List<Animation<Offset>> _slideList;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
    );

    _fadeList = List.generate(20, (i) {
    final start = i * 0.05;
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Interval(start, 1.0, curve: Curves.easeOut),
      ),
    );
  });

   _slideList = List.generate(20, (i) {
    final start = i * 0.05;
    return Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Interval(start, 1.0, curve: Curves.easeOut),
      ),
    );
  });

   _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// FIRESTORE STREAM
  Stream<QuerySnapshot> _reportsStream() {
    return FirebaseFirestore.instance
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),

      appBar: AppBar(
        backgroundColor: _emasColor,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              child: Text(
                'ทั้งหมด', style: TextStyle(color: Colors.white, fontSize: 14),
                ),
            ),
            Tab(
              child: Text(
                'ของฉัน', style: TextStyle(color: Colors.white, fontSize: 14),
                ),
            ),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(all: true),
          _buildList(all: false),
        ],
      ),
    );
  }

  /// [LIST BUILDER]
  Widget _buildList({required bool all}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _reportsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('ไม่มีรายการ'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;

            return _withAnimation(index, _buildReportCard(context, data, id));
          },
        );
      },
    );
  }

  /// =====================
  /// CARD UI
  /// =====================
  Widget _buildReportCard(
      BuildContext context, Map<String, dynamic> data, String id) {
    final building = data['building'] ?? '-';
    final floor = data['floor'] ?? '-';
    final room = data['room'] ?? '-';
    final desc = data['description'] ?? '-';
    final status = data['status'] ?? 'รอดำเนินการ';
    final date = data['date'] ?? '-';
    final severity = data['severity'] ?? 'low';
    final imageUrl = data['imageUrl'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 350),
            
            pageBuilder: (_, __, ___) => ReportDetailPage(data: data, id: id),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
          ),
        );
      },
      child: Container(
        decoration: _glass(),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            /// Severity dot
            _severityDot(severity),

            const SizedBox(width: 10),

            /// Thumbnail
            Hero(
              tag: 'img_$id',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey.shade200,
                  child: imageUrl != null
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(width: 12),

            /// Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$building / $floor / $room',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      _statusChip(status),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// =====================
  /// SEVERITY DOT
  /// =====================
  Widget _severityDot(String level) {
    Color color;
    switch (level) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  /// =====================
  /// STATUS CHIP
  /// =====================
  Widget _statusChip(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'กำลังดำเนินการ':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        break;
      case 'เสร็จสิ้น':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        break;
      default:
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
    }
  
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    );
  }

  Widget _withAnimation(int index, Widget child) {
    final i = index % _fadeList.length;

    return FadeTransition(
      opacity: _fadeList[i],
      child: SlideTransition(
        position: _slideList[i],
        child: child,
      ),
    );
  }

  /// =====================
  /// GLASS STYLE
  /// =====================
  BoxDecoration _glass() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.6)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }
}

/// =======================================================
/// DETAIL PAGE
/// =======================================================
class ReportDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String id;

  const ReportDetailPage({super.key, required this.data, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),

      appBar: AppBar(
        backgroundColor: _emasColor,
        title: const Text('รายละเอียด'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            Hero(
              tag: 'img_$id',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: data['imageUrl'] != null
                    ? Image.network(data['imageUrl'], height: 220, width: double.infinity, fit: BoxFit.cover)
                    : Container(
                        height: 220,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image, size: 60),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              '${data['building']} / ${data['floor']} / ${data['room']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(data['description'] ?? '-'),

            const SizedBox(height: 12),

            Row(
              children: [
                _infoBox('สถานะ', data['status']),
                const SizedBox(width: 8),
                _infoBox('วันที่', data['date']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          Text(value ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
