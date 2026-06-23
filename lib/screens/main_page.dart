import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'reportForm/report_form.dart';
import 'reportList/report_list_page.dart';
import 'profile_page.dart';
import 'emergency_page.dart';
import '../register/login.dart';
import 'reportForm/report_form_constants.dart';

const _appColor = Color(0xFFe85d6a);

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static const _titles = [
    'Home',
    'รายการแจ้งปัญหา',
    'ข่าวสาร',
    'โปรไฟล์'
  ];

  static const _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: ''), // 🔔
    BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
  ];

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
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        },
      ),

      // หน้าแต่ละแท็บ
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _HomePage(),          // ของเดิม
          ReportListPage(),
          NotificationPage(),   //  เพิ่ม
          ProfilePage(),
        ],
      ),

      // Bottom Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: _appColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: _navItems,
      ),
    );
  }
}

// ================= Drawer =================
class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.onTap,
    required this.onEmergency,
    required this.onAdmin,
  });

  final void Function(int) onTap;
  final VoidCallback onEmergency;
  final VoidCallback onAdmin;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: _appColor),
            child: Text('EMAS',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
          ),
          _DrawerItem(icon: Icons.home, label: 'หน้าหลัก', onTap: () => onTap(0)),
          _DrawerItem(icon: Icons.list_alt, label: 'รายการแจ้งปัญหา', onTap: () => onTap(1)),
          _DrawerItem(icon: Icons.notifications_none, label: 'ข่าวสาร', onTap: () => onTap(2)),
          _DrawerItem(icon: Icons.person, label: 'โปรไฟล์', onTap: () => onTap(3)),
          const Divider(height: 1),
          _DrawerItem(
            icon: Icons.phone_in_talk_outlined,
            label: 'เบอร์โทรฉุกเฉิน',
            onTap: onEmergency,
            color: _appColor,
          ),
          _DrawerItem(
            icon: Icons.admin_panel_settings_outlined,
            label: 'เข้าสู่ระบบ Admin',
            onTap: onAdmin,
          ),
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

// ================= Home Page =================
class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  final MapController _mapController = MapController();

  LatLng? _userPosition;
  MapMode _mapMode = MapMode.normal;

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

        //  map switch (ของเดิม)
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
                  Icon(mapModeIcon(_mapMode), size: 16, color: _appColor),
                  const SizedBox(width: 6),
                  Text(mapModeLabel(_mapMode)),
                ],
              ),
            ),
          ),
        ),

        //  ปุ่มแจ้งปัญหา (ของเดิม)
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _appColor,
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
      ],
    );
  }
}

// ================= Notification =================
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Information Page'),
    );
  }
}