import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/admin_service.dart';
import '../../shared/constants/emas_colors.dart';
import '../../shared/constants/report_constants.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/buttons.dart';

// Report detail + status/severity/note editor for admins [AdminReportDetailPage]
class AdminReportDetailPage extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> data;

  const AdminReportDetailPage({
    super.key,
    required this.reportId,
    required this.data,
  });

  @override
  State<AdminReportDetailPage> createState() => _AdminReportDetailPageState();
}

class _AdminReportDetailPageState extends State<AdminReportDetailPage> {

  /// ============================== [Controllers & Services] ==============================
  final _noteCtrl = TextEditingController();
  final _adminService = AdminService();

  /// ============================== [State] ==============================
  late String _currentStatus;
  late String? _currentSeverity;
  bool _isSaving = false;

  // Status options with icon + color, used for the segmented picker [_statusOptions]
  static const _statusOptions = [
    (label: 'รอดำเนินการ', icon: Icons.hourglass_empty_rounded, color: Colors.orange),
    (label: 'กำลังดำเนินการ', icon: Icons.construction_rounded, color: Colors.blue),
    (label: 'เสร็จสิ้น', icon: Icons.check_circle_rounded, color: Colors.green),
  ];

  /// ============================== [Life Cycle] ==============================
  @override
  void initState() {
    super.initState();
    _currentStatus = widget.data['status'] ?? 'รอดำเนินการ';
    _currentSeverity = widget.data['severity'];
    _noteCtrl.text = widget.data['adminNote'] ?? '';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  /// ============================== [Report Actions Logic] ==============================
  // Save status + severity + admin note [_saveStatus]
  Future<void> _saveStatus() async {
    if (_currentSeverity == null) {
      _showSnack('กรุณาเลือกระดับความรุนแรง', Colors.red.shade600);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // TODO: เพิ่มพารามิเตอร์ severity ใน AdminService.updateReportStatus()
      // ให้เขียนลง field 'severity' ใน Firestore ด้วย
      await _adminService.updateReportStatus(
        reportId: widget.reportId,
        status: _currentStatus,
        severity: _currentSeverity!,
        note: _noteCtrl.text.trim(),
      );

      if (!mounted) return;
      _showSnack('อัพเดทสำเร็จ ✓', Colors.green.shade600);
      Navigator.pop(context);
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาด: $e', Colors.red.shade600);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Confirm + delete this report [_deleteReport]
  Future<void> _deleteReport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
        ),
        title: const Text('ยืนยันการลบ'),
        content: const Text('ต้องการลบรายการนี้หรือไม่? การกระทำนี้ไม่สามารถย้อนกลับได้'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminService.deleteReport(widget.reportId);

      if (!mounted) return;
      _showSnack('ลบแล้ว', Colors.red.shade700);
      Navigator.pop(context);
    } catch (e) {
      _showSnack('ลบไม่ได้: $e', Colors.red.shade600);
    }
  }

  /// ============================== [UI Helpers] ==============================
  // Show themed snackbar [_showSnack]
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
    final data = widget.data;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            backgroundColor: emasColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text('รายละเอียดการแจ้งซ่อม',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [emasColor, emasColorDarker],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _deleteReport,
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ข้อมูลรายงาน
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CardHeader(icon: Icons.description_rounded, title: 'ข้อมูลรายงาน'),
                      const SizedBox(height: 12),
                      _info(Icons.apartment_rounded, 'อาคาร', '${data['building'] ?? '-'}'),
                      _info(Icons.layers_rounded, 'ชั้น', '${data['floor'] ?? '-'}'),
                      _info(Icons.edit_note_rounded, 'รายละเอียด', '${data['description'] ?? '-'}'),
                      _info(
                        Icons.location_on_rounded,
                        'ตำแหน่ง',
                        data['lat'] != null
                            ? '${data['lat']}, ${data['lng']}'
                            : 'ไม่ได้ระบุ',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // อัพเดทสถานะ
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CardHeader(icon: Icons.flag_rounded, title: 'อัพเดทสถานะ'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final opt in _statusOptions) ...[
                            Expanded(child: _buildStatusChip(opt)),
                            if (opt != _statusOptions.last) const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ระดับความรุนแรง (ใหม่)
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CardHeader(icon: Icons.priority_high_rounded, title: 'ระดับความรุนแรง'),
                      const SizedBox(height: 12),
                      _buildSeverityRow(),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // บันทึกของ Admin
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CardHeader(icon: Icons.sticky_note_2_rounded, title: 'บันทึกของ Admin'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteCtrl,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                        decoration: InputDecoration(
                          hintText: 'เช่น ส่งช่างไปแล้ว...',
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
                ),
                const SizedBox(height: 24),

                GradientButton(
                  onTap: _isSaving ? () {} : _saveStatus,
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
                            Text('บันทึก', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// ============================== [Widgets] ==============================
  // Icon + label + value row for the report info card [_info]
  Widget _info(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: emasColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 78,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // Single segmented status chip [_buildStatusChip]
  Widget _buildStatusChip(({String label, IconData icon, Color color}) opt) {
    final isSelected = _currentStatus == opt.label;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentStatus = opt.label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? opt.color.withValues(alpha: 0.12) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? opt.color : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(opt.icon, size: 18, color: isSelected ? opt.color : Colors.grey.shade400),
            const SizedBox(height: 6),
            Text(
              opt.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? opt.color : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Severity row: reuses severityLevels from report_constants.dart [_buildSeverityRow]
  Widget _buildSeverityRow() {
    final options = severityLevels.entries.where((e) => e.key != 'none').toList();

    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _buildSeverityChip(options[i].key, options[i].value)),
        ],
      ],
    );
  }

  // Single severity chip, same pattern as AdminReportForm [_buildSeverityChip]
  Widget _buildSeverityChip(String key, SeverityInfo info) {
    final isSelected = _currentSeverity == key;
    final isHigh = key == 'high';
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentSeverity = key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? info.color.withValues(alpha: 0.12) : Colors.grey.shade50,
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
}
