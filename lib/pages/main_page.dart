import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../admin/pages/admin_main.dart';
import 'annoucement_page.dart';
import 'profile_page.dart';
import 'emergency_page.dart';
import 'mark.dart';
import 'report_sheet.dart';
import '../report/pages/report_list_page.dart';
import '../report/pages/report_form.dart';

import '../shared/constants/emas_colors.dart';
import '../shared/constants/map_constants.dart';

// App shell: bottom nav (Home/Reports/News/Profile) + drawer (Admin/Emergency)
// No AppBar here — each tab that needs one (ReportListPage/AnnouncementPage) owns its own [MainPage]
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
  // Display name shown in the drawer header, built from firstName + lastName [_userName]
  String? _userName;

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
    _loadUserData();
  }

  /// ============================== [User Data Logic] ==============================
  // Reads users/{uid}.role (admin gating) + firstName/lastName (drawer header),
  // same fields written/read by ProfilePage / ProfileDetailPage. [_loadUserData]
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data();

      final firstName = data?['firstName'] as String?;
      final lastName = data?['lastName'] as String?;
      final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();

      setState(() {
        _isAdmin = data?['role'] == 'admin';
        _userName = fullName.isNotEmpty ? fullName : 'ผู้ใช้งาน';
      });
    } catch (e) {
      debugPrint('User data error: $e');
    }
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // No AppBar here — each tab (ReportListPage/AnnouncementPage) owns its own AppBar now
      drawer: _AppDrawer(
        isAdmin: _isAdmin,
        userName: _userName,
        onTap: (i) {
          Navigator.pop(context);
          setState(() => _selectedIndex = i);
        },

        onProfileTap: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = 3);
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
          AnnouncementPage(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
          ProfilePage(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            isAdmin: _isAdmin,
          ),
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

// Side drawer: profile header + nav shortcuts + conditional Admin Dashboard entry [_AppDrawer]
class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.onTap,
    required this.onAdmin,
    required this.isAdmin,
    required this.onEmergency,
    required this.onProfileTap,
    this.userName,
  });

  final void Function(int) onTap;
  final VoidCallback onAdmin;
  final bool isAdmin;
  final VoidCallback onEmergency;
  final VoidCallback onProfileTap;
  final String? userName;

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFAFAFA),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [DRAWER-HEADER] Profile avatar + user name, tappable to open profile tab
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onProfileTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: emasColor,
                        child: const Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName ?? 'กำลังโหลด...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ดูโปรไฟล์',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
            ),

            if (isAdmin) ...[
              _SectionLabel('จัดการระบบ'),
              _DrawerItem(
                icon: Icons.space_dashboard_rounded,
                label: 'Admin Dashboard',
                onTap: onAdmin,
                iconColor: emasColor,
              ),
              const SizedBox(height: 8),
              const _DrawerDivider(),
            ],

            _SectionLabel('เมนูหลัก'),
            _DrawerItem(icon: Icons.home_rounded, label: 'หน้าหลัก', onTap: () => onTap(0)),
            _DrawerItem(icon: Icons.list_alt_rounded, label: 'รายการแจ้งปัญหา', onTap: () => onTap(1)),
            _DrawerItem(icon: Icons.notifications_none_rounded, label: 'ข่าวสาร', onTap: () => onTap(2)),
            _DrawerItem(icon: Icons.person_rounded, label: 'โปรไฟล์', onTap: () => onTap(3)),

            const SizedBox(height: 8),
            const _DrawerDivider(),

            _DrawerItem(
              icon: Icons.phone_in_talk_rounded,
              label: 'เบอร์โทรฉุกเฉิน',
              onTap: onEmergency,
              iconColor: Colors.red.shade400,
              labelColor: Colors.red.shade400,
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// Small uppercase section label above a group of drawer items [_SectionLabel]
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}

// Thin inset divider between sections, less harsh than full-width [_DrawerDivider]
class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }
}

// Single drawer row, rounded + inset with tap ripple contained to the row [_DrawerItem]
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor ?? Colors.grey.shade700),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Single drawer item [_DrawerItem] rows plus divider [_DrawerDivider] are used above;
// note: original file also has private widget classes below for the map tab
// (_HomePage, ReportMarkerLayer usage, etc.) — unchanged from before, kept as-is.

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
            initialCenter: const LatLng(14.1076, 100.9833),
            initialZoom: 14.8,
            minZoom: 14,
            maxZoom: 20,
            cameraConstraint: CameraConstraint.containCenter(bounds: mapBounds),
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