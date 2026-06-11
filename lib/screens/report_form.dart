/// <<<<< [1. Import] (นำเข้า package / library) >>>>>
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ====================================================================================================

/// <<<<< [2. Constants] Const Variable (ประกาศค่าคงที่ / ตัวแปรที่ไม่เปลี่ยน) >>>>>
// EMAS Theme Colors [_emasColor, _emasColorDarker]
const _emasColor = Color(0xFFe85d6a);
const _emasColorDarker = Color(0xFFc4394a);

// Google Map Location and Bounds config [_mapLocation, _mapBounds]
const _mapLocation = LatLng(14.1076, 100.9822);
final _mapBounds = LatLngBounds(
  const LatLng(14.1010, 100.9750),
  const LatLng(14.1140, 100.9900),
);

// Tile URL-GoogleMap [_titleNormal, _tileHybrid, _tileSatellite, _tileTerrain]
const _tileNormal = 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
const _tileHybrid = 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
const _tileSatellite = 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
const _tileTerrain   = 'https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
// ====================================================================================================

/// <<<<< [3. Enum] (ชุดตัวเลือกแบบจำกัด) >>>>>
// Map mode [_MapMod]
enum _MapMode {normal, hybrid, satellite, terrain,}
// ====================================================================================================

/// <<<<< [4. Widget Class] ReportForm (ตัวแม่ของหน้าจอ | หน้าที่: สร้างหน้า / ส่งต่อให้ State จัดการ) >>>>>
class ReportForm extends StatefulWidget {
  const ReportForm({super.key});

  @override
  State<ReportForm> createState() => _ReportFormState();
}
// ====================================================================================================

/// <<<<< [5. State Class] _ReportFormState (สมองของหน้าจอ | หน้าที่: เก็บข้อมูล / เปลี่ยน UI / รับ event / คนควบคุม) >>>>>
// State class of ReportForm (Handles UI state, animation, map, image picker, and Firestore submit)
class _ReportFormState extends State<ReportForm> with TickerProviderStateMixin {
// ----------------------------------------------------------------------------------------------------

  /// [5.1 Controllers] (ตัวควบคุม)
  // Controllers [_descController, _mapController, _imagePicker]
  final _dateController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  final _mapController = MapController();
  final _imagePicker = ImagePicker();

  // Animation Controllers
    // Map expansion animation [_mapAnimController, _mapHeightAnimation]
    late final AnimationController _mapAnimController;
    late final Animation<double> _mapHeightAnimation;

    // Page entrance animation (stagger fade + slide) [_sectionFadeController, _sectionFadeList, _sectionSlideList]
    late final AnimationController _sectionFadeController;
    late final List<Animation<double>> _sectionFadeList;
    late final List<Animation<Offset>> _sectionSlideList;
  // ----------------------------------------------------------------------------------------------------

  /// [5.2 State Variable] (ตัวแปรสถานะ)
  // Map State [_isMapExpanded, _isPickingMode, _mapMode, _pickedLocation]
  bool _isMapExpanded = false;         // Whether the map is currently expanded
  bool _isPickingMode = false;         // Whether the user is in pin selection mode (waiting for map tap)
  _MapMode _mapMode = _MapMode.normal; // Current map display mode
  LatLng? _pickedLocation;             // Selected pinned location on the map

  // Form State [_selecetedBuilding, _selectedFloor, _selectedImage, _selectedRoom, _isSubmitting]
  String? _selectedBuilding;
  String? _selectedFloor;
  String? _selectedRoom;
  File? _selectedImage;
  bool _isSubmitting = false;

  // Dropdown Options [_buildingOptions, _floorOptions, _roomOptions]
  static const _buildingOptions = ['อาคาร 1', 'อาคาร 2', 'อาคาร 3', 'อาคาร 4', 'อาคาร 5',];
  static const _floorOptions = ['ชั้น 1', 'ชั้น 2', 'ชั้น 3', 'ชั้น 4', 'ชั้น 5',];
  static const _roomOptions = ['110', '111', '112', '113', '114',];
  // ----------------------------------------------------------------------------------------------------

