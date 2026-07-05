import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_report_list.dart';
import 'admin_news.dart';
import '../services/admin_service.dart';
import '../../pages/main_page.dart';

import '../../shared/constants/emas_colors.dart';

// Admin shell: bottom nav across Dashboard / Report List / News [AdminMainPage]
class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {

  /// ============================== [State] ==============================
  int _selectedIndex = 0;

  // Tab pages, indexed by the bottom nav [_pages]
  final List<Widget> _pages = [
    const _AdminDashboard(),
    const AdminReportListPage(),
    const AdminNewsPage(),
  ];

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainPage()),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'Admin Panel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: emasColor,
        foregroundColor: Colors.white,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'แดชบอร์ด',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'รายการแจ้งซ่อม',
          ),
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: 'ข่าวสาร',
          ),
        ],
      ),
    );
  }
}

// Dashboard tab: stat cards computed live from the reports stream [_AdminDashboard]
class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard();

  /// ============================== [Controllers & Services] ==============================
  static final _adminService = AdminService();

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _adminService.reportsStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        // Status counts tallied client-side from the raw stream [pending, inProgress, done]
        int pending = 0, inProgress = 0, done = 0;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';
          if (status == 'รอดำเนินการ') {
            pending++;
          } else if (status == 'กำลังดำเนินการ') {
            inProgress++;
          } else if (status == 'เสร็จสิ้น') {
            done++;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // NOTE: hardcoded hex duplicates emasColor/emasColorDarker — should reference those constants instead
                  gradient: const LinearGradient(
                    colors: [Color(0xFFe85d6a), Color(0xFFff8a80)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('สวัสดี, Admin 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 8),
                    Text('รายการทั้งหมด ${docs.length} รายการ',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('ภาพรวม',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                        title: 'รอดำเนินการ',
                        count: pending,
                        color: Colors.orange,
                        icon: Icons.pending_actions),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                        title: 'กำลังดำเนินการ',
                        count: inProgress,
                        color: Colors.blue,
                        icon: Icons.engineering),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                        title: 'เสร็จสิ้น',
                        count: done,
                        color: Colors.green,
                        icon: Icons.check_circle),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Single stat tile: icon + count + label [_StatCard]
class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text('$count',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
