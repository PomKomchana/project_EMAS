import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'report_form.dart';
import 'report_list_page.dart';

const _appColor = Color(0xFFe85d6a);

const _swuCenter = LatLng(14.1076, 100.9822);
final _swuBounds = LatLngBounds(
  southwest: const LatLng(14.1010, 100.9750),
  northeast: const LatLng(14.1140, 100.9900),
);

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static const _titles = ['Home', 'รายการแจ้งปัญหา', 'โปรไฟล์'];

  static const _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
    BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'รายการ'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
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
      drawer: _AppDrawer(onTap: (i) {
        Navigator.pop(context);
        setState(() => _selectedIndex = i);
      }),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [_HomePage(), ReportListPage(), _ProfilePage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: _appColor,
        unselectedItemColor: Colors.grey,
        items: _navItems,
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.onTap});
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: _appColor),
            child: Text('Plan Alert',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          _DrawerItem(icon: Icons.home, label: 'หน้าหลัก', onTap: () => onTap(0)),
          _DrawerItem(icon: Icons.list_alt, label: 'รายการแจ้งปัญหา', onTap: () => onTap(1)),
          _DrawerItem(icon: Icons.person, label: 'โปรไฟล์', onTap: () => onTap(2)),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}

// ===================================================
// Home Tab — Google Maps + ปุ่มแจ้งปัญหา
// ===================================================
class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  GoogleMapController? _mapController;
  LatLng? _userPosition;
  MapType _mapType = MapType.normal;

  static const _mapTypes = [
    MapType.normal,
    MapType.hybrid,
  ];

  static const _mapTypeLabels = ['ปกติ', 'ไฮบริด'];

  static const _mapTypeIcons = [
    Icons.map_outlined,
    Icons.layers_outlined,
  ];

  void _cycleMapType() {
    HapticFeedback.selectionClick();
    final next = (_mapTypes.indexOf(_mapType) + 1) % _mapTypes.length;
    setState(() => _mapType = _mapTypes[next]);
  }

  int get _mapTypeIndex => _mapTypes.indexOf(_mapType);

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;

      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _userPosition = latLng);

      final inBounds = _swuBounds.contains(latLng);
      if (inBounds) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 16),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Google Map เต็มหน้าจอ
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _swuCenter,
            zoom: 15.5,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            controller.animateCamera(
              CameraUpdate.newLatLngBounds(_swuBounds, 40),
            );
          },
          mapType: _mapType,
          cameraTargetBounds: CameraTargetBounds(_swuBounds),
          minMaxZoomPreference: const MinMaxZoomPreference(14, 20),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          compassEnabled: true,
          buildingsEnabled: true,
          markers: _userPosition != null
              ? {
                  Marker(
                    markerId: const MarkerId('user'),
                    position: _userPosition!,
                    infoWindow: const InfoWindow(title: 'ตำแหน่งของคุณ'),
                  ),
                }
              : {},
        ),

        // ปุ่ม Hamburger ลอยบนซ้าย
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

        // ปุ่มสลับ map type — glass style เหมือน report_form
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 68,
          child: GestureDetector(
            onTap: _cycleMapType,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9), width: 1),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_mapTypeIcons[_mapTypeIndex],
                          size: 16, color: _appColor),
                      const SizedBox(width: 6),
                      Text(
                        _mapTypeLabels[_mapTypeIndex],
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ปุ่ม Zoom มุมขวาบน ตรงแนวเดียวกับ hamburger
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: Column(
            children: [
              _ZoomButton(
                icon: Icons.add,
                onTap: () async {
                  final zoom = await _mapController?.getZoomLevel() ?? 15;
                  _mapController?.animateCamera(
                    CameraUpdate.zoomTo((zoom + 1).clamp(14, 20)),
                  );
                },
              ),
              const SizedBox(height: 6),
              _ZoomButton(
                icon: Icons.remove,
                onTap: () async {
                  final zoom = await _mapController?.getZoomLevel() ?? 15;
                  _mapController?.animateCamera(
                    CameraUpdate.zoomTo((zoom - 1).clamp(14, 20)),
                  );
                },
              ),
            ],
          ),
        ),

        // ปุ่มแจ้งปัญหาใหม่ ลอยด้านล่าง
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
                  borderRadius: BorderRadius.circular(12)),
              elevation: 6,
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('แจ้งปัญหาใหม่',
                style: TextStyle(fontSize: 16)),
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

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
      ),
    );
  }
}

// ===================================================
// Profile Tab — placeholder
// ===================================================
class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('โปรไฟล์', style: TextStyle(fontSize: 20, color: Colors.grey)),
        ],
      ),
    );
  }
}
