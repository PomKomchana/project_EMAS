import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _appColor = Color(0xFFe85d6a);
const _appColorDark = Color(0xFFc4394a);

// ===== มศว องครักษ์ =====
const _swuCenter = LatLng(14.1076, 100.9822);
final _swuBounds = LatLngBounds(
  const LatLng(14.1010, 100.9750),
  const LatLng(14.1140, 100.9900),
);

// Tile URLs
const _tileNormal = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _tileSatellite =
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

class ReportForm extends StatefulWidget {
  const ReportForm({super.key});

  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> with TickerProviderStateMixin {
  // Controllers
  final _descController = TextEditingController();
  final _mapController = MapController();
  final _picker = ImagePicker();

  // Map expand animation
  late final AnimationController _mapAnimController;
  late final Animation<double> _mapHeightAnim;
  bool _isMapExpanded = false;

  // Section fade-in animations
  late final AnimationController _fadeController;
  late final List<Animation<Offset>> _slideAnims;
  late final List<Animation<double>> _fadeAnims;

  // Map state
  LatLng? _pickedLocation;
  bool _pickingMode = false;
  bool _useSatellite = false;

  // Form state
  String? _building;
  String? _floor;
  File? _image;
  bool _isSubmitting = false;

  static final _buildings = ['อาคาร 1', 'อาคาร 2', 'อาคาร 3', 'อาคาร 4', 'อาคาร 5', 'อาคาร 6', 'อาคาร 7', 'อาคาร 8', 'อาคาร 9', 'อาคาร 10',];
  static final _floors = ['ชั้น 1', 'ชั้น 2', 'ชั้น 3', 'ชั้น 4', 'ชั้น 5', 'ชั้น 6',
  ];

  @override
  void initState() {
    super.initState();

    _mapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() => setState(() {}));

    _mapHeightAnim = Tween<double>(begin: 200, end: 520).animate(
      CurvedAnimation(
          parent: _mapAnimController, curve: Curves.easeInOutCubic),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _slideAnims = List.generate(5, (i) {
      final start = i * 0.15;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _fadeController,
              curve: Interval(start, end, curve: Curves.easeOutCubic)));
    });

