import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../admin/pages/admin_main.dart';
import 'news_page.dart';
import 'profile_page.dart';
import 'emergency_page.dart';
import 'mark.dart';
import 'report_sheet.dart';
import '../report/pages/report_list_page.dart';
import '../report/pages/report_form.dart';

import '../shared/constants/emas_colors.dart';
import '../shared/constants/map_constants.dart';

// App shell: bottom nav (Home/Reports/News/Profile) + drawer (Admin/Emergency)
// No AppBar here — each tab that needs one (ReportListPage/NewsPage) owns its own [MainPage]
class MainPage extends StatefulWidget {
  final int initialIndex;

  const MainPage({super.key, this.initialIndex = 0});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // Key to reach MainPage's own Scaffold (the one that owns the Drawer)
  // from child tab pages that have their own Scaffold [_scaffoldKey]
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// ============================== [State] ==============================
  late int _selectedIndex;
  bool _isAdmin = false;

  /// ============================== [Data] ==============================
  // Bottom nav icons, order: Home / Reports / News / Profile [_navItems]
  static const _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
  ];

  /// ============================== [Life Cycle] ==============================
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _checkAdmin();
  }

  /// ============================== [Admin Check Logic] ==============================
  // Reads users/{uid}.role to decide whether to show the Admin Panel drawer item.
  // NOTE: this only gates UI visibility — real admin authorization must still
  // come from Firestore security rules, not this client-side check. [_checkAdmin]
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

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // No AppBar here — each tab (ReportListPage/NewsPage) owns its own AppBar now
      drawer: _AppDrawer(
        isAdmin: _isAdmin,
        onTap: (i) {
          Navigator.pop(context);
          setState(() => _selectedIndex = i);
        },

        onAdmin: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminMainPage()),
          );
        },

        onEmergency: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencyPage()),
          );
        },
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomePage(isAdmin: _isAdmin),
          ReportListPage(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
          NewsPage(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
          ProfilePage(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
        ],
      ),

      // Bottom Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: emasColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: _navItems,
      ),
    );
  }
}

// Side drawer: nav shortcuts + conditional Admin Panel entry [_AppDrawer]
class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.onTap,
    required this.onAdmin,
    required this.isAdmin,
    required this.onEmergency,
  });

  final void Function(int) onTap;
  final VoidCallback onAdmin;
  final bool isAdmin;
  final VoidCallback onEmergency;

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: emasColor),
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

// Single drawer row [_DrawerItem]
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

  /// ============================== [Build] ==============================
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

// Home tab: full-screen campus map + report markers + report shortcut button [_HomePage]
class _HomePage extends StatefulWidget {
  final bool isAdmin;

  const _HomePage({required this.isAdmin});

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {

  /// ============================== [Controllers & Services] ==============================
  final MapController _mapController = MapController();

  /// ============================== [State] ==============================
  LatLng? _userPosition;
  MapMode _mapMode = MapMode.normal;
  // Currently tapped report marker; drives the bottom detail sheet [_selectedReport]
  Map<String, dynamic>? _selectedReport;

  /// ============================== [Life Cycle] ==============================
  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  /// ============================== [Location & Map Logic] ==============================
  // Switch to next map display mode [_cycleMapType]
  void _cycleMapType() {
    HapticFeedback.selectionClick();
    final modes = MapMode.values;
    final next = (modes.indexOf(_mapMode) + 1) % modes.length;
    setState(() => _mapMode = modes[next]);
  }

  // Request GPS permission and move map to user location [_getUserLocation]
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

  /// ============================== [Navigation Logic] ==============================
  // Route to the correct report form depending on the user's role [_onNewReportTap]
  void _onNewReportTap(BuildContext context) {
    if (widget.isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          // Auto-open report form on entry
          builder: (_) => const AdminMainPage(autoOpenReportForm: true),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReportForm()),
      );
    }
  }

  /// ============================== [Build] ==============================
  // NOTE: menu button / map-mode switch / report button are inline here rather
  // than extracted to _build... methods, unlike report_form.dart's pattern.
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

        //  3lines Menu
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
                  Icon(mapModeIcon(_mapMode), size: 16, color: emasColor),
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
              backgroundColor: emasColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('แจ้งปัญหาใหม่'),
            onPressed: () => _onNewReportTap(context),
          ),
        ),

        // Report detail sheet, shown when a marker on the map is tapped
        if (_selectedReport != null)
          ReportDetailSheet(
            report: _selectedReport!,
            onClose: () => setState(() => _selectedReport = null),
          ),
      ],
    );
  }
}
