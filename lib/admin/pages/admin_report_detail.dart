import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../../shared/constants/emas_colors.dart';

// Report detail + status/note editor for admins [AdminReportDetailPage]
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
  bool _isSaving = false;

  // Status options for the ChoiceChip row [_statusOptions]
  static const _statusOptions = [
    'รอดำเนินการ',
    'กำลังดำเนินการ',
    'เสร็จสิ้น',
  ];

  /// ============================== [Life Cycle] ==============================
  @override
  void initState() {
    super.initState();
    _currentStatus = widget.data['status'] ?? 'รอดำเนินการ';
    _noteCtrl.text = widget.data['adminNote'] ?? '';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  /// ============================== [Report Actions Logic] ==============================
  // Save status + admin note [_saveStatus]
  Future<void> _saveStatus() async {
    setState(() => _isSaving = true);

    try {
      await _adminService.updateReportStatus(
        reportId: widget.reportId,
        status: _currentStatus,
        note: _noteCtrl.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ อัพเดทสถานะสำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Confirm + delete this report [_deleteReport]
  Future<void> _deleteReport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('ต้องการลบรายการนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบแล้ว'), backgroundColor: Colors.orange),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่ได้: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// ============================== [UI Helpers] ==============================
  // Color per status, used for ChoiceChip styling [_statusColor]
  Color _statusColor(String s) {
    switch (s) {
      case 'รอดำเนินการ': return Colors.orange;
      case 'กำลังดำเนินการ': return Colors.blue;
      case 'เสร็จสิ้น': return Colors.green;
      default: return Colors.grey;
    }
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียด'),
        backgroundColor: emasColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ข้อมูลรายงาน
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ข้อมูลรายงาน',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    _info('อาคาร', data['building'] ?? '-'),
                    _info('ชั้น', data['floor'] ?? '-'),
                    _info('รายละเอียด', data['description'] ?? '-'),
                    _info('ตำแหน่ง',
                        data['lat'] != null
                            ? '${data['lat']}, ${data['lng']}'
                            : 'ไม่ได้ระบุ'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // อัพเดทสถานะ
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('อัพเดทสถานะ',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _statusOptions.map((status) {
                        final sel = _currentStatus == status;
                        final c = _statusColor(status);
                        return ChoiceChip(
                          label: Text(status),
                          selected: sel,
                          selectedColor: c.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: sel ? c : Colors.grey,
                            fontWeight:
                                sel ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(
                              color: sel ? c : Colors.grey),
                          onSelected: (_) =>
                              setState(() => _currentStatus = status),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // บันทึก Admin
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('บันทึกของ Admin',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'เช่น ส่งช่างไปแล้ว...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ปุ่มบันทึก
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: emasColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึก',
                    style: const TextStyle(fontSize: 16)),
                onPressed: _isSaving ? null : _saveStatus,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ============================== [Widgets] ==============================
  // "label: value" row for the report info card [_info]
  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
