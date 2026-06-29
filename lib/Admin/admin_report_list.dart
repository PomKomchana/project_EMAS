import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_report_detail.dart';
import 'admin_report_form.dart';

const _emasColor = Color(0xFFe85d6a);

class AdminReportListPage extends StatefulWidget {
  const AdminReportListPage({super.key});

  @override
  State<AdminReportListPage> createState() => _AdminReportListPageState();
}

class _AdminReportListPageState extends State<AdminReportListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // เพิ่มรายการแจ้งซ่อม (Admin) [showAdminReportForm]
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _emasColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มรายการแจ้งซ่อม'),
        onPressed: () => showAdminReportForm(context),
      ),

      body: Column(
        children: [
          Container(
            color: _emasColor.withOpacity(0.05),
            child: TabBar(
              controller: _tabCtrl,
              labelColor: _emasColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: _emasColor,
              tabs: const [
                Tab(text: 'รอดำเนินการ'),
                Tab(text: 'กำลังดำเนินการ'),
                Tab(text: 'เสร็จสิ้น'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
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

class _FilteredList extends StatelessWidget {
  final String status;
  const _FilteredList({required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('ไม่มีรายการ "$status"',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            // รายการที่ admin สร้างเอง (ไม่ใช่ user แจ้ง) [createdBy]
            final isAdminCreated = data['createdBy'] == 'admin';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: Icon(
                  isAdminCreated
                      ? Icons.admin_panel_settings_rounded
                      : Icons.location_on,
                  color: _emasColor,
                ),
                title: Text(
                  '${data['building'] ?? '-'} · ${data['floor'] ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  data['description'] ?? '-',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // ป้ายเล็กบอกว่า admin เป็นคนสร้างรายการนี้เอง
                trailing: isAdminCreated
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _emasColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _emasColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right),
                        ],
                      )
                    : const Icon(Icons.chevron_right),
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
              ),
            );
          },
        );
      },
    );
  }
}
