import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _appColor = Color(0xFFe85d6a);

class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        Widget child;

        if (snapshot.connectionState == ConnectionState.waiting) {
          child = _ShimmerList(
            key: const ValueKey('loading'),
            controller: _shimmerController,
          );
        } else if (snapshot.hasError) {
          child = const _ErrorState(key: ValueKey('error'));
        } else {
          final docs = (snapshot.data?.docs ?? []).where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return (d['building'] as String?)?.isNotEmpty == true;
          }).toList();
          child = docs.isEmpty
              ? const _EmptyState(key: ValueKey('empty'))
              : _ReportListView(key: const ValueKey('list'), docs: docs);
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: child,
        );
      },
    );
  }
}

// ── Skeleton loading ──────────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  const _ShimmerList({super.key, required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => _ShimmerCard(controller: controller),
    );
  }
}

class _ShimmerCard extends AnimatedWidget {
  const _ShimmerCard({required AnimationController controller})
      : super(listenable: controller);

  Widget _box(double width, double height, double v, {double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color.lerp(
            const Color(0xFFE0E0E0), const Color(0xFFF0F0F0), v),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = (listenable as AnimationController).value;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _box(140, 14, v),
              const Spacer(),
              _box(64, 22, v, radius: 20),
            ]),
            const SizedBox(height: 10),
            _box(double.infinity, 12, v),
            const SizedBox(height: 6),
            _box(180, 12, v),
            const SizedBox(height: 10),
            _box(100, 10, v),
          ],
        ),
      ),
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('ยังไม่มีรายการแจ้งปัญหา',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 52, color: Colors.redAccent),
          SizedBox(height: 12),
          Text('เกิดข้อผิดพลาด',
              style: TextStyle(fontSize: 15, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ── Report list ───────────────────────────────────────────────────────────────

class _ReportListView extends StatelessWidget {
  const _ReportListView({super.key, required this.docs});
  final List<QueryDocumentSnapshot> docs;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 300 + (i < 8 ? i * 50 : 400)),
        curve: Curves.easeOut,
        builder: (_, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        ),
        child: _ReportCard(data: docs[i].data() as Map<String, dynamic>),
      ),
    );
  }
}

// ── Report card ───────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.data});
  final Map<String, dynamic> data;

  static String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final building = data['building'] as String? ?? '-';
    final floor = data['floor'] as String? ?? '-';
    final description = data['description'] as String? ?? '-';
    final status = data['status'] as String? ?? 'รอดำเนินการ';
    final ts = data['createdAt'] as Timestamp?;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: _appColor),
                const SizedBox(width: 4),
                Text('$building · $floor',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 8),
            Text(
              ts != null ? _formatDate(ts.toDate()) : '-',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  static Color _colorFor(String s) => switch (s) {
        'เสร็จสิ้น' => Colors.green,
        'กำลังดำเนินการ' => Colors.orange,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(status,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
