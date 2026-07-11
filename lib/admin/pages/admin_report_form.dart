import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/admin_service.dart';
import '../../shared/constants/emas_colors.dart';
import '../../shared/constants/map_constants.dart';
import '../../shared/constants/report_constants.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/form_widgets.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/image_widgets.dart';
import '../../shared/widgets/map_widgets.dart';

// Bottom sheet: Admin [showAdminReportForm]
Future<void> showAdminReportForm(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AdminReportForm(),
  );
}

// Admin-created report form (building/floor/room, status, severity, description, map pin) [AdminReportForm]
class AdminReportForm extends StatefulWidget {
  const AdminReportForm({super.key});

  @override
  State<AdminReportForm> createState() => _AdminReportFormState();
}

class _AdminReportFormState extends State<AdminReportForm>
    with TickerProviderStateMixin {

  /// ============================== [Controllers & Services] ==============================
  // Text/map controllers [_roomController, _descController, _mapController]
  final _roomController = TextEditingController();
  final _descController = TextEditingController();
  final _mapController = MapController();
  final _adminService = AdminService();

  // Staggered entrance animation [_fadeController, _fadeList, _slideList]
  late final AnimationController _fadeController;
  late final List<Animation<double>> _fadeList;
  late final List<Animation<Offset>> _slideList;

  // Map expand/collapse animation [_mapAnimController, _mapHeightAnimation]
  late final AnimationController _mapAnimController;
  late final Animation<double> _mapHeightAnimation;

  /// ============================== [State] ==============================
  // Map State [_pickedLocation, _isPickingMode, _isMapExpanded, _mapMode]
  LatLng? _pickedLocation;
  bool _isPickingMode = false;
  bool _isMapExpanded = false;
  MapMode _mapMode = MapMode.normal;

  // Form State [_selectedBuilding, _selectedFloor, _selectedSeverity, _selectedStatus, _isSaving]
  String? _selectedBuilding;
  String? _selectedFloor;
  String? _selectedSeverity;
  String _selectedStatus = ReportStatus.pending;
  bool _isSaving = false;

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

    // Map height animation: 200 → 520 [_mapAnimController]
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
  }

  @override
  void dispose() {
    _roomController.dispose();
    _descController.dispose();
    _mapController.dispose();
    _fadeController.dispose();
    _mapAnimController.dispose();
    super.dispose();
  }

  /// ============================== [Animation Logic] ==============================
  // Staggered fade-in per form section [_buildStaggeredFadeList]
  List<Animation<double>> _buildStaggeredFadeList() {
    return List.generate(5, (i) {
      final start = (i * 0.1).clamp(0.0, 0.9);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start, 1.0, curve: Curves.easeOut),
        ),
      );
    });
  }

  // Same as above but slide-up motion [_buildStaggeredSlideList]
  List<Animation<Offset>> _buildStaggeredSlideList() {
    return List.generate(5, (i) {
      final start = (i * 0.1).clamp(0.0, 0.9);
      return Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  // Apply fade + slide animation to a form section [_buildAnimatedSection]
  Widget _buildAnimatedSection(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeList[index],
      child: SlideTransition(position: _slideList[index], child: child),
    );
  }

  /// ============================== [Location & Map Logic] ==============================
  // Expand / collapse map and optionally enter picking mode [_toggleMapExpand]
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

  // Handle map tap and set pin location [_onMapTapped]
  void _onMapTapped(TapPosition tapPosition, LatLng tappedPosition) {
    if (!_isPickingMode) return;

    if (!mapBounds.contains(tappedPosition)) {
      HapticFeedback.heavyImpact();
      _showSnack('กรุณาเลือกตำแหน่งภายใน มศว องครักษ์ เท่านั้น', Colors.orange.shade700);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _pickedLocation = tappedPosition);
    _mapController.move(tappedPosition, 18);
  }

  // Confirm selected pin location [_confirmPin]
  void _confirmPin() {
    HapticFeedback.mediumImpact();
    _toggleMapExpand();
    _showSnack('ปักหมุดสำเร็จ ✓', Colors.green.shade600);
  }

  // Switch to next map mode [_cycleMapMode]
  void _cycleMapMode() {
    HapticFeedback.selectionClick();
    setState(() {
      final modes = MapMode.values;
      _mapMode = modes[(modes.indexOf(_mapMode) + 1) % modes.length];
    });
  }

  /// ============================== [Submit Logic] ==============================
  // Validate + create the admin report [_submit]
  Future<void> _submit() async {
    if (_selectedBuilding == null || _selectedFloor == null) {
      _showSnack('กรุณาเลือกอาคารและชั้น', Colors.red.shade600);
      return;
    }
    if (_selectedSeverity == null) {
      _showSnack('กรุณาเลือกระดับความรุนแรง', Colors.red.shade600);
      return;
    }
    if (_descController.text.trim().isEmpty) {
      _showSnack('กรุณากรอกรายละเอียดปัญหา', Colors.red.shade600);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      await _adminService.createReport(
        building: _selectedBuilding!,
        floor: _selectedFloor!,
        room: _roomController.text.trim(),
        description: _descController.text.trim(),
        severity: _selectedSeverity!,
        status: _selectedStatus,
        lat: _pickedLocation?.latitude,
        lng: _pickedLocation?.longitude,
      );

      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('เพิ่มรายการแจ้งซ่อมสำเร็จ ✓', Colors.green.shade600);
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาด: $e', Colors.red.shade600);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// ============================== [UI Helpers] ==============================
  // Show snackbar message [_showSnack]
  void _showSnack(String message, Color color) {
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
                        _buildAnimatedSection(1, _buildLocationSection()),
                        const SizedBox(height: 14),
                        _buildAnimatedSection(2, _buildStatusSection()),
                        const SizedBox(height: 14),
                        _buildAnimatedSection(3, _buildSeveritySection()),
                        const SizedBox(height: 14),
                        _buildAnimatedSection(4, _buildDescriptionSection()),
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
  // Drag handle at top of the sheet [_buildHandle]
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

  // Title row with Admin badge + close button [_buildHeader]
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

  // Map section with pin picking, expand/collapse animation, and mode toggle [_buildMapSection]
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

  // Location section: building/floor dropdown + room number [_buildLocationSection]
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
            onChanged: (v) => setState(() => _selectedBuilding = v),
          ),
          const SizedBox(height: 10),
          StyledDropdown(
            value: _selectedFloor,
            hint: 'เลือกชั้น',
            icon: Icons.layers_rounded,
            items: floorOptions,
            onChanged: (v) => setState(() => _selectedFloor = v),
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

  // [ADMIN] Report status picker: "รอดำเนินการ" / "กำลังดำเนินการ" [_buildStatusSection]
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

  // [ADMIN] Severity picker: uses severityLevels from report_constants.dart [_buildSeveritySection]
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

  // Problem description section (free text) [_buildDescriptionSection]
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

  // Submit button bar pinned at bottom, shows loading spinner while saving [_buildSubmitBar]
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

  // Small "Admin" pill shown on admin-only sections [_buildAdminBadge]
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
