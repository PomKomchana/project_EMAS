import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _appColor = Color(0xFFe85d6a);

const _appColor = Color(0xFFe85d6a);
const _appColorLight = Color(0xFFff8a94);
const _appColorDark = Color(0xFFc4394a);

class ReportForm extends StatefulWidget {
  const ReportForm({super.key});

  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm>
    with TickerProviderStateMixin {

  // ===== Controllers =====
  final descController = TextEditingController();
  GoogleMapController? mapController;

  // ===== Map Expand Animation =====
  late AnimationController _mapAnimController;
  late Animation<double> _mapHeightAnim;
  bool _isMapExpanded = false;

  // ===== Section Fade-in Animations =====
  late AnimationController _fadeController;
  late List<Animation<Offset>> _slideAnims;
  late List<Animation<double>> _fadeAnims;

  // ===== มศว องครักษ์ =====
  static const LatLng _swuCenter = LatLng(14.107589754630002, 100.98220884149639);
  static final LatLngBounds _swuBounds = LatLngBounds(
    southwest: LatLng(14.1010, 100.9750),
    northeast: LatLng(14.1140, 100.9900),
  );

  // ===== Map State =====
  LatLng? _pickedLocation;
  LatLng _initialPosition = _swuCenter;
  Set<Marker> _markers = {};
  bool _pickingMode = false;
  MapType _mapType = MapType.normal;

  // ===== Form State =====
  String? selectedBuilding;
  String? selectedFloor;
  File? selectedImage;

  final List<String> buildings = List.generate(10, (i) => 'อาคาร ${i + 1}');
  final List<String> floors = List.generate(6, (i) => 'ชั้น ${i + 1}');

  @override
  void initState() {
    super.initState();

    // Map expand animation
    _mapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _mapHeightAnim = Tween<double>(begin: 200, end: 520).animate(
      CurvedAnimation(parent: _mapAnimController, curve: Curves.easeInOutCubic),
    );
    _mapAnimController.addListener(() => setState(() {}));

    // Section fade-in animations (5 sections)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideAnims = List.generate(5, (i) {
      final start = i * 0.15;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _fadeController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));
    });
    _fadeAnims = List.generate(5, (i) {
      final start = i * 0.15;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _fadeController.forward();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapAnimController.dispose();
    _fadeController.dispose();
    descController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  // ===== Get Current Location =====
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      final userLatLng = LatLng(pos.latitude, pos.longitude);
      final bool inBounds = _swuBounds.contains(userLatLng);
      final LatLng startPos = inBounds ? userLatLng : _swuCenter;

      setState(() => _initialPosition = startPos);

      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(startPos, 16),
      );
    } catch (_) {}
  }

  // ===== Toggle Map Expand =====
  void _toggleMapExpand({bool enterPickMode = false}) {
    HapticFeedback.lightImpact();
    if (!_isMapExpanded) {
      _isMapExpanded = true;
      _mapAnimController.forward();
      if (enterPickMode) setState(() => _pickingMode = true);
      mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(_swuBounds, 40),
      );
    } else {
      _isMapExpanded = false;
      _mapAnimController.reverse();
      setState(() => _pickingMode = false);
    }
  }

  // ===== On Map Tap =====
  void _onMapTap(LatLng position) {
    if (!_pickingMode) return;

    if (!_swuBounds.contains(position)) {
      HapticFeedback.heavyImpact();
      _showSnackBar(
        'กรุณาเลือกตำแหน่งภายใน มศว องครักษ์ เท่านั้น',
        Colors.orange.shade700,
        Icons.warning_amber_rounded,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _pickedLocation = position;
      _markers = {
        Marker(
          markerId: const MarkerId('incident'),
          position: position,
          infoWindow: const InfoWindow(title: 'จุดเกิดเหตุ'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, 18),
    );
  }

  // ===== Confirm Pin =====
  void _confirmPin() {
    HapticFeedback.mediumImpact();
    _toggleMapExpand();
    _showSnackBar(
      'ปักหมุดสำเร็จ ✓',
      Colors.green.shade600,
      Icons.check_circle_outline,
    );
  }

  // ===== Snackbar Helper =====
  void _showSnackBar(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ===== Pick Image =====
  Future<void> pickImage() async {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImagePickerSheet(
        onCamera: () async {
          Navigator.pop(context);
          final image =
              await ImagePicker().pickImage(source: ImageSource.camera);
          if (image != null) setState(() => selectedImage = File(image.path));
        },
        onGallery: () async {
          Navigator.pop(context);
          final image =
              await ImagePicker().pickImage(source: ImageSource.gallery);
          if (image != null) setState(() => selectedImage = File(image.path));
        },
      ),
    );
  }

  // ===== Submit =====
  void submitReport() {
    HapticFeedback.mediumImpact();
    print("Building: $selectedBuilding");
    print("Floor: $selectedFloor");
    print("Description: ${descController.text}");
    print("Location: $_pickedLocation");
  }

  // ===== Map Type =====
  String get _mapTypeLabel {
    switch (_mapType) {
      case MapType.normal: return 'ปกติ';
      case MapType.satellite: return 'ดาวเทียม';
      case MapType.hybrid: return 'ไฮบริด';
      case MapType.terrain: return 'ภูมิประเทศ';
      default: return '';
    }
  }

  IconData get _mapTypeIcon {
    switch (_mapType) {
      case MapType.normal: return Icons.map_outlined;
      case MapType.satellite: return Icons.satellite_alt;
      case MapType.hybrid: return Icons.layers_outlined;
      case MapType.terrain: return Icons.terrain;
      default: return Icons.map_outlined;
    }
  }

  void _cycleMapType() {
    HapticFeedback.selectionClick();
    setState(() {
      switch (_mapType) {
        case MapType.normal: _mapType = MapType.terrain; break;
        case MapType.terrain: _mapType = MapType.satellite; break;
        case MapType.satellite: _mapType = MapType.hybrid; break;
        case MapType.hybrid: _mapType = MapType.normal; break;
        default: _mapType = MapType.normal;
      }
    });
  }

  // ===== Slide-in wrapper =====
  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(
        position: _slideAnims[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFFF2F2F7), // iOS system background

      // ===== AppBar =====
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
            title: const Text(
              "แจ้งปัญหา",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.3,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),

      // ===== Floating Submit Button =====
      bottomNavigationBar: _animated(
        4,
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: _GradientButton(
            onTap: submitReport,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  "ส่งแจ้งซ่อม",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
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

            /// =====================================================
            /// 1. Map Section
            /// =====================================================
            _animated(0, _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                    icon: Icons.location_on_rounded,
                    title: "ตำแหน่งที่เกิดเหตุ",
                  ),
                  const SizedBox(height: 12),

                  // แผนที่
                  AnimatedBuilder(
                    animation: _mapAnimController,
                    builder: (context, child) => SizedBox(
                      height: _mapHeightAnim.value,
                      child: child,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _swuCenter,
                              zoom: 15,
                            ),
                            mapType: _mapType,
                            onMapCreated: (c) {
                              mapController = c;
                              c.animateCamera(
                                CameraUpdate.newLatLngBounds(_swuBounds, 40),
                              );
                            },
                            cameraTargetBounds:
                                CameraTargetBounds(_swuBounds),
                            minMaxZoomPreference:
                                const MinMaxZoomPreference(14, 20),
                            markers: _markers,
                            onTap: _onMapTap,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: _isMapExpanded,
                            zoomControlsEnabled: _isMapExpanded,
                            buildingsEnabled: true,
                            compassEnabled: true,
                          ),

                          // Glass Map Type Button
                          Positioned(
                            top: 10,
                            left: 10,
                            child: _GlassMapButton(
                              icon: _mapTypeIcon,
                              label: _mapTypeLabel,
                              onTap: _cycleMapType,
                            ),
                          ),

                          // Banner picking
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
                                        color: _appColor.withOpacity(0.75),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        "📍  แตะเพื่อปักหมุดจุดเกิดเหตุ",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Confirm button
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
                                    Text("ยืนยันตำแหน่งนี้",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),

                          // Close button
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
                                        color:
                                            Colors.white.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ปุ่มใต้แผนที่
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
                                  ? "เลือกตำแหน่ง"
                                  : "เปลี่ยนตำแหน่ง",
                              onTap: () =>
                                  _toggleMapExpand(enterPickMode: true),
                            ),
                          ),
                          if (_pickedLocation != null) ...[
                            const SizedBox(width: 10),
                            _PinBadge(),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            )),

            const SizedBox(height: 14),

            /// =====================================================
            /// 2. Image Section
            /// =====================================================
            _animated(1, _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                    icon: Icons.camera_alt_rounded,
                    title: "รูปภาพ",
                  ),
                  const SizedBox(height: 12),

                  if (selectedImage != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            selectedImage!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // ปุ่มเปลี่ยนรูปบนรูป
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: pickImage,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.edit_rounded,
                                          size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text("เปลี่ยน",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (selectedImage == null)
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _appColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _appColor.withOpacity(0.3),
                            width: 1.5,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                size: 32, color: _appColor.withOpacity(0.7)),
                            const SizedBox(height: 6),
                            Text(
                              "แตะเพื่อเพิ่มรูปภาพ",
                              style: TextStyle(
                                color: _appColor.withOpacity(0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "ถ่ายรูปหรือเลือกจากคลัง",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            )),

            const SizedBox(height: 14),

            /// =====================================================
            /// 3. Location Detail Section
            /// =====================================================
            _animated(2, _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                    icon: Icons.apartment_rounded,
                    title: "สถานที่",
                  ),
                  const SizedBox(height: 12),
                  _StyledDropdown(
                    value: selectedBuilding,
                    hint: "เลือกอาคาร",
                    icon: Icons.domain_rounded,
                    items: buildings,
                    onChanged: (v) => setState(() => selectedBuilding = v),
                  ),
                  const SizedBox(height: 10),
                  _StyledDropdown(
                    value: selectedFloor,
                    hint: "เลือกชั้น",
                    icon: Icons.layers_rounded,
                    items: floors,
                    onChanged: (v) => setState(() => selectedFloor = v),
                  ),
                ],
              ),
            )),

            const SizedBox(height: 14),

            /// =====================================================
            /// 4. Description Section
            /// =====================================================
            _animated(3, _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                    icon: Icons.edit_note_rounded,
                    title: "รายละเอียดปัญหา",
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                    decoration: InputDecoration(
                      hintText: "อธิบายปัญหาที่พบ...",
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.grey.shade200, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.grey.shade200, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _appColor, width: 2),
                      ),
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
  final Widget child;
  const _GlassCard({required this.child});

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
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _CardHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _appColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _appColor),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color color1;
  final Color color2;

  const _GradientButton({
    required this.onTap,
    required this.child,
    this.color1 = _appColor,
    this.color2 = _appColorDark,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _scaleController;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.reverse(),
      onTapUp: (_) {
        _scaleController.forward();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.forward(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color1, widget.color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.color1.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white, fontSize: 15),
              child: IconTheme(
                data: const IconThemeData(color: Colors.white),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: _appColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _appColor.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: _appColor),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: _appColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _PinBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: Colors.green.shade600, size: 15),
          const SizedBox(width: 4),
          Text("ปักหมุดแล้ว",
              style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _GlassMapButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GlassMapButton(
      {required this.icon, required this.label, required this.onTap});

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
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.white.withOpacity(0.8), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: _appColor),
                const SizedBox(width: 4),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null ? _appColor.withOpacity(0.5) : Colors.grey.shade200,
          width: value != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: _appColor.withOpacity(0.7)),
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
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _ImagePickerSheet(
      {required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "เพิ่มรูปภาพ",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SheetOption(
                          icon: Icons.camera_alt_rounded,
                          label: "ถ่ายรูป",
                          onTap: onCamera,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SheetOption(
                          icon: Icons.photo_library_rounded,
                          label: "คลังภาพ",
                          onTap: onGallery,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SheetOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _appColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _appColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _appColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _appColor, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: _appColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }
}
