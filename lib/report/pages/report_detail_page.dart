import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../shared/constants/emas_colors.dart';
import '../../shared/constants/report_constants.dart';
import '../../shared/utils/thai_date.dart';

/// Detail view for a single report, opened from ReportListPage
class ReportDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String id;

  const ReportDetailPage({
    super.key,
    required this.data,
    required this.id,
  });

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
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
    final location = data['lat'] != null
        ? '${data['lat']}, ${data['lng']}'
        : 'ไม่ได้ระบุ';

    // Privacy guard — reporter details (location, name, phone) are only
    // revealed to the person who submitted the report. Anyone else viewing
    // (this page is user-facing, never the admin one) sees a locked
    // placeholder instead [_isOwnReport]
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwnReport = currentUid != null && data['createdBy'] == currentUid;
    // Reports submitted by an admin have no real reporter — location stays
    // visible, and name/phone collapse into a single "Admin" indicator [_isAdmin]
    final isAdmin = data['createdBy'] == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroImage(imageUrl),
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
                location: location,
                isOwnReport: isOwnReport,
                isAdmin: isAdmin,
              ),
            ),
            const SizedBox(height: 12),

            _buildGlassCard(
              child: _buildReporterSection(
                isOwnReport: isOwnReport,
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
            'รายละเอียด',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
      ),
    );
  }

  /// Hero photo, shares tag with the list page thumbnail [_buildHeroImage]
  Widget _buildHeroImage(String? imageUrl) {
    return Hero(
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

  /// "ข้อมูลรายงาน" card — building/floor/description/location rows,
  /// mirrors AdminReportDetailPage's report-info card. ตำแหน่ง is always
  /// visible for admin-submitted reports and for the viewer's own report;
  /// otherwise it's locked (shows a lock icon + "Admin") [_buildReportInfoSection]
  Widget _buildReportInfoSection({
    required String building,
    required String floor,
    required String desc,
    required String location,
    required bool isOwnReport,
    required bool isAdmin,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.description_rounded, 'ข้อมูลปัญหา'),
        const SizedBox(height: 12),
        _buildDetailRow(Icons.apartment_rounded, 'อาคาร', building),
        _buildDetailRow(Icons.layers_rounded, 'ชั้น', floor),
        _buildDetailRow(Icons.edit_note_rounded, 'รายละเอียดปัญหา', desc),
        (isAdmin || isOwnReport)
            ? _buildDetailRow(Icons.location_on_rounded, 'ตำแหน่ง', location)
            : _buildLockedDetailRow(Icons.location_on_rounded, 'ตำแหน่ง'),
      ],
    );
  }

  /// "ข้อมูลผู้แจ้ง" card — for admin-submitted reports, name/phone collapse
  /// into a single combined "Admin" indicator; for other users' reports
  /// they're locked (lock icon + "Admin"); for the viewer's own report the
  /// real values show [_buildReporterSection]
  Widget _buildReporterSection({
    required bool isOwnReport,
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
        else if (isOwnReport) ...[
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
  /// row is hidden from non-owners (ตำแหน่ง/ชื่อ/เบอร์) [_buildLockedValue]
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

  /// Locked variant of [_buildDetailRow] — value replaced with lock+Admin [_buildLockedDetailRow]
  Widget _buildLockedDetailRow(IconData icon, String label) {
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
          _buildLockedValue(),
        ],
      ),
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
  Widget _buildDetailRow(IconData icon, String label, String value) {
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
