import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_report_detail.dart';
import '../services/admin_service.dart';

import '../../shared/constants/emas_colors.dart';

// Admin report list: tabbed by status ("รอดำเนินการ" / "กำลังดำเนินการ" / "เสร็จสิ้น").
// Read/manage only — creating new reports now happens from the "ประกาศ" tab. [AdminReportListPage]
class AdminReportListPage extends StatefulWidget {
  const AdminReportListPage({super.key});

  @override
  State<AdminReportListPage> createState() => _AdminReportListPageState();
}

class _AdminReportListPageState extends State<AdminReportListPage>
    with SingleTickerProviderStateMixin {

  /// ============================== [Controllers & Services] ==============================
  late final TabController _tabController;

  /// ============================== [Life Cycle] ==============================
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                Tab(text: 'รอดำเนินการ'),
                Tab(text: 'กำลังดำเนินการ'),
                Tab(text: 'เสร็จสิ้น'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _FilteredList(status: 'รอดำเนินการ'),
                _FilteredList(status: 'กำลังดำเนินการ'),
                _FilteredList(status: 'เสร็จสิ้น'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// One tab's content: reports filtered by status, newest first [_FilteredList]
class _FilteredList extends StatelessWidget {
  final String status;
  const _FilteredList({required this.status});

  /// ============================== [Controllers & Services] ==============================
  static final _adminService = AdminService();

  /// ============================== [UI Helpers] ==============================
  Color _statusColor(String s) {
    switch (s) {
      case 'รอดำเนินการ': return Colors.orange;
      case 'กำลังดำเนินการ': return Colors.blue;
      case 'เสร็จสิ้น': return Colors.green;
      default: return emasColor;
    }
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return StreamBuilder<QuerySnapshot>(
      stream: _adminService.reportsByStatusStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล',
                style: TextStyle(color: Colors.red.shade400)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: emasColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.inbox_rounded, size: 40, color: emasColor.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 14),
                Text('ไม่มีรายการ "$status"',
                    style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border(left: BorderSide(color: color, width: 4)),
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminReportDetailPage(
                          reportId: doc.id,
                          data: data,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${data['building'] ?? '-'} · ${data['floor'] ?? '-'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${data['description'] ?? '-'}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
