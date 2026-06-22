import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_report_detail.dart';

const _appColor = Color(0xFFe85d6a);

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
    return Column(
      children: [
        Container(
          color: _appColor.withOpacity(0.05),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: _appColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _appColor,
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
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: const Icon(Icons.location_on, color: _appColor),
                title: Text(
                  '${data['building'] ?? '-'} · ${data['floor'] ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  data['description'] ?? '-',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
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
