import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/constants/emas_colors.dart';
import '../../shared/constants/report_constants.dart';
import '../../shared/utils/thai_date.dart';

/// Detail view for a single report, opened from ReportListPage
class ReportDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String id;

  const ReportDetailPage({
    super.key,
    required this.data,
    required this.id,
  });

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {

  /// ============================== [State] ==============================
  /// Whether the currently logged-in user has role == 'admin' in
  /// users/{uid}. Admins can see everything regardless of ownership [_isViewerAdmin]
  bool _isViewerAdmin = false;
  bool _isCheckingRole = true;

  /// ============================== [Life Cycle] ==============================
  @override
  void initState() {
    super.initState();
    _checkViewerRole();
  }

  /// ============================== [Data] ==============================
  /// Reads users/{uid}.role from Firestore to determine admin access [_checkViewerRole]
  Future<void> _checkViewerRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isCheckingRole = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final role = doc.data()?['role'] ?? 'user';

      if (mounted) {
        setState(() {
          _isViewerAdmin = role == 'admin';
          _isCheckingRole = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingRole = false);
    }
  }

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final id = widget.id;

    // Data Mapping — fall back to '-' for missing fields (older reports may lack some)
    final building = data['building'] ?? '-';
    final floor = data['floor'] ?? '-';
    final room = data['room'] ?? '-';
    final desc = data['description'] ?? '-';
    final status = data['status'] ?? ReportStatus.pending;
    final dateTime = data['dateTime'] ?? '-';
    final username = data['username'] ?? '-';
    final phone = data['phone'] ?? '-';
    final imageUrl = data['imageUrl'] as String?;
    final severityKey = data['severity'] as String?;
    final severity = getSeverityInfo(severityKey);

    // Privacy guard — reporter details (name, phone) are only revealed to
    // the person who submitted the report, or to a viewer whose Firestore
    /// role == 'admin'. Everyone else sees a locked placeholder [_isOwnReport, _canReveal]
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwnReport = currentUid != null && data['createdBy'] == currentUid;
    final canReveal = isOwnReport || _isViewerAdmin;
    // Reports submitted by an admin have no real reporter — name/phone
    /// collapse into a single "Admin" indicator [_isAdmin]
    final isAdmin = data['createdBy'] == 'admin';

    if (_isCheckingRole) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: _buildAppBar(context),
        body: const Center(child: CircularProgressIndicator(color: emasColor)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroImage(context, imageUrl, id),
            const SizedBox(height: 16),

            _buildGlassCard(
              child: _buildHeaderSection(
                building: building,
                floor: floor,
                room: room,
                status: status,
                dateTime: dateTime,
                severity: severity,
                isAdmin: isAdmin,
              ),
            ),
            const SizedBox(height: 12),

            _buildGlassCard(
              child: _buildReportInfoSection(
                building: building,
                floor: floor,
                desc: desc,
              ),
            ),
            const SizedBox(height: 12),

            _buildGlassCard(
              child: _buildReporterSection(
                canReveal: canReveal,
                isAdmin: isAdmin,
                username: username,
                phone: phone,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// ============================== [Widgets] ==============================
  /// App Bar with back button and title [_buildAppBar]
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: emasColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'รายละเอียด',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [emasColor, emasColorDarker],
          ),
        ),
      ),
    );
  }

  /// Hero photo, shares tag with the list page thumbnail. Includes an expand
  /// button (bottom-right) to view the image at full/real size. [_buildHeroImage]
  Widget _buildHeroImage(BuildContext context, String? imageUrl, String id) {
    return Stack(
      children: [
        Hero(
          tag: 'img_$id',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : _buildNoImagePlaceholder(),
          ),
        ),
        if (imageUrl != null)
          Positioned(
            right: 10,
            bottom: 10,
            child: _expandImageButton(
              () => _openFullImage(context, imageUrl),
            ),
          ),
      ],
    );
  }

  /// Small circular button that opens the full-size image viewer [_expandImageButton]
  Widget _expandImageButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.zoom_out_map_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Opens the image at real/full size in a fullscreen zoomable viewer [_openFullImage]
  void _openFullImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _FullScreenImageViewer(imageUrl: imageUrl),
          );
        },
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

  /// Title + severity badge + status/dateTime chips (+ Admin badge for
  /// admin-submitted reports) [_buildHeaderSection]
  Widget _buildHeaderSection({
    required String building,
    required String floor,
    required String room,
    required String status,
    required String dateTime,
    required SeverityInfo severity,
    required bool isAdmin,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSeverityBadge(severity),
                if (isAdmin) ...[
                  const SizedBox(height: 6),
                  _buildAdminBadge(),
                ],
              ],
            ),
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
              Colors.grey.shade600
            ),
          ],
        ),
      ],
    );
  }

  /// Small "Admin" pill, same style as ReportListPage's badge for
  /// admin-submitted reports [_buildAdminBadge]
  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: emasColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Admin',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: emasColorDarker),
      ),
    );
  }

  /// Icon for the status chip, matches AdminReportDetailPage's _statusOptions [_statusIcon]
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

  /// Severity dot + label (duplicate of list page's version) [_buildSeverityBadge]
  Widget _buildSeverityBadge(SeverityInfo severity) {
    final isHigh = severity.label == severityLevels['high']!.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: severity.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: severity.color.withOpacity(0.4)),
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

  /// "ข้อมูลปัญหา" card — building/floor/description rows, mirrors
  /// AdminReportDetailPage's report-info card [_buildReportInfoSection]
  Widget _buildReportInfoSection({
    required String building,
    required String floor,
    required String desc,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.description_rounded, 'ข้อมูลปัญหา'),
        const SizedBox(height: 12),
        _buildDetailRow(Icons.apartment_rounded, 'อาคาร', building),
        _buildDetailRow(Icons.layers_rounded, 'ชั้น', floor),
        _buildDetailRow(Icons.edit_note_rounded, 'รายละเอียดปัญหา', desc, valueColor: emasColorDarker),
      ],
    );
  }

  /// "ข้อมูลผู้แจ้ง" card — for admin-submitted reports, name/phone collapse
  /// when canReveal is true (owner or admin viewer), locked otherwise [_buildReporterSection]
  Widget _buildReporterSection({
    required bool canReveal,
    required bool isAdmin,
    required String username,
    required String phone,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.person_outline_rounded, 'ข้อมูลผู้แจ้ง'),
        const SizedBox(height: 10),
        if (isAdmin)
          _buildCombinedAdminBadge()
        else if (canReveal) ...[
          _buildInfoRow(Icons.person, 'ชื่อ', username),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.phone, 'เบอร์', phone),
        ] else ...[
          _buildLockedInfoRow(Icons.person, 'ชื่อ'),
          const SizedBox(height: 6),
          _buildLockedInfoRow(Icons.phone, 'เบอร์'),
        ],
      ],
    );
  }

  /// Combined name+phone placeholder for admin-submitted reports [_buildCombinedAdminBadge]
  Widget _buildCombinedAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: emasColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, size: 14, color: emasColorDarker),
          const SizedBox(width: 6),
          Text(
            'แจ้งโดย Admin',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: emasColorDarker,
            ),
          ),
        ],
      ),
    );
  }

  /// Lock icon + "Admin" text, used as the value placeholder wherever a
  /// row is hidden from non-owners (ชื่อ/เบอร์) [_buildLockedValue]
  Widget _buildLockedValue() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_rounded, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          'Admin',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  /// Locked variant of [_buildInfoRow] — value replaced with lock+Admin [_buildLockedInfoRow]
  Widget _buildLockedInfoRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        _buildLockedValue(),
      ],
    );
  }

  /// Glass card background (duplicate of list page's glass container) [_buildGlassCard]
  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  /// Icon chip + bold title for each section [_buildSectionHeader]
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: emasColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: emasColor),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Icon + label (fixed width) + value row, used in "ข้อมูลรายงาน"
  /// (matches AdminReportDetailPage's _info row layout) [_buildDetailRow]
  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: emasColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  /// "label: value" row, used for name/phone [_buildInfoRow]
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Outlined pill for the status/dateTime chips [_buildInfoChip]
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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
}

/// [FULLSCREEN-IMAGE-VIEWER] แสดงรูปภาพขนาดจริงแบบเต็มจอ พร้อมซูม/ลากได้
/// ปิดได้ด้วยการแตะพื้นหลัง หรือกดปุ่มปิดมุมขวาบน
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

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
                  child: Image.network(
                    imageUrl,
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
                  ),
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
                  color: Colors.white.withOpacity(0.15),
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