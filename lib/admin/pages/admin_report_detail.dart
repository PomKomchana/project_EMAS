import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'admin_delete_confirm_dialog.dart' show showDeleteConfirmDialog;
import '../services/admin_service.dart';

import '../../shared/constants/emas_colors.dart';
import '../../shared/constants/report_constants.dart';
import '../../shared/utils/thai_date.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/buttons.dart';

/// Report detail page — admin can edit status, severity, note, and photo [AdminReportDetailPage]
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

  // Snapshots of the original values, used to detect whether anything
  // actually changed before requiring a password confirmation on save.
  late String _originalStatus;
  late String? _originalSeverity;
  late String _originalNote;

  // Image change (admin only) — staged locally, only written to Firestore
  // when _saveStatus() runs, same pattern as _NewsFormPage.
  File? _pickedImage; // newly picked image, not yet uploaded
  bool _imageRemoved = false; // true if admin marked the existing photo for removal
  String? _originalImageUrl; // snapshot of the photo already on the doc

  /// Status options for the picker: label, icon, color [_statusOptions]
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
    _originalImageUrl = widget.data['imageUrl'] as String?;

    // Snapshot originals for change detection on save.
    _originalStatus = _currentStatus;
    _originalSeverity = _currentSeverity;
    _originalNote = _noteCtrl.text;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  /// ============================== [Report Actions Logic] ==============================
  /// Returns true if status, severity, note, or the photo have been changed
  /// from their original loaded values. [_hasChanges]
  bool _hasChanges() {
    final statusChanged = _currentStatus != _originalStatus;
    final severityChanged = _currentSeverity != _originalSeverity;
    final noteChanged = _noteCtrl.text.trim() != _originalNote.trim();
    final imageChanged = _pickedImage != null || _imageRemoved;
    return statusChanged || severityChanged || noteChanged || imageChanged;
  }

  /// Save status, severity, note, and (if changed) the photo. If anything
  /// was changed, the admin's password is required first — same
  /// confirmation used before deleting a whole report. [_saveStatus]
  Future<void> _saveStatus() async {
    if (_currentSeverity == null) {
      _showSnack('กรุณาเลือกระดับความรุนแรง', Colors.red.shade600);
      return;
    }

    // Require password confirmation whenever there is any change to save.
    if (_hasChanges()) {
      final confirmed = await showDeleteConfirmDialog(
        context,
        title: 'ยืนยันการบันทึกการเปลี่ยนแปลง',
        message: 'กรุณากรอกรหัสผ่านเพื่อยืนยันการบันทึกการเปลี่ยนแปลงนี้',
      );
      if (!confirmed) return;
    }

    setState(() => _isSaving = true);

    try {
      await _adminService.updateReportStatus(
        reportId: widget.reportId,
        status: _currentStatus,
        severity: _currentSeverity!,
        note: _noteCtrl.text.trim(),
      );

      if (_pickedImage != null) {
        await _adminService.updateReportImage(
          reportId: widget.reportId,
          image: _pickedImage!,
        );
      } else if (_imageRemoved) {
        await _adminService.removeReportImage(widget.reportId);
      }

      if (!mounted) return;
      _showSnack('อัพเดทสำเร็จ ✓', Colors.green.shade600);
      Navigator.pop(context);
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาด: $e', Colors.red.shade600);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Ask for password, then delete this report [_deleteReport]
  Future<void> _deleteReport() async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'ยืนยันการลบ',
      message: 'กรุณากรอกรหัสผ่านเพื่อยืนยันการลบรายการนี้ การกระทำนี้ไม่สามารถย้อนกลับได้',
    );

    if (!confirmed) return;

    try {
      await _adminService.deleteReport(widget.reportId);

      if (!mounted) return;
      _showSnack('ลบแล้ว', Colors.red.shade700);
      Navigator.pop(context);
    } catch (e) {
      _showSnack('ลบไม่ได้: $e', Colors.red.shade600);
    }
  }

  /// Opens a bottom sheet to choose image source (gallery / camera) [_showImageSourceSheet]
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: emasColor),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: emasColor),
              title: const Text('ถ่ายรูป'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Picks an image from the given source and stages it locally. Not
  /// uploaded until _saveStatus() runs. [_pickImage]
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;

    setState(() {
      _pickedImage = File(picked.path);
      _imageRemoved = false; // a freshly picked image supersedes any "removed" state
    });
  }

  /// Marks the photo for removal locally. Not deleted from Firestore until
  /// _saveStatus() runs (with password confirmation). [_removeImage]
  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _imageRemoved = true;
    });
  }

  /// ============================== [UI Helpers] ==============================
  /// Show a snackbar message [_showSnack]
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

  /// Icon for the status badge, matches _statusOptions [_statusIcon]
  IconData _statusIcon(String status) {
    switch (status) {
      case ReportStatus.pending:
        return Icons.hourglass_empty_rounded;
      case ReportStatus.inProgress:
        return Icons.construction_rounded;
      case ReportStatus.done:
        return Icons.check_circle_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  /// Opens the image at real/full size in a fullscreen zoomable viewer.
  /// Accepts either a freshly-picked File or an existing network URL. [_openFullImage]
  void _openFullImage({File? file, String? imageUrl}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _FullScreenImageViewer(imageFile: file, imageUrl: imageUrl),
          );
        },
      ),
    );
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    final building = '${data['building'] ?? '-'}';
    final floor = '${data['floor'] ?? '-'}';
    final room = '${data['room'] ?? '-'}';
    final desc = '${data['description'] ?? '-'}';
    final status = data['status'] ?? ReportStatus.pending;
    final dateTime = data['dateTime'] ?? '-';
    final username = '${data['username'] ?? '-'}';
    final phone = '${data['phone'] ?? '-'}';
    final severityKey = data['severity'] as String?;
    final severity = getSeverityInfo(severityKey);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: emasColor,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('รายละเอียดการแจ้งปัญหา',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [emasColor, emasColorDarker],
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
                // รูปภาพ
                _buildHeroImage(),
                const SizedBox(height: 14),

                // หัวข้อ + severity/status/date badge
                GlassCard(
                  child: _buildTitleSection(
                    building: building,
                    floor: floor,
                    room: room,
                    status: status,
                    dateTime: dateTime,
                    severity: severity,
                  ),
                ),
                const SizedBox(height: 14),

                // ข้อมูลปัญหา
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CardHeader(icon: Icons.description_rounded, title: 'ข้อมูลปัญหา'),
                      const SizedBox(height: 12),
                      _info(Icons.apartment_rounded, 'อาคาร', building),
                      _info(Icons.layers_rounded, 'ชั้น', floor),
                      _info(
                        Icons.edit_note_rounded,
                        'รายละเอียดปัญหา',
                        desc,
                        valueColor: emasColorDarker,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ข้อมูลผู้แจ้ง
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CardHeader(icon: Icons.person_outline_rounded, title: 'ข้อมูลผู้แจ้ง'),
                      const SizedBox(height: 12),
                      _info(Icons.person_rounded, 'ชื่อ', username),
                      _info(Icons.phone_rounded, 'เบอร์', phone),
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

                // ระดับความรุนแรง
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
                            Text('บันทึกการเปลี่ยนแปลง', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
  /// Hero photo. Tag 'img_${reportId}' must match the tag used on the list
  /// thumbnail for the hero animation to work. Shows the staged pick
  /// (_pickedImage) if present, the original imageUrl otherwise (unless
  /// staged for removal), or a placeholder. Edit/remove are staged only —
  /// nothing is written to Firestore until _saveStatus() runs. Admin only. [_buildHeroImage]
  Widget _buildHeroImage() {
    final hasPickedImage = _pickedImage != null;
    final hasExistingImage = !hasPickedImage && !_imageRemoved && _originalImageUrl != null;
    final hasAnyImage = hasPickedImage || hasExistingImage;

    return Stack(
      children: [
        Hero(
          tag: 'img_${widget.reportId}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: hasPickedImage
                ? Image.file(
                    _pickedImage!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : (hasExistingImage
                    ? Image.network(
                        _originalImageUrl!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : _buildNoImagePlaceholder()),
          ),
        ),
        if (hasAnyImage)
          Positioned(
            right: 10,
            bottom: 10,
            child: _imageActionButton(
              icon: Icons.zoom_out_map_rounded,
              onTap: () => _openFullImage(
                file: hasPickedImage ? _pickedImage : null,
                imageUrl: hasPickedImage ? null : _originalImageUrl,
              ),
            ),
          ),
        // Edit + remove buttons, top-right — staged only, saved on _saveStatus()
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _imageActionButton(
                icon: Icons.edit_rounded,
                onTap: _showImageSourceSheet,
              ),
              if (hasAnyImage) ...[
                const SizedBox(width: 8),
                _imageActionButton(
                  icon: Icons.close_rounded,
                  onTap: _removeImage,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Small circular icon button used for both the expand and change-image
  /// actions on the hero photo [_imageActionButton]
  Widget _imageActionButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  /// Shown when there's no photo [_buildNoImagePlaceholder]
  Widget _buildNoImagePlaceholder() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('ไม่มีรูปภาพ', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  /// Title row (building/floor/room + severity badge) plus a status/date
  /// badge row [_buildTitleSection]
  Widget _buildTitleSection({
    required String building,
    required String floor,
    required String room,
    required String status,
    required String dateTime,
    required SeverityInfo severity,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$building $floor ห้อง $room',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            _buildSeverityBadge(severity),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoChip(
              _statusIcon(status),
              status,
              getStatusTextColor(status),
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              Icons.calendar_today_outlined,
              shortenThaiDate(dateTime),
              Colors.grey.shade600,
            ),
          ],
        ),
      ],
    );
  }

  /// Severity dot + label badge [_buildSeverityBadge]
  Widget _buildSeverityBadge(SeverityInfo severity) {
    final isHigh = severity.label == severityLevels['high']!.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: severity.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: severity.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isHigh
              ? Text(
                  '!',
                  style: TextStyle(
                    color: severity.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                )
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: severity.color,
                    shape: BoxShape.circle,
                  ),
                ),
          const SizedBox(width: 5),
          Text(
            severity.label,
            style: TextStyle(
              color: severity.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Outlined pill used for the status/dateTime badges [_buildInfoChip]
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Icon + label + value row [_info]
  Widget _info(IconData icon, String label, String value, {Color? valueColor}) {
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
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One status option chip [_buildStatusChip]
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

  /// Severity picker row, from report_constants.dart [_buildSeverityRow]
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

  /// One severity chip [_buildSeverityChip]
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

/// [FULLSCREEN-IMAGE-VIEWER] แสดงรูปภาพขนาดจริงแบบเต็มจอ พร้อมซูม/ลากได้
/// รองรับทั้งรูปที่เพิ่งเลือก (File) และรูปเดิมที่อยู่บน network (String url)
/// ปิดได้ด้วยการแตะพื้นหลัง หรือกดปุ่มปิดมุมขวาบน
class _FullScreenImageViewer extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;

  const _FullScreenImageViewer({this.imageFile, this.imageUrl});

  Widget _buildImage() {
    if (imageFile != null) {
      return Image.file(imageFile!, fit: BoxFit.contain);
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stack) => const Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: Colors.white54,
        ),
      );
    }
    return const Icon(
      Icons.broken_image_outlined,
      size: 48,
      color: Colors.white54,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 5.0,
                  child: _buildImage(),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