    _fadeAnims = List.generate(5, (i) {
      final start = i * 0.15;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start, end, curve: Curves.easeOut)));
    });

    _fadeController.forward();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapAnimController.dispose();
    _fadeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      if (_swuBounds.contains(latLng)) {
        _mapController.move(latLng, 16);
      }
    } catch (_) {}
  }

  void _toggleMapExpand({bool enterPickMode = false}) {
    HapticFeedback.lightImpact();
    setState(() {
      _isMapExpanded = !_isMapExpanded;
      if (_isMapExpanded) {
        _mapAnimController.forward();
        if (enterPickMode) _pickingMode = true;
        _mapController.fitCamera(
          CameraFit.bounds(
              bounds: _swuBounds, padding: const EdgeInsets.all(40)),
        );
      } else {
        _mapAnimController.reverse();
        _pickingMode = false;
      }
    });
  }

  void _onMapTap(_, LatLng position) {
    if (!_pickingMode) return;

    if (!_swuBounds.contains(position)) {
      HapticFeedback.heavyImpact();
      _showSnackBar('กรุณาเลือกตำแหน่งภายใน มศว องครักษ์ เท่านั้น',
          Colors.orange.shade700, Icons.warning_amber_rounded);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _pickedLocation = position);
    _mapController.move(position, 18);
  }

  void _confirmPin() {
    HapticFeedback.mediumImpact();
    _toggleMapExpand();
    _showSnackBar('ปักหมุดสำเร็จ ✓', Colors.green.shade600,
        Icons.check_circle_outline);
  }

  void _showSnackBar(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ));
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source);
    if (image != null) setState(() => _image = File(image.path));
  }

  void _showImagePicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImagePickerSheet(
        onCamera: () async {
          Navigator.pop(context);
          await _pickImage(ImageSource.camera);
        },
        onGallery: () async {
          Navigator.pop(context);
          await _pickImage(ImageSource.gallery);
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (_building == null || _floor == null) {
      _showSnackBar('กรุณาเลือกอาคารและชั้น', Colors.red.shade600,
          Icons.error_outline);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    await FirebaseFirestore.instance.collection('reports').add({
      'building': _building,
      'floor': _floor,
      'description': _descController.text.trim(),
      'status': 'รอดำเนินการ',
      'lat': _pickedLocation?.latitude,
      'lng': _pickedLocation?.longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    _showSnackBar(
        'ส่งแจ้งปัญหาเรียบร้อยแล้ว', Colors.green.shade600, Icons.check_circle);
    Navigator.pop(context);
  }

  Widget _animated(int i, Widget child) => FadeTransition(
        opacity: _fadeAnims[i],
        child: SlideTransition(position: _slideAnims[i], child: child),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_appColor, _appColorDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('แจ้งปัญหา',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            centerTitle: true,
          ),
        ),
      ),
      bottomNavigationBar: _animated(
        4,
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4))
            ],
          ),
          child: _GradientButton(
            onTap: _isSubmitting ? () {} : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('ส่งแจ้งซ่อม',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                    ],
                  ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: _isMapExpanded
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Map
            _animated(0, _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeader(
                      icon: Icons.location_on_rounded,
                      title: 'ตำแหน่งที่เกิดเหตุ'),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _mapAnimController,
                    builder: (_, child) =>
                        SizedBox(height: _mapHeightAnim.value, child: child),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _swuCenter,
                            initialZoom: 15,
                            minZoom: 14,
                            maxZoom: 20,
                            cameraConstraint: CameraConstraint.containCenter(
                                bounds: _swuBounds),
                            onTap: _onMapTap,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: _useSatellite
                                  ? _tileSatellite
                                  : _tileNormal,
                              userAgentPackageName: 'com.example.plan_alert',
                            ),
                            if (_pickedLocation != null)
                              MarkerLayer(markers: [
                                Marker(
                                  point: _pickedLocation!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_pin,
                                      color: _appColor, size: 40),
                                ),
                              ]),
                          ],
                        ),

                        // ปุ่มสลับ tile
                        Positioned(
                          top: 10,
                          left: 10,
                          child: _GlassMapButton(
                            icon: _useSatellite
                                ? Icons.satellite_alt
                                : Icons.map_outlined,
                            label: _useSatellite ? 'ดาวเทียม' : 'ปกติ',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _useSatellite = !_useSatellite);
                            },
                          ),
                        ),

                        // Banner picking mode
                        if (_pickingMode)
                          Positioned(
                            top: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _appColor.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      '📍  แตะเพื่อปักหมุดจุดเกิดเหตุ',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // ปุ่มยืนยัน
                        if (_pickingMode && _pickedLocation != null)
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: _GradientButton(
                              onTap: _confirmPin,
                              color1: Colors.green.shade500,
                              color2: Colors.green.shade700,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, size: 18),
                                  SizedBox(width: 6),
                                  Text('ยืนยันตำแหน่งนี้',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),

                        // ปุ่มปิด
                        if (_isMapExpanded && !_pickingMode)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: _toggleMapExpand,
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded,
                                        size: 18, color: Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_isMapExpanded)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        key: ValueKey(_pickedLocation),
                        children: [
                          Expanded(
                            child: _OutlineButton(
                              icon: Icons.my_location_rounded,
                              label: _pickedLocation == null
                                  ? 'เลือกตำแหน่ง'
                                  : 'เปลี่ยนตำแหน่ง',
                              onTap: () =>
                                  _toggleMapExpand(enterPickMode: true),
                            ),
                          ),
                          if (_pickedLocation != null) ...[
                            const SizedBox(width: 10),
                            const _PinBadge(),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            )),
            const SizedBox(height: 14),

            // 2. รูปภาพ
            _animated(1, _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeader(
                      icon: Icons.camera_alt_rounded, title: 'รูปภาพ'),
                  const SizedBox(height: 12),
                  if (_image != null) ...[
                    Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_image!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _showImagePicker,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(children: [
                                  Icon(Icons.edit_rounded,
                                      size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('เปลี่ยน',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                  ],
                  if (_image == null)
                    GestureDetector(
                      onTap: _showImagePicker,
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _appColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: _appColor.withValues(alpha: 0.3),
                              width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                size: 32,
                                color: _appColor.withValues(alpha: 0.7)),
                            const SizedBox(height: 6),
                            Text('แตะเพื่อเพิ่มรูปภาพ',
                                style: TextStyle(
                                    color: _appColor.withValues(alpha: 0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text('ถ่ายรูปหรือเลือกจากคลัง',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            )),
            const SizedBox(height: 14),

            // 3. สถานที่
            _animated(2, _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeader(
                      icon: Icons.apartment_rounded, title: 'สถานที่'),
                  const SizedBox(height: 12),
                  _StyledDropdown(
                    value: _building,
                    hint: 'เลือกอาคาร',
                    icon: Icons.domain_rounded,
                    items: _buildings,
                    onChanged: (v) => setState(() => _building = v),
                  ),
                  const SizedBox(height: 10),
                  _StyledDropdown(
                    value: _floor,
                    hint: 'เลือกชั้น',
                    icon: Icons.layers_rounded,
                    items: _floors,
                    onChanged: (v) => setState(() => _floor = v),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 14),

            // 4. รายละเอียด
            _animated(3, _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeader(
                      icon: Icons.edit_note_rounded,
                      title: 'รายละเอียดปัญหา'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'อธิบายปัญหาที่พบ...',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.grey.shade200, width: 1)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.grey.shade200, width: 1)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _appColor, width: 2)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// Reusable Widgets
// =====================================================

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.6), width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4))
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _appColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: _appColor),
      ),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: 0.2)),
    ]);
  }
}

