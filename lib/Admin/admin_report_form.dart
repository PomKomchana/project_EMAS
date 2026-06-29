import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/reportForm/report_form_constants.dart'
    hide emasColor, emasColorDarker;
import '../screens/reportList/report_list_constants.dart'
    hide emasColor, emasColorDarker;

const emasColor = Color(0xFFe85d6a);
const emasColorDarker = Color(0xFFc4394a);

// ==== Bottom sheet: admin สร้างรายการแจ้งซ่อมเอง [showAdminReportForm] ====
// เรียกจาก FAB ใน admin_report_list.dart
Future<void> showAdminReportForm(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AdminReportForm(),
  );
}

class AdminReportForm extends StatefulWidget {
  const AdminReportForm({super.key});

  @override
  State<AdminReportForm> createState() =>
      _AdminReportFormState();
}

class _AdminReportFormState extends State<AdminReportForm>
    with TickerProviderStateMixin {
  // Controllers [_roomController, _descController]
  final _roomController = TextEditingController();
  final _descController = TextEditingController();
  final _mapController = MapController();

  // Map picking state [_pickedLocation, _isPickingMode, _mapMode]
  LatLng? _pickedLocation;
  bool _isPickingMode = false;
  MapMode _mapMode = MapMode.normal;

  // Form state [_selectedBuilding, _selectedFloor, _selectedSeverity, _isSaving]
  String? _selectedBuilding;
  String? _selectedFloor;
  String? _selectedSeverity;
  bool _isSaving = false;

  // Staggered fade-in สำหรับ section ต่างๆ ในชีต ให้ feel เหมือน report_list
  late final AnimationController _fadeController;
  late final List<Animation<double>> _fadeList;
  late final List<Animation<Offset>> _slideList;

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
  }

  @override
  void dispose() {
    _roomController.dispose();
    _descController.dispose();
    _mapController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  List<Animation<double>> _buildStaggeredFadeList() {
    return List.generate(4, (i) {
      final start = (i * 0.12).clamp(0.0, 0.9);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start, 1.0, curve: Curves.easeOut),
        ),
      );
    });
  }

  List<Animation<Offset>> _buildStaggeredSlideList() {
    return List.generate(4, (i) {
      final start = (i * 0.12).clamp(0.0, 0.9);
      return Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  // ==== Handle map tap → ปักหมุด (เช็ค bounds เหมือน report_form) [_onMapTapped] ====
  void _onMapTapped(TapPosition tapPosition, LatLng tappedPosition) {
    if (!_isPickingMode) return;

    if (!mapBounds.contains(tappedPosition)) {
      HapticFeedback.heavyImpact();
      _showSnack(
        'กรุณาเลือกตำแหน่งภายใน มศว องครักษ์ เท่านั้น',
        Colors.orange.shade700,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _pickedLocation = tappedPosition);
    _mapController.move(tappedPosition, 18);
  }

  // ==== สลับโหมดแผนที่ ปกติ/ไฮบริด [_cycleMapMode] ====
  void _cycleMapMode() {
    HapticFeedback.selectionClick();
    setState(() {
      final modes = MapMode.values;
      final nextIndex = (modes.indexOf(_mapMode) + 1) % modes.length;
      _mapMode = modes[nextIndex];
    });
  }

  // ==== บันทึกรายการแจ้งซ่อมลง Firestore [_submit] ====
  Future<void> _submit() async {
    if (_selectedBuilding == null || _selectedFloor == null) {
      _showSnack('กรุณาเลือกอาคารและชั้น', Colors.red.shade600);
      return;
    }

    if (_selectedSeverity == null) {
      _showSnack('กรุณาเลือกระดับความเร่งด่วน', Colors.red.shade600);
      return;
    }

    if (_descController.text.trim().isEmpty) {
      _showSnack('กรุณากรอกรายละเอียดปัญหา', Colors.red.shade600);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'building': _selectedBuilding,
        'floor': _selectedFloor,
        'room': _roomController.text.trim(),
        'description': _descController.text.trim(),
        'severity': _selectedSeverity,
        'status': ReportStatus.pending,
        'lat': _pickedLocation?.latitude,
        'lng': _pickedLocation?.longitude,
        'username': 'Admin', // [createdBy=admin] ระบุชื่อผู้แจ้งเป็น Admin ตรงๆ
        'createdBy': 'admin', // เพื่อแยกว่า admin สร้างเอง ไม่ใช่ user แจ้ง
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('เพิ่มรายการแจ้งซ่อมสำเร็จ ✓', Colors.green.shade600);
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาด: $e', Colors.red.shade600);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    // เปิดเกือบเต็มจอ แต่ยัง dismiss แบบ sheet ได้ [DraggableScrollableSheet]
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
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAnimatedSection(0, _buildMapSection()),
                        const SizedBox(height: 14),
                        _buildAnimatedSection(1, _buildLocationSection()),
                        const SizedBox(height: 14),
                        _buildAnimatedSection(2, _buildSeveritySection()),
                        const SizedBox(height: 14),
                        _buildAnimatedSection(3, _buildDescriptionSection()),
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

  // ==== ครอบแต่ละ section ด้วย fade + slide-up ตอนเปิดชีต [_buildAnimatedSection] ====
  Widget _buildAnimatedSection(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeList[index],
      child: SlideTransition(position: _slideList[index], child: child),
    );
  }

  // ==== Drag handle ด้านบน sheet ====
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
          // Badge เล็กๆ บอกว่านี่คือรายการที่ admin สร้างเอง
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

  // ==== แผนที่เลือกตำแหน่ง (ใช้ขนาดคงที่ เพราะอยู่ใน sheet ที่ scroll ได้แล้ว) [_buildMapSection] ====
  Widget _buildMapSection() {
    return _buildGlassCard(
      icon: Icons.location_on_rounded,
      title: 'ตำแหน่งที่เกิดเหตุ (ไม่บังคับ)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 260,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: mapLocation,
                      initialZoom: 15,
                      minZoom: 14,
                      maxZoom: 20,
                      cameraConstraint:
                          CameraConstraint.containCenter(bounds: mapBounds),
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

                  // ปุ่มสลับโหมดแผนที่
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _MapModeChip(
                      icon: mapModeIcon(_mapMode),
                      label: mapModeLabel(_mapMode),
                      onTap: _cycleMapMode,
                    ),
                  ),

                  // แบนเนอร์บอกให้แตะปักหมุด
                  if (_isPickingMode)
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'แตะบนแผนที่เพื่อปักหมุด',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ปุ่มเข้า/ออก โหมดปักหมุด
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: emasColor,
                    side: const BorderSide(color: emasColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isPickingMode = !_isPickingMode);
                  },
                  icon: Icon(
                    _isPickingMode
                        ? Icons.check_rounded
                        : Icons.my_location_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _isPickingMode
                        ? 'เสร็จสิ้นการปักหมุด'
                        : (_pickedLocation == null
                            ? 'เลือกตำแหน่ง'
                            : 'เปลี่ยนตำแหน่ง'),
                  ),
                ),
              ),
              if (_pickedLocation != null && !_isPickingMode) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return _buildGlassCard(
      icon: Icons.apartment_rounded,
      title: 'สถานที่',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdown(
            value: _selectedBuilding,
            hint: 'เลือกอาคาร',
            icon: Icons.domain_rounded,
            items: buildingOptions,
            onChanged: (v) => setState(() => _selectedBuilding = v),
          ),
          const SizedBox(height: 10),
          _buildDropdown(
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
              labelText: 'ห้องเลขที่ (ไม่บังคับ)',
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

  // ==== เลือกระดับความเร่งด่วน (severity) — ของใหม่ ไม่มีในเวอร์ชันเดิม [_buildSeveritySection] ====
  Widget _buildSeveritySection() {
    // ตัด 'none' ออก เพราะ admin ต้องเลือกระดับจริงเสมอ ไม่ปล่อยว่าง
    final options = severityLevels.entries
        .where((entry) => entry.key != 'none')
        .toList();

    return _buildGlassCard(
      icon: Icons.priority_high_rounded,
      title: 'ระดับความเร่งด่วน',
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _buildSeverityOption(
                options[i].key,
                options[i].value,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==== ปุ่มเลือก severity แบบ chip กดเลือกได้ [_buildSeverityOption] ====
  Widget _buildSeverityOption(String key, SeverityInfo info) {
    final isSelected = _selectedSeverity == key;

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
            Container(
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

  Widget _buildDescriptionSection() {
    return _buildGlassCard(
      icon: Icons.edit_note_rounded,
      title: 'รายละเอียดปัญหา',
      child: TextField(
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
    );
  }

  // ==== ปุ่มบันทึกด้านล่าง sheet ====
  Widget _buildSubmitBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
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
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: emasColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isSaving ? null : _submit,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(
            _isSaving ? 'กำลังบันทึก...' : 'บันทึกรายการแจ้งซ่อม',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ==== Glass card wrapper — สไตล์เดียวกับการ์ดใน report_list_page.dart [_buildGlassCard] ====
  Widget _buildGlassCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: emasColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }

  // ==== Dropdown ใช้ร่วมกัน building/floor [_buildDropdown] ====
  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: emasColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emasColor, width: 2),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ==== ปุ่มเล็กสลับโหมดแผนที่ (เวอร์ชันย่อ ไม่ใช้ glass effect เหมือน report_form) [_MapModeChip] ====
class _MapModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MapModeChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: emasColorDarker),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: emasColorDarker,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
