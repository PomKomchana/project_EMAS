import 'dart:ui';
import 'package:flutter/material.dart';

import '../../shared/constants/emas_colors.dart';
import '../../shared/constants/report_constants.dart';

// Detail view for a single report, opened from ReportListPage
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
    final date = data['date'] ?? '-';
    final username = data['username'] ?? '-';
    final phone = data['phone'] ?? '-';
    final imageUrl = data['imageUrl'] as String?;
    final severityKey = data['severity'] as String?;
    final severity = getSeverityInfo(severityKey);

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
                date: date,
                severity: severity,
              ),
            ),
            const SizedBox(height: 12),

            _buildGlassCard(
              child: _buildDescriptionSection(desc),
            ),
            const SizedBox(height: 12),

            _buildGlassCard(
              child: _buildReporterSection(username: username, phone: phone),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// ============================== [Widgets] ==============================
  // App Bar with back button and title [_buildAppBar]
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

  // Hero photo, shares tag with the list page thumbnail [_buildHeroImage]
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

  // Shown when there's no photo [_buildNoImagePlaceholder]
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

  // Title + severity badge + status/date chips [_buildHeaderSection]
  Widget _buildHeaderSection({
    required String building,
    required String floor,
    required String room,
    required String status,
    required String date,
    required SeverityInfo severity,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$building · $floor · ห้อง $room',
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
              Icons.info_outline_rounded,
              status,
              getStatusTextColor(status),
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              Icons.calendar_today_outlined,
              date,
              Colors.grey.shade600,
            ),
          ],
        ),
      ],
    );
  }

  // Severity dot + label (duplicate of list page's version) [_buildSeverityBadge]
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

  // "รายละเอียดปัญหา" card [_buildDescriptionSection]
  Widget _buildDescriptionSection(String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.edit_note_rounded, 'รายละเอียดปัญหา'),
        const SizedBox(height: 10),
        Text(
          desc,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // "ข้อมูลผู้แจ้ง" card [_buildReporterSection]
  Widget _buildReporterSection({
    required String username,
    required String phone,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.person_outline_rounded, 'ข้อมูลผู้แจ้ง'),
        const SizedBox(height: 10),
        _buildInfoRow(Icons.person, 'ชื่อ', username),
        const SizedBox(height: 6),
        _buildInfoRow(Icons.phone, 'เบอร์', phone),
      ],
    );
  }

  // Glass card background (duplicate of list page's glass container) [_buildGlassCard]
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

  // Icon chip + bold title for each section [_buildSectionHeader]
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

  // "label: value" row, used for name/phone [_buildInfoRow]
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

  // Outlined pill for the status/date chips [_buildInfoChip]
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
