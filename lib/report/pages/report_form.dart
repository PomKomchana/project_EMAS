import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../pages/main_page.dart';
import '../services/report_service.dart';

import '../../shared/constants/emas_colors.dart';
import '../../shared/constants/map_constants.dart';
import '../../shared/constants/report_constants.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/form_widgets.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/image_widgets.dart';
import '../../shared/widgets/map_widgets.dart';

// Report form page [ReportForm]
class ReportForm extends StatefulWidget {
  const ReportForm({super.key});

  @override
  State<ReportForm> createState() => _ReportFormState();
}

// State class of ReportForm (Handles UI state, animation, map, image picker, and Firestore submit)
class _ReportFormState extends State<ReportForm> with TickerProviderStateMixin {

  /// ============================== [Controllers & Services] ==============================
  // Service [_reportService]
  final _reportService = ReportService();

  // Text Controllers [_dateController, _usernameController, _phoneController, _roomController, _descController]
  final _dateController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roomController = TextEditingController();
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

  /// ============================== [State] ==============================
  // Map State [_isMapExpanded, _isPickingMode, _mapMode, _pickedLocation]
  bool _isMapExpanded = false;        // whether the map is currently expanded
  bool _isPickingMode = false;        // whether the user is in pin selection mode (waiting for map tap)
  MapMode _mapMode = MapMode.normal;  // current map display mode
  LatLng? _pickedLocation;            // selected pinned location on the map

  // Form State [_selectedBuilding, _selectedFloor, _selectedImage, _isSubmitting]
  String? _selectedBuilding;
  String? _selectedFloor;
  File? _selectedImage;
  bool _isSubmitting = false;

