import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../admin/admin_main.dart';
import '../auth/login.dart';
import 'news_page.dart';
import 'profile_page.dart';
import 'emergency_page.dart';
import '../report/report_form_constants.dart';
import '../report/report_list_page.dart';
import '../report/report_form.dart';
import 'report_sheet.dart';
import 'mark.dart';

const _emasColor = Color(0xFFe85d6a);

class MainPage extends StatefulWidget {
  final int initialIndex;

  const MainPage({super.key, this.initialIndex = 0});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedIndex;
  bool _isAdmin = false;
  dynamic _selectedReport; // หรือใช้ model ของคุณ
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _checkAdmin();
  }
  
  static const _titles = [
    'Home',
    'รายการแจ้งปัญหา',
    'ข่าวสาร',
    'โปรไฟล์'
  ];

  static const _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
  ];

  Future<void> _checkAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data();

      if (data?['role'] == 'admin') {
        setState(() {
          _isAdmin = true;
        });
      }
    } catch (e) {
      debugPrint('Admin check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHome = _selectedIndex == 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: isHome
          ? null
          : AppBar(
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              title: Text(
                _titles[_selectedIndex],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),

      drawer: _AppDrawer(
        isAdmin: _isAdmin,
        onTap: (i) {
          Navigator.pop(context);
          setState(() => _selectedIndex = i);
        },

        onEmergency: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencyPage()),
          );
        },

        onAdmin: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminMainPage()),
          );
        },
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _HomePage(),
          ReportListPage(),
          NewsPage(),
          ProfilePage(),
        ],
      ),

      // Bottom Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: _emasColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: _navItems,
      ),
    );
  }
}

// Drawer
class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.onTap,
    required this.onEmergency,
    required this.onAdmin,
    required this.isAdmin,
  });

  final void Function(int) onTap;
  final VoidCallback onEmergency;
  final VoidCallback onAdmin;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: _emasColor),
            child: Text('EMAS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          
        if (isAdmin)
          _DrawerItem(icon: Icons.admin_panel_settings, label: 'Admin Panel', onTap: onAdmin),

        if (isAdmin)
          const Divider(height: 1),

          _DrawerItem(icon: Icons.home, label: 'หน้าหลัก', onTap: () => onTap(0)),
          _DrawerItem(icon: Icons.list_alt, label: 'รายการแจ้งปัญหา', onTap: () => onTap(1)),
          _DrawerItem(icon: Icons.notifications_none, label: 'ข่าวสาร', onTap: () => onTap(2)),
          _DrawerItem(icon: Icons.person, label: 'โปรไฟล์', onTap: () => onTap(3)),

          const Divider(height: 1),

          _DrawerItem(icon: Icons.phone_in_talk_outlined, label: 'เบอร์โทรฉุกเฉิน', onTap: onEmergency),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label,
          style: color != null
              ? TextStyle(color: color, fontWeight: FontWeight.w600)
              : null),
      onTap: onTap,
    );
  }
}

// Home Page
class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  final MapController _mapController = MapController();

  LatLng? _userPosition;
  MapMode _mapMode = MapMode.normal;
  Map<String, dynamic>? _selectedReport;

  void _cycleMapType() {
    HapticFeedback.selectionClick();
    final modes = MapMode.values;
    final next = (modes.indexOf(_mapMode) + 1) % modes.length;
    setState(() => _mapMode = modes[next]);
  }

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _userPosition = latLng);

      if (mapBounds.contains(latLng)) {
        _mapController.move(latLng, 16);
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Widget _buildBottomCard() {
  final data = _selectedReport!;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                data['description'] ?? '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedReport = null;
                });
              },
            )
          ],
        ),

        const SizedBox(height: 8),

        Text(
          "${data['building'] ?? '-'} · ห้อง ${data['room'] ?? '-'}",
          style: const TextStyle(color: Colors.white70),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                // ไปหน้า detail ได้ตรงนี้
              },
              child: const Text("ดูรายละเอียด"),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedReport = null;
                });
              },
              child: const Text("ปิด"),
            ),
          ],
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: mapLocation,
            initialZoom: 15.5,
            minZoom: 14,
            maxZoom: 20,
            cameraConstraint: CameraConstraint.contain(bounds: mapBounds),
          ),
          children: [
            TileLayer(
              urlTemplate: mapModeTileUrl(_mapMode),
              userAgentPackageName: 'com.example.app',
            ),

            ReportMarkerLayer(
              onTapMarker: (data) {
                setState(() {
                  _selectedReport = data;
                });
              },
            ),

            if (_userPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userPosition!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),

        //  menu (ของเดิม)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: Builder(
            builder: (ctx) => CircleAvatar(
              backgroundColor: Colors.white,
              radius: 22,
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.black87),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ),
        ),

        // Map Switch
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 68,
          child: GestureDetector(
            onTap: _cycleMapType,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(mapModeIcon(_mapMode), size: 16, color: _emasColor),
                  const SizedBox(width: 6),
                  Text(mapModeLabel(_mapMode)),
                ],
              ),
            ),
          ),
        ),

        // Report Form
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _emasColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('แจ้งปัญหาใหม่'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportForm()),
            ),
          ),
        ),

        if (_selectedReport != null)
        ReportDetailSheet(
          report: _selectedReport!,
          onClose: () => setState(() => _selectedReport = null),
        ),
      ],
    );
  }
}