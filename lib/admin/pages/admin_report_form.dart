import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../services/admin_service.dart';

import '../../shared/constants/emas_colors.dart';
import '../../shared/constants/map_constants.dart';
import '../../shared/constants/report_constants.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/form_widgets.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/image_widgets.dart';
import '../../shared/widgets/map_widgets.dart';
import '../../shared/utils/geo_utils.dart';

/// Bottom sheet: Admin. Resolves to `true` only when a report was actually
/// saved (see AdminReportForm._submit) — `null`/`false` means the admin
/// closed it without saving. Callers (e.g. AdminMainPage's global FAB) should
/// check this before treating the flow as complete. [showAdminReportForm]
Future<bool?> showAdminReportForm(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AdminReportForm(),
  );
}

/// Admin-created report form (building/floor/room, status, severity, image, description, map pin) [AdminReportForm]
class AdminReportForm extends StatefulWidget {
  const AdminReportForm({super.key});

  @override
  State<AdminReportForm> createState() => _AdminReportFormState();
}

class _AdminReportFormState extends State<AdminReportForm>
    with TickerProviderStateMixin {

  /// ============================== [Controllers & Services] ==============================
  /// Text/map controllers [_floorController, _roomController, _descController, _mapController, _adminService, _imagePicker, _buildingTextController]
  final _floorController = TextEditingController();
  final _roomController = TextEditingController();
  final _descController = TextEditingController();
  final _mapController = MapController();
  final _adminService = AdminService();
  final _imagePicker = ImagePicker();
  final _buildingTextController = TextEditingController();

  /// Staggered entrance animation [_fadeController, _fadeList, _slideList]
  late final AnimationController _fadeController;
  late final List<Animation<double>> _fadeList;
  late final List<Animation<Offset>> _slideList;

  // Map expand/collapse animation [_mapAnimController, _mapHeightAnimation]
  late final AnimationController _mapAnimController;
  late final Animation<double> _mapHeightAnimation;

  /// ============================== [State] ==============================
  /// Map State [_pickedLocation, _isPickingMode, _isMapExpanded, _mapMode]
  LatLng? _pickedLocation;
  bool _isPickingMode = false;
  bool _isMapExpanded = false;
  MapMode _mapMode = MapMode.normal;

  /// Form State [_selectedBuilding, _selectedFloor, _selectedSeverity, _selectedStatus, _selectedImage, _isSaving]
  String? _selectedBuilding;
  String? _selectedSeverity;
  String _selectedStatus = ReportStatus.pending;
  File? _selectedImage;
  bool _isSaving = false;
  bool _isManualBuildingEntry = false;

  /// Number of staggered sections: Map, Image, Location, Status, Severity, Description
  static const _sectionCount = 6;

  /// ============================== [Life Cycle] ==============================
  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeList = _buildStaggeredFadeList();
    _slideList = _buildStaggeredSlideList();
    _fadeController.forward();

    /// Map height animation: 200 → 520 [_mapAnimController]
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
    _requestLocationAndMove(); 
  }
  
  @override
  void dispose() {
    _buildingTextController.dispose();
    _floorController.dispose();
    _roomController.dispose();
    _descController.dispose();
    _mapController.dispose();
    _fadeController.dispose();
    _mapAnimController.dispose();
    super.dispose();
  }

  /// ============================== [Animation Logic] ==============================
  /// Staggered fade-in per form section [_buildStaggeredFadeList]
  List<Animation<double>> _buildStaggeredFadeList() {
    return List.generate(_sectionCount, (i) {
      final start = (i * 0.1).clamp(0.0, 0.9);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start, 1.0, curve: Curves.easeOut),
        ),
      );
    });
  }

  /// Same as above but slide-up motion [_buildStaggeredSlideList]
  List<Animation<Offset>> _buildStaggeredSlideList() {
    return List.generate(_sectionCount, (i) {
      final start = (i * 0.1).clamp(0.0, 0.9);
      return Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  /// Apply fade + slide animation to a form section [_buildAnimatedSection]
  Widget _buildAnimatedSection(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeList[index],
      child: SlideTransition(position: _slideList[index], child: child),
    );
  }

  /// ============================== [Location & Map Logic] ==============================
  /// Request GPS permission and move map to user location (if inside campus bounds) [_requestLocationAndMove]
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

      if (mapBounds.contains(userLatLng)) {
        _mapController.move(userLatLng, 16);
      }
    } catch (_) {
      // if can't find GPS then use initialCenter location
    }
  }

  /// Expand / collapse map and optionally enter picking mode [_toggleMapExpand]
  void _toggleMapExpand({bool enterPickingMode = false}) {
    HapticFeedback.lightImpact();
    setState(() {
      _isMapExpanded = !_isMapExpanded;
      if (_isMapExpanded) {
        _mapAnimController.forward();
        if (enterPickingMode) _isPickingMode = true;
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

  /// Handle map tap and set pin location [_onMapTapped]
void _onMapTapped(TapPosition tapPosition, LatLng tappedPosition) {
  if (!_isPickingMode) return;

  if (!mapBounds.contains(tappedPosition)) {
    HapticFeedback.heavyImpact();
    _showSnackBar(
      'กรุณาเลือกตำแหน่งภายใน มศว องครักษ์ เท่านั้น', Colors.red.shade700, Icons.warning_amber_rounded
    );
    return;
  }

  HapticFeedback.mediumImpact();
  setState(() => _pickedLocation = tappedPosition);
  _mapController.move(tappedPosition, 18);

  _autoDetectBuilding(tappedPosition);
}

/// Auto-fill the building field using point-in-polygon detection.
/// Works in both dropdown mode and manual-typing mode. [_autoDetectBuilding]
void _autoDetectBuilding(LatLng point) {
  final detectedName = getBuildingNameFromPoint(point);
  if (detectedName == null) return;

  setState(() {
    _selectedBuilding = detectedName;
    _buildingTextController.text = detectedName;
  });

  _showSnackBar(
    'ตรวจพบตำแหน่ง: $detectedName', Colors.green.shade600, Icons.location_city_rounded
  );
}

/// Confirm selected pin location [_confirmPin]
void _confirmPin() {
  HapticFeedback.mediumImpact();
  _toggleMapExpand();
  _showSnackBar(
    'ปักหมุดสำเร็จ', Colors.green.shade600, Icons.check_circle_outline
  );
}

/// Switch to next map mode [_cycleMapMode]
void _cycleMapMode() {
  HapticFeedback.selectionClick();
  setState(() {
    final modes = MapMode.values;
    _mapMode = modes[(modes.indexOf(_mapMode) + 1) % modes.length];
  });
}

  /// ============================== [Image Picker Logic] ==============================
  /// Show image picker bottom sheet [_showImagePickerSheet]
  void _showImagePickerSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildImagePickerSheet(),
    );
  }

  /// Pick image from selected source [_pickImageFrom]
  Future<void> _pickImageFrom(ImageSource source) async {
    final picked = await _imagePicker.pickImage(source: source);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  /// ============================== [Submit Logic] ==============================
  /// Validate + create the admin report [_submit]
  Future<void> _submit() async {
    if (_selectedBuilding == null || _floorController.text.trim().isEmpty) {
      _showSnackBar(
        'กรุณาเลือกอาคารและชั้น', Colors.red.shade600, Icons.error_outline
        );
      return;
    }
    if (_selectedSeverity == null) {
      _showSnackBar(
        'กรุณาเลือกระดับความรุนแรง', Colors.red.shade600, Icons.error_outline
        );
      return;
    }
    if (_descController.text.trim().isEmpty) {
      _showSnackBar(
        'กรุณากรอกรายละเอียดปัญหา', Colors.red.shade600, Icons.error_outline
        );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      /// NOTE: AdminService.createReport() ต้องรองรับพารามิเตอร์ `image` (File?)
      /// และอัปโหลดขึ้น Firebase Storage แบบเดียวกับ ReportService.submitReport()
      await _adminService.createReport(
        building: _selectedBuilding!,
        floor: _floorController.text.trim(),
        room: _roomController.text.trim(),
        description: _descController.text.trim(),
        severity: _selectedSeverity!,
        status: _selectedStatus,
        lat: _pickedLocation?.latitude,
        lng: _pickedLocation?.longitude,
        image: _selectedImage,
      );

      if (!mounted) return;
      /// Pop `true` — distinguishes a real save from the admin just closing
      /// the sheet, so callers like AdminMainPage's global FAB know whether
      /// to switch to the report list tab. [Navigator.pop(context, true)]
      Navigator.pop(context, true);
      _showSnackBar(
        'เพิ่มรายการแจ้งซ่อมสำเร็จ', Colors.green.shade600, Icons.check_circle
        );
    } catch (e) {
      _showSnackBar(
        'เกิดข้อผิดพลาด: $e', Colors.red.shade700, Icons.error_outline
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// ============================== [UI Helpers] ==============================
  /// Show snackbar message [_showSnack]
  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            color: const Color(0xFFF2F2F7),
            child: Column(
              children: [
                _buildHandle(),
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: _isMapExpanded
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAnimatedSection(0, _buildMapSection()),
                        const SizedBox(height: 14),
                        _buildAnimatedSection(1, _buildImageSection()),
                        const SizedBox(height: 14),
                        _buildAnimatedSection(2, _buildLocationSection()),
                        const SizedBox(height: 14),
                        _buildAnimatedSection(3, _buildStatusSection()),
                        const SizedBox(height: 14),
                        _buildAnimatedSection(4, _buildSeveritySection()),
                        const SizedBox(height: 14),
                        _buildAnimatedSection(5, _buildDescriptionSection()),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                _buildSubmitBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ============================== [Widgets] ==============================
  /// Drag handle at top of the sheet [_buildHandle]
  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// Title row with Admin badge + close button [_buildHeader]
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'เพิ่มรายการแจ้งซ่อม',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: emasColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: emasColor.withOpacity(0.4)),
            ),
            child: Text(
              'Admin',
              style: TextStyle(
                color: emasColorDarker,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Map section with pin picking, expand/collapse animation, and mode toggle [_buildMapSection]
  Widget _buildMapSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(
            icon: Icons.location_on_rounded,
            title: 'ตำแหน่งที่เกิดเหตุ',
          ),
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
                      if (_pickedLocation != null)
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
                    top: _isMapExpanded ? 50 : 10,
                    left: 10,
                    child: GlassMapButton(
                      icon: mapModeIcon(_mapMode),
                      label: mapModeLabel(_mapMode),
                      onTap: _cycleMapMode,
                    ),
                  ),

                  // Banner "แตะเพื่อปักหมุด"
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
                            Text(
                              'ยืนยันตำแหน่งนี้',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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

  /// Image upload section, shows placeholder or selected image with change button (same pattern as ReportForm) [_buildImageSection]
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

  /// Bottom sheet to choose image source: camera or gallery (same pattern as ReportForm) [_buildImagePickerSheet]
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

/// Location Section: Building / Floor dropdown + room number [_buildLocationSection]
Widget _buildLocationSection() {
  return GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CardHeader(
          icon: Icons.apartment_rounded,
          title: 'สถานที่',
        ),
        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: _buildBuildingField(),
            ),
            const SizedBox(width: 8),
            _buildBuildingModeToggle(),
          ],
        ),

        const SizedBox(height: 10),

        TextField(
          controller: _floorController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: 'ชั้น',
            labelStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.layers_rounded,
              color: emasColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: emasColor,
                width: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: _roomController,
          decoration: InputDecoration(
            labelText: 'ห้องเลขที่',
            labelStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.meeting_room_outlined,
              color: emasColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: emasColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Building input, switches between StyledDropdown and free-text TextField
/// depending on _isManualBuildingEntry [_buildBuildingField]
Widget _buildBuildingField() {
  if (_isManualBuildingEntry) {
    return TextField(
      controller: _buildingTextController,
      decoration: InputDecoration(
        labelText: 'ชื่ออาคาร',
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: const Icon(Icons.domain_rounded, color: emasColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emasColor, width: 2),
        ),
      ),
      onChanged: (value) => setState(() => _selectedBuilding = value),
    );
  }

  return StyledDropdown(
    value: _selectedBuilding,
    hint: 'เลือกอาคาร',
    icon: Icons.domain_rounded,
    items: buildingOptions,
    onChanged: (value) => setState(() => _selectedBuilding = value),
  );
}

/// Toggle button between dropdown mode and manual-typing mode.
/// Carries the current value over when switching so nothing gets lost. [_buildBuildingModeToggle]
Widget _buildBuildingModeToggle() {
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (!_isManualBuildingEntry) {
            // Switching dropdown → manual: carry over current value as starting text
            _buildingTextController.text = _selectedBuilding ?? '';
          } else {
            // Switching manual → dropdown: only keep the value if it matches a real option,
            // otherwise clear it so the dropdown doesn't crash on an unknown value
            if (!buildingOptions.contains(_selectedBuilding)) {
              _selectedBuilding = null;
            }
          }
          _isManualBuildingEntry = !_isManualBuildingEntry;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: emasColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: emasColor.withOpacity(0.3)),
        ),
        child: Icon(
          _isManualBuildingEntry ? Icons.list_rounded : Icons.edit_rounded,
          color: emasColorDarker,
          size: 20,
        ),
      ),
    ),
  );
}

  /// [ADMIN] Report status picker: "รอดำเนินการ" / "กำลังดำเนินการ" [_buildStatusSection]
  Widget _buildStatusSection() {
    final options = [
      (
        value: ReportStatus.pending,
        label: 'รอดำเนินการ',
        icon: Icons.hourglass_empty_rounded,
        color: Colors.orange,
      ),
      (
        value: ReportStatus.inProgress,
        label: 'กำลังดำเนินการ',
        icon: Icons.construction_rounded,
        color: Colors.blue,
      ),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CardHeader + Admin Badge (In the same row)
          Row(
            children: [
              const CardHeader(icon: Icons.flag_rounded, title: 'สถานะเริ่มต้น'),
              const Spacer(),
              _buildAdminBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final opt in options) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedStatus = opt.value);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedStatus == opt.value
                            ? opt.color.withOpacity(0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedStatus == opt.value
                              ? opt.color
                              : Colors.grey.shade200,
                          width: _selectedStatus == opt.value ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            opt.icon,
                            size: 20,
                            color: _selectedStatus == opt.value
                                ? opt.color
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _selectedStatus == opt.value
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _selectedStatus == opt.value
                                  ? opt.color
                                  : Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (opt != options.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// [ADMIN] Severity picker: uses severityLevels from report_constants.dart [_buildSeveritySection]
  Widget _buildSeveritySection() {
    final options = severityLevels.entries
        .where((e) => e.key != 'none')
        .toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CardHeader(
                icon: Icons.priority_high_rounded,
                title: 'ระดับความรุนแรง',
              ),
              const Spacer(),
              _buildAdminBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _buildSeverityOption(options[i].key, options[i].value),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Single severity chip used inside _buildSeveritySection [_buildSeverityOption]
  Widget _buildSeverityOption(String key, SeverityInfo info) {
    final isSelected = _selectedSeverity == key;
    final isHigh = key == 'high';
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedSeverity = key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? info.color.withOpacity(0.12) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? info.color : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            isHigh
                ? Text(
                    '!',
                    style: TextStyle(
                      color: info.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  )
                : Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: info.color, shape: BoxShape.circle),
                  ),
            const SizedBox(height: 6),
            Text(
              info.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? info.color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Problem description section (free text) [_buildDescriptionSection]
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
                borderSide: BorderSide(color: Colors.grey.shade200),
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

  /// Submit button bar pinned at bottom, shows loading spinner while saving [_buildSubmitBar]
  Widget _buildSubmitBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
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
        onTap: _isSaving ? () {} : _submit,
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'บันทึกรายการแจ้งซ่อม',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  /// Small "Admin" pill shown on admin-only sections [_buildAdminBadge]
  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: emasColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: emasColor.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 10, color: emasColorDarker),
          const SizedBox(width: 3),
          Text(
            'Admin',
            style: TextStyle(
              color: emasColorDarker,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