class _GradientButton extends StatefulWidget {
  const _GradientButton({
    required this.onTap,
    required this.child,
    this.color1 = _appColor,
    this.color2 = _appColorDark,
  });
  final VoidCallback onTap;
  final Widget child;
  final Color color1;
  final Color color2;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.95,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [widget.color1, widget.color2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: widget.color1.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Center(
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white, fontSize: 15),
              child: IconTheme(
                  data: const IconThemeData(color: Colors.white),
                  child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: _appColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _appColor.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: _appColor),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: _appColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ]),
      ),
    );
  }
}

class _PinBadge extends StatelessWidget {
  const _PinBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(children: [
        Icon(Icons.check_circle_rounded,
            color: Colors.green.shade600, size: 15),
        const SizedBox(width: 4),
        Text('ปักหมุดแล้ว',
            style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _GlassMapButton extends StatelessWidget {
  const _GlassMapButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8), width: 1),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 14, color: _appColor),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
  });
  final String? value;
  final String hint;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null
              ? _appColor.withValues(alpha: 0.5)
              : Colors.grey.shade200,
          width: value != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            prefixIcon:
                Icon(icon, size: 18, color: _appColor.withValues(alpha: 0.7)),
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _ImagePickerSheet extends StatelessWidget {
  const _ImagePickerSheet(
      {required this.onCamera, required this.onGallery});
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              const Text('เพิ่มรูปภาพ',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(
                      child: _SheetOption(
                          icon: Icons.camera_alt_rounded,
                          label: 'ถ่ายรูป',
                          onTap: onCamera)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _SheetOption(
                          icon: Icons.photo_library_rounded,
                          label: 'คลังภาพ',
                          onTap: onGallery)),
                ]),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _appColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: _appColor.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _appColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _appColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: _appColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ]),
      ),
    );
  }
}
