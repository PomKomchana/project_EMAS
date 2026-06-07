import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'report_form.dart';
import 'report_list_page.dart';

const _appColor = Color(0xFFe85d6a);
const _swuCenter = LatLng(14.0956, 101.0010);
const _swuSW = LatLng(14.0880, 100.9920);
const _swuNE = LatLng(14.1040, 101.0100);

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
      // IndexedStack keeps each tab alive — no rebuild on tab switch
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
  const _DrawerItem({required this.icon, required this.label, required this.onTap});
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

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  final _mapController = MapController();
  LatLng? _userPosition;

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

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;

      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _userPosition = latLng);

      final inBounds = pos.latitude >= _swuSW.latitude &&
          pos.latitude <= _swuNE.latitude &&
          pos.longitude >= _swuSW.longitude &&
          pos.longitude <= _swuNE.longitude;

      if (inBounds) _mapController.move(latLng, 16);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _swuCenter,
            initialZoom: 15.5,
            minZoom: 14,
            maxZoom: 20,
            cameraConstraint: CameraConstraint.containCenter(
              bounds: LatLngBounds(_swuSW, _swuNE),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.plan_alert',
            ),
            if (_userPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userPosition!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_pin,
                        color: _appColor, size: 40),
                  ),
                ],
              ),
          ],
        ),
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