  /// ============================== [Life Cycle] ==============================
  // InitState (Initialize state and prepare data before UI renders) [_setupAnimations, _sectionFadeController, _requestLocationAndMove]
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _sectionFadeController.forward(); // start animation
    _requestLocationAndMove();        // request GPS and move the camera
  }

  // Dispose (Return resource when you leave this page)
  @override
  void dispose() {
    _mapAnimController.dispose();
    _sectionFadeController.dispose();

    _dateController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _roomController.dispose();
    _descController.dispose();

    _mapController.dispose();
    super.dispose();
  }

  /// ============================== [Animation Logic] ==============================
  // Setup Animations [_setupAnimations]
  void _setupAnimations() {
    // Map height grows from 200 to 520 when expanded.
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

  /// ============================== [Location & Map Logic] ==============================
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

      // GPS can move only in mapBounds area
      if (mapBounds.contains(userLatLng)) {
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
            bounds: mapBounds,
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
    if (!mapBounds.contains(tappedPosition)) {
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
    _showSnackBar('ปักหมุดสำเร็จ ✓', Colors.green.shade600, Icons.check_circle_outline);
  }

  // Switch to next map mode [_cycleMapMode]
  void _cycleMapMode() {
    HapticFeedback.selectionClick();
    setState(() {
      final modes = MapMode.values; // [normal, hybrid]
      final nextIndex = (modes.indexOf(_mapMode) + 1) % modes.length;
      _mapMode = modes[nextIndex];
    });
  }

  /// ============================== [Image Picker Logic] ==============================
  // Show image picker bottom sheet [_showImagePickerSheet]
  void _showImagePickerSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildImagePickerSheet(),
    );
  }

  // Pick image from selected source [_pickImageFrom]
  Future<void> _pickImageFrom(ImageSource source) async {
    final picked = await _imagePicker.pickImage(source: source);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  /// ============================== [Submit Logic] ==============================
  // Submit report via ReportService [_submitReport]
  Future<void> _submitReport() async {
    if (_selectedBuilding == null || _selectedFloor == null) {
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

      await _reportService.submitReport(
        location: _pickedLocation,
        image: _selectedImage,
        date: _dateController.text,
        username: _usernameController.text,
        phone: _phoneController.text,
        building: _selectedBuilding!,
        floor: _selectedFloor!,
        room: _roomController.text,
        description: _descController.text,
      );

      if (!mounted) return;

      _showSnackBar('ส่งแจ้งปัญหาเรียบร้อยแล้ว', Colors.green, Icons.check_circle);

      // Submit to ReportListPage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainPage(initialIndex: 1), // ไป tab รายการ
        ),
        (route) => false,
      );
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e', Colors.red, Icons.error);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// ============================== [UI Helpers] ==============================
  // Show snackbar message [_showSnackBar]
  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),

      // AppBar
      appBar: _buildAppBar(),

      // Submit Bar at bottom
      bottomNavigationBar: _withSectionAnimation(4, _buildSubmitBar()),

      // Main
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

            _withSectionAnimation(1, _buildImageSection()),
            const SizedBox(height: 14),

            _withSectionAnimation(2, _buildReporterSection()),
            const SizedBox(height: 14),

            _withSectionAnimation(3, _buildLocationSection()),
            const SizedBox(height: 14),

            _withSectionAnimation(4, _buildDescriptionSection()),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// ============================== [Widgets] ==============================
  // App Bar with back button and title [_buildAppBar]
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [emasColor, emasColorDarker],
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

  // Submit Button Bar pinned at bottom, shows loading spinner while submitting [_buildSubmitBar]
  Widget _buildSubmitBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
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
      child: GradientButton(
        onTap: _isSubmitting ? () {} : _submitReport,
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'ส่งแจ้งปัญหา',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          );
        }

  // Map Section with pin picking, Expand / Collapse animation, and mode toggle [_buildMapSection]
  Widget _buildMapSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const CardHeader(icon: Icons.location_on_rounded, title: 'ตำแหน่งที่เกิดเหตุ'),
          const SizedBox(height: 12),

          // Map height changes with animation.
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
                      initialCenter: mapLocation,
                      initialZoom: 15,
                      minZoom: 14,
                      maxZoom: 20,
                      cameraConstraint: CameraConstraint.containCenter(bounds: mapBounds),
                      onTap: _onMapTapped,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: mapModeTileUrl(_mapMode),
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
                                color: emasColor,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Map Mode Button
                  Positioned(
                    top: _isMapExpanded ? 50 : 10, // Move down when expanded so it clears the app bar area.
                    left: 10,
                    child: GlassMapButton(
                      icon: mapModeIcon(_mapMode),
                      label: mapModeLabel(_mapMode),
                      onTap: _cycleMapMode,
                    ),
                  ),

                  // Banner (แตะเพื่อปักหมุดจุดเกิดเหตุ)
                  if (_isPickingMode)
                    const Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(child: PickingBanner()),
                    ),

                  // Confirm Picking Location
                  if (_isPickingMode && _pickedLocation != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: GradientButton(
                        onTap: _confirmPin,
                        color1: Colors.green.shade500,
                        color2: Colors.green.shade700,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('ยืนยันตำแหน่งนี้', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                  // Close Map
                  if (_isMapExpanded && !_isPickingMode)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: CloseMapButton(onTap: _toggleMapExpand),
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
                  child: OutlineButton(
                    icon: Icons.my_location_rounded,
                    label: _pickedLocation == null ? 'เลือกตำแหน่ง' : 'เปลี่ยนตำแหน่ง',
                    onTap: () => _toggleMapExpand(enterPickingMode: true),
                  ),
                ),
                if (_pickedLocation != null) ...[
                  const SizedBox(width: 10),
                  const PinBadge(),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // Image Upload Section, shows placeholder or selected image with change button [_buildImageSection]
  Widget _buildImageSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(icon: Icons.camera_alt_rounded, title: 'รูปภาพ'),
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
                  child: ChangeImageButton(onTap: _showImagePickerSheet),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // But if an image not present → show Placeholder box
          if (_selectedImage == null) ImagePlaceholder(onTap: _showImagePickerSheet),
        ],
      ),
    );
  }

  // Bottom Sheet to choose image source: camera or gallery [_buildImagePickerSheet]
  Widget _buildImagePickerSheet() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),

                // 2 Options: "ถ่ายรูป" / "คลังภาพ"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SheetOption(
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
                        child: SheetOption(
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

  // Reporter Info Section: date picker, username, phone [_buildReporterSection]
  Widget _buildReporterSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(icon: Icons.person_outline, title: 'ข้อมูลผู้แจ้ง'),
          const SizedBox(height: 12),

          // Date Report "วันที่แจ้งซ่อม"
          TextField(
            controller: _dateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'วันที่แจ้งซ่อม',
              labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.calendar_today, color: emasColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: emasColor, width: 2),
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
              prefixIcon: const Icon(Icons.person, color: emasColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: emasColor, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // User Phone Number "เบอร์ติดต่อ"
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'เบอร์ติดต่อ',
              labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.phone, color: emasColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: emasColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Location Section: Building / Floor dropdown + room number [_buildLocationSection]
  Widget _buildLocationSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(icon: Icons.apartment_rounded, title: 'สถานที่'),
          const SizedBox(height: 12),
          StyledDropdown(
            value: _selectedBuilding,
            hint: 'เลือกอาคาร',
            icon: Icons.domain_rounded,
            items: buildingOptions,
            onChanged: (value) => setState(() => _selectedBuilding = value),
          ),
          const SizedBox(height: 10),
          StyledDropdown(
            value: _selectedFloor,
            hint: 'เลือกชั้น',
            icon: Icons.layers_rounded,
            items: floorOptions,
            onChanged: (value) => setState(() => _selectedFloor = value),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _roomController,
            decoration: InputDecoration(
              labelText: 'ห้องเลขที่',
              labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.meeting_room_outlined, color: emasColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: emasColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Problem Description Section (free text) [_buildDescriptionSection]
  Widget _buildDescriptionSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(icon: Icons.edit_note_rounded, title: 'รายละเอียดปัญหา'),
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
                borderSide: const BorderSide(color: emasColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