  /// [5.3 Lifecycle Methods] (เมธอดตามวงจรชีวิต | เช่น: เปิดหน้า → initState ปิดหน้า → dispose เหมือน “เกิด → ใช้งาน → ตาย”)
  // InitState (Initialize state and prepare data before UI renders) [_setupAnimations, _sectionFadeController, _requestLocationAndMove]
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _sectionFadeController.forward(); // Start animation
    _requestLocationAndMove();        // Request GPS and move the camera
  }

  // Dispose (Return resource when you leave this page)
  @override
  void dispose() {
    _mapAnimController.dispose();
    _sectionFadeController.dispose();

    _dateController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _descController.dispose();

    _mapController.dispose();
    super.dispose();
  }

    // Setup Animations [_setupAnimations]
    void _setupAnimations() {
      // Map Animation 200 → 520
      _mapAnimController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..addListener(() => setState(() {}));

      _mapHeightAnimation = Tween<double>(begin: 200, end: 520).animate(
        CurvedAnimation(
          parent: _mapAnimController,
          curve: Curves.easeInOutCubic,
        ),
      );

      // Fade + slide animation for 5 sections (Stagger per section)
      _sectionFadeController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      );

      _sectionFadeList = List.generate(6, (index) {
        final startTime = index * 0.15;
        final endTime = (startTime + 0.5).clamp(0.0, 1.0);
        return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _sectionFadeController,
            curve: Interval(startTime, endTime, curve: Curves.easeOut),
          ),
        );
      });

      _sectionSlideList = List.generate(6, (index) {
        final startTime = index * 0.15;
        final endTime = (startTime + 0.5).clamp(0.0, 1.0);
        return Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _sectionFadeController,
            curve: Interval(startTime, endTime, curve: Curves.easeOutCubic),
          ),
        );
      });
    }
  // ----------------------------------------------------------------------------------------------------

  /// [5.4 Helper / Logic Methods] (ฟังก์ชันช่วย + ตรรกะ | ทำงานเบื้องหลัง / ไม่ใช่สร้าง UI)
  // Request GPS permission and move map to user location [_requestLocationAndMove]
  Future<void> _requestLocationAndMove() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final userLatLng = LatLng(position.latitude, position.longitude);

      // GPS can move only in _mapBounds area
      if (_mapBounds.contains(userLatLng)) {
        _mapController.move(userLatLng, 16);
      }
    } catch (_) {
      // if can't find GPS then use initialCenter location
    }
  }

  // Expand / collapse map and optionally enter picking mode [_toggleMapExpand]
  void _toggleMapExpand({bool enterPickingMode = false}) {
    HapticFeedback.lightImpact();
    setState(() {
      _isMapExpanded = !_isMapExpanded;
      if (_isMapExpanded) {
        _mapAnimController.forward();
        if (enterPickingMode) _isPickingMode = true;
        // Zoom Out to full map
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: _mapBounds,
            padding: const EdgeInsets.all(40),
          ),
        );
      } else {
        _mapAnimController.reverse();
        _isPickingMode = false;
      }
    });
  }

  // Handle map tap and set pin location [_onMapTapped]
  void _onMapTapped(TapPosition tapPosition, LatLng tappedPosition) {
    if (!_isPickingMode) return;

    // ตรวจสอบว่าอยู่ใน มศว ไหม
    if (!_mapBounds.contains(tappedPosition)) {
      HapticFeedback.heavyImpact();
      _showSnackBar(
        'กรุณาเลือกตำแหน่งภายใน มศว องครักษ์ เท่านั้น',
        Colors.orange.shade700,
        Icons.warning_amber_rounded,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _pickedLocation = tappedPosition);
    _mapController.move(tappedPosition, 18);
  }

  // Confirm selected pin location [_confirmPin]
  void _confirmPin() {
    HapticFeedback.mediumImpact();
    _toggleMapExpand(); // ย่อแผนที่กลับ
    _showSnackBar('ปักหมุดสำเร็จ ✓', Colors.green.shade600,
        Icons.check_circle_outline);
  }
  // ----------------------------------------------------------------------------------------------------

  // ====================================================================================================

/// >>>>> [6.Getters] (ตัวคืนค่าแบบคำนวณ) <<<<<
// Get current tile URL from selected map mode [_currentTileUrl]
String get _currentTileUrl {
  switch (_mapMode) {
    case _MapMode.normal:    return _tileNormal;
    case _MapMode.hybrid:    return _tileHybrid;
    case _MapMode.satellite: return _tileSatellite;
    case _MapMode.terrain:   return _tileTerrain;
  }
}

// Get current map mode label [_mapModeLabel]
String get _mapModeLabel {
  switch (_mapMode) {
    case _MapMode.normal:    return 'ปกติ';
    case _MapMode.hybrid:    return 'ไฮบริด';
    case _MapMode.satellite: return 'ดาวเทียม';
    case _MapMode.terrain:   return 'ภูมิประเทศ';
  }
}

// Get current map mode icon [_mapModeIcon]
IconData get _mapModeIcon {
  switch (_mapMode) {
    case _MapMode.normal:    return Icons.map_outlined;
    case _MapMode.hybrid:    return Icons.layers_outlined;
    case _MapMode.satellite: return Icons.satellite_alt;
    case _MapMode.terrain:   return Icons.terrain;
  }
}

// Switch to next map mode [_cycleMapMode]
void _cycleMapMode() {
  HapticFeedback.selectionClick();
  setState(() {
    final modes = _MapMode.values; // [normal, satellite, terrain, hybrid,]
    final nextIndex = (modes.indexOf(_mapMode) + 1) % modes.length;
    _mapMode = modes[nextIndex];
  });
}

  // Show image picker bottom sheet [_showImagePickerSheet]
  void _showImagePickerSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildImagePickerSheet(),
    );
  }

  // Pick image from selected source [_pickImageForm]
  Future<void> _pickImageFrom(ImageSource source) async {
    final picked = await _imagePicker.pickImage(source: source);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  // Submit report to Firestore [_submitReport]
  Future<void> _submitReport() async {
    // Check the necessary information
    if (_selectedBuilding == null || _selectedFloor == null || _selectedRoom == null) {
      _showSnackBar(
        'กรุณาเลือกอาคารและชั้น',
        Colors.red.shade600,
        Icons.error_outline,
      );
      return;
    }

    HapticFeedback.mediumImpact();

      try {
        setState(() => _isSubmitting = true);

        await FirebaseFirestore.instance.collection('reports').add({
          'building': _selectedBuilding,
          'floor': _selectedFloor,
          'room': _selectedRoom,

          'date': _dateController.text,
          'username': _usernameController.text,
          'phone': _phoneController.text,

          'description': _descController.text.trim(),

          'status': 'รอดำเนินการ',
          'lat': _pickedLocation?.latitude,
          'lng': _pickedLocation?.longitude,

          'createdAt': FieldValue.serverTimestamp(),
        });

      if (!mounted) return;

      _showSnackBar('ส่งแจ้งปัญหาเรียบร้อยแล้ว',
          Colors.green, Icons.check_circle);

      Navigator.pop(context);

    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e', Colors.red, Icons.error);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Show snackbar message  [_showSnackBar]
  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(message,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // Apply fade + slide animation to section [_withSectionAnimation]
  Widget _withSectionAnimation(int sectionIndex, Widget child) {
    return FadeTransition(
      opacity: _sectionFadeList[sectionIndex],
      child: SlideTransition(
        position: _sectionSlideList[sectionIndex],
        child: child,
      ),
    );
  }
  // =============================================================

  /// >>>>> [7.Build] (วาดหน้าจอหลัก | Flutter จะเรียกตรงนี้เพื่อสร้าง UI) <<<<<
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),

      // ----- AppBar -----
      appBar: _buildAppBar(),

      // ----- Submit Bar at bottom -----
      bottomNavigationBar: _withSectionAnimation(4, _buildSubmitBar()),

      // ----- Main -----
      body: SingleChildScrollView(
        physics: _isMapExpanded
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        // Setup Column Layout
        child: Column(
          children: [
            _withSectionAnimation(0, _buildMapSection()),
            const SizedBox(height: 14),

            _withSectionAnimation(1, _buildReporterSection()),
            const SizedBox(height: 14),

            _withSectionAnimation(2, _buildLocationSection()),
            const SizedBox(height: 14),

            _withSectionAnimation(3, _buildDescriptionSection()),
            const SizedBox(height: 8),

            _withSectionAnimation(4, _buildImageSection()),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  // ----- App Bar -----
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_emasColor, _emasColorDarker],
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
            'บันทึกแจ้งปัญหา',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
      ),
    );
  }

  // ----- Submit Bar -----
  Widget _buildSubmitBar() {
    return Container(
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
      child: _buildGradientButton(
        onTap: _isSubmitting ? () {} : _submitReport,
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'ส่งแจ้งปัญหา',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ----- Map -----
  Widget _buildMapSection() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Card Header (ตำแหน่งที่เกิดเหตุ)
          _buildCardHeader(
              icon: Icons.location_on_rounded, title: 'ตำแหน่งที่เกิดเหตุ'),
          const SizedBox(height: 12),

          // Map Altitude changes with animation.
          AnimatedBuilder(
            animation: _mapAnimController,
            builder: (_, child) => SizedBox(
              height: _mapHeightAnimation.value,
              child: child,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [

                  // Flutter Map
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _mapLocation,
                      initialZoom: 15,
                      minZoom: 14,
                      maxZoom: 20,
                      cameraConstraint: CameraConstraint.containCenter(
                          bounds: _mapBounds),
                      onTap: _onMapTapped,
                    ),
                    children: [

                      TileLayer(
                        urlTemplate: _currentTileUrl,
                        userAgentPackageName: 'com.example.plan_alert',
                      ),
                      
                      if (_pickedLocation == null)
                        const SizedBox.shrink()
                      else
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _pickedLocation!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_pin,
                                color: _emasColor,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  // Map Mode Bottom
                  Positioned(
                    top: _isMapExpanded ? 50 : 10, // Expand = scroll down, Reduce = scroll up
                    left: 10,
                    child: _buildGlassMapButton(
                      icon: _mapModeIcon,
                      label: _mapModeLabel,
                      onTap: _cycleMapMode,
                    ),
                  ),

                  // Banner (แตะเพื่อปักหมุดจุดเกิดเหตุ)
                  if (_isPickingMode)
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildPickingBanner()),
                    ),

                  // Confirm Picking Location
                  if (_isPickingMode && _pickedLocation != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: _buildGradientButton(
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

                  // Close Map
                  if (_isMapExpanded && !_isPickingMode)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _buildCloseMapButton(),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Button Below Map (ปักหมุดแล้ว)
          if (!_isMapExpanded)
            Row(
              children: [
                Expanded(
                  child: _buildOutlineButton(
                    icon: Icons.my_location_rounded,
                    label: _pickedLocation == null
                        ? 'เลือกตำแหน่ง'
                        : 'เปลี่ยนตำแหน่ง',
                    onTap: () =>
                        _toggleMapExpand(enterPickingMode: true),
                  ),
                ),
                if (_pickedLocation != null) ...[
                  const SizedBox(width: 10),
                  _buildPinBadge(),
                ],
              ],
            ),
        ],
      ),
    );
  }

  /// >>>>> [8. UI Builder Method] (ฟังก์ชันสร้าง UI ย่อย | เอาไว้แยก build ให้อ่านง่าย) <<<<<
  /// [8.1 Report Info Section] (_buildReporterSection)
  Widget _buildReporterSection() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.person_outline,
            title: 'ข้อมูลผู้แจ้ง',
          ),

          const SizedBox(height: 12),

          // Date Report "วันที่แจ้งซ่อม"
          TextField(
            controller: _dateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'วันที่แจ้งซ่อม',
              labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.calendar_today, color: _emasColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _emasColor, width: 2),
              ),
            ),

            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2025),
                lastDate: DateTime(2035),
              );

              if (date != null) {
                _dateController.text = '${date.day}/${date.month}/${date.year}';
              }
            },
          ),

          const SizedBox(height: 10),

          // Username "ชื่อผู้แจ้ง"
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'ชื่อผู้แจ้ง',
              labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.person, color: _emasColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _emasColor, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // User Phone Numbers "เบอร์ติดต่อ"
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'เบอร์ติดต่อ',
              labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.phone, color: _emasColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _emasColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// [8.2 Location Section] (_buildLocationSection)
  Widget _buildLocationSection() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
              icon: Icons.apartment_rounded, title: 'สถานที่'),
          const SizedBox(height: 12),
          _buildStyledDropdown(
            value: _selectedBuilding,
            hint: 'เลือกอาคาร',
            icon: Icons.domain_rounded,
            items: _buildingOptions,
            onChanged: (value) =>
                setState(() => _selectedBuilding = value),
          ),
          const SizedBox(height: 10),
          _buildStyledDropdown(
            value: _selectedFloor,
            hint: 'เลือกชั้น',
            icon: Icons.layers_rounded,
            items: _floorOptions,
            onChanged: (value) => setState(() => _selectedFloor = value),
          ),
          const SizedBox(height: 10),
          _buildStyledDropdown(
            value: _selectedRoom,
            hint: 'เลือกห้อง',
            icon: Icons.meeting_room_outlined,
            items: _roomOptions,
            onChanged: (value) => setState(() => _selectedRoom = value),
          ),
        ],
      ),
    );
  }

  /// [8.3 Description Section] (_buildDescriptionSection)
  Widget _buildDescriptionSection() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
              icon: Icons.edit_note_rounded, title: 'รายละเอียดปัญหา'),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 5,
            style: const TextStyle(fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText: 'อธิบายปัญหาที่พบ...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _emasColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// [8.4 Image Section] (_buildImageSection)
  Widget _buildImageSection() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
              icon: Icons.camera_alt_rounded, title: 'รูปภาพ'),
          const SizedBox(height: 12),

          // If an image is already present → display the image with a change button
          if (_selectedImage != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _selectedImage!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),  
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildChangeImageButton(),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // But if an image not present → show Placeholder box
          if (_selectedImage == null)
            _buildImagePlaceholder(),
        ],
      ),
    );
  }


  /// [8.5 Glass Card]
  // Glass card with a clear white background (_buildGlassCard)
  Widget _buildGlassCard({required Widget child}) {
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
                color: Colors.white.withOpacity(0.6), width: 1),
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

  /// [8.6 Section Header]
  // Setup Section Header (icon + name + color) (_buildCardHeader)
  Widget _buildCardHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _emasColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _emasColor),
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

  /// [8.7 Gradiant Button]
  // Gradient Button (Used with the submit button and confirm pin button) (_buildGradientButton)
  Widget _buildGradientButton({
    required VoidCallback onTap,
    required Widget child,
    Color color1 = _emasColor,
    Color color2 = _emasColorDarker,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color1.withOpacity(0.4),
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
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// [8.8 Red Outline Button]
  // Red Outline Button (_buildOutlineButton)
  Widget _buildOutlineButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: _emasColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _emasColor.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: _emasColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: _emasColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [8.9 Green Badge]
  // Green Badge "ปักหมุดแล้ว" (_buildPinBadge)
  Widget _buildPinBadge() {
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
          Text(
            'ปักหมุดแล้ว',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// [8.10 Glass Map Botton]
  // Glass Button on the map (Map Mode) (_buildGlassMapButton)
  Widget _buildGlassMapButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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
                Icon(icon, size: 14, color: _emasColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// [8.11 Picking Banner]
  // Banner "แตะเพื่อปักหมุด" (_buildPickingBanner)
  Widget _buildPickingBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _emasColor.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '📍  แตะเพื่อปักหมุดจุดเกิดเหตุ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// [8.12 Close Map Button]
  // The X Button closes the Glass Map (_buildCloseMapButton)
  Widget _buildCloseMapButton() {
    return GestureDetector(
      onTap: _toggleMapExpand,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded,
                size: 18, color: Colors.black87),
          ),
        ),
      ),
    );
  }

  /// [8.13 Change Image Button]
  // Button "เปลี่ยน" on Image (_buildChangeImageButton)
  Widget _buildChangeImageButton() {
    return GestureDetector(
      onTap: _showImagePickerSheet,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text('เปลี่ยน',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// [8.14 Image Placeholder]
  // Placeholder Box when there is no image yet (_buildImagePlaceholder)
  Widget _buildImagePlaceholder() {
    return GestureDetector(
      onTap: _showImagePickerSheet,
      child: Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _emasColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _emasColor.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded,
                size: 32, color: _emasColor.withOpacity(0.7)),
            const SizedBox(height: 6),
            Text(
              'แตะเพื่อเพิ่มรูปภาพ',
              style: TextStyle(
                color: _emasColor.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'ถ่ายรูปหรือเลือกจากคลัง',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  /// [8.15 Styled Dropdown]
  // Custom Dropdown Style (_buildStyledDropdown)
  Widget _buildStyledDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null
              ? _emasColor.withOpacity(0.5)
              : Colors.grey.shade200,
          width: value != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon,
                size: 18, color: _emasColor.withOpacity(0.7)),
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.grey.shade400, fontSize: 14),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 4),
          ),
          items: items
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// [8.16 Image Picker Sheet]
  // Bottom Sheet to select image source (_buildImagePickerSheet)
  Widget _buildImagePickerSheet() {
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

                // Handle Bar
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
                  'เพิ่มรูปภาพ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // 2 Options: "ถ่ายรูป" / "คลังภาพ"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSheetOption(
                          icon: Icons.camera_alt_rounded,
                          label: 'ถ่ายรูป',
                          onTap: () async {
                            Navigator.pop(context);
                            await _pickImageFrom(ImageSource.camera);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSheetOption(
                          icon: Icons.photo_library_rounded,
                          label: 'คลังภาพ',
                          onTap: () async {
                            Navigator.pop(context);
                            await _pickImageFrom(ImageSource.gallery);
                          },
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

  /// [8.17 Sheet Option]
  // Options in the bottom sheet (_buildSheetOption)
  Widget _buildSheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _emasColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _emasColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _emasColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _emasColor, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: _emasColor,
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
