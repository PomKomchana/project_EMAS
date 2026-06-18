import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _emasColor = Color(0xFFe85d6a);
const _emasColorDarker = Color(0xFFc4394a);

const severityLevels = {
  'high':   {'label': 'ด่วนมาก',  'color': Color(0xFFef4444)},
  'medium': {'label': 'ปานกลาง', 'color': Color(0xFFf97316)},
  'low':    {'label': 'ไม่ด่วน',  'color': Color(0xFF22c55e)},
  'none':   {'label': 'ยังไม่ระบุ', 'color': Colors.grey},
};

class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage>
    with TickerProviderStateMixin {

  late final TabController _tabController;
  late final AnimationController _fadeController;

  late final List<Animation<double>> _fadeList;
  late final List<Animation<Offset>> _slideList;

  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeList = List.generate(20, (i) {
      final start = (i * 0.05).clamp(0.0, 0.9);

      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start, 1.0, curve: Curves.easeOut),
        ),
      );
    });

    _slideList = List.generate(20, (i) {
      final start = (i * 0.05).clamp(0.0, 0.9);

      return Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
        ),
      );
    });

    _fadeController.forward();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _fadeController.reset();
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _reportsStream() {
    return FirebaseFirestore.instance
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56 + 48),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_emasColor, _emasColorDarker],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Text(
                        'รายการแจ้งปัญหา',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),

                      _buildFilterButton(),
                    ],
                  ),
                ),

                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle:
                      const TextStyle(fontWeight: FontWeight.normal),
                  tabs: const [
                    Tab(
                      child: Text('ทั้งหมด',
                          style: TextStyle(color: Colors.white)),
                    ),
                    Tab(
                      child: Text('ของฉัน',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(myReportsOnly: false),
          _buildList(myReportsOnly: true),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: () => _showFilterSheet(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.4), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  _filterStatus ?? 'ทุกสถานะ',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet( 
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.white.withOpacity(0.9),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('กรองตามสถานะ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),

                  for (final option in [
                    null,
                    'รอดำเนินการ',
                    'กำลังดำเนินการ',
                    'เสร็จสิ้น'
                  ])
                    ListTile(
                      leading: Icon(
                        _filterStatus == option
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _emasColor,
                      ),
                      title: Text(option ?? 'ทุกสถานะ'),
                      onTap: () {
                        setState(() => _filterStatus = option);
                        Navigator.pop(context);
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList({required bool myReportsOnly}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _reportsStream(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _emasColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
          );
        }

        var docs = snapshot.data?.docs ?? [];

        if (_filterStatus != null) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == _filterStatus;
          }).toList();
        }

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            final animIndex = index % _fadeList.length;

            return FadeTransition(
              opacity: _fadeList[animIndex],
              child: SlideTransition(
                position: _slideList[animIndex],
                child: _buildReportCard(context, data, id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'ไม่มีรายการ',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
      BuildContext context, Map<String, dynamic> data, String id) {

    final building = data['building'] ?? '-';
    final floor = data['floor'] ?? '-';
    final room = data['room'] ?? '-';
    final desc = data['description'] ?? '-';
    final status = data['status'] ?? 'รอดำเนินการ';
    final date = data['date'] ?? '-';
    final severity = data['severity'] ?? 'none';
    final imageUrl = data['imageUrl'] as String?;

    final severityColor = (severityLevels[severity]?['color'] as Color?) ?? Colors.grey;
    final severityLabel = (severityLevels[severity]?['label'] as String?) ?? 'ยังไม่ระบุ';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) =>
              ReportDetailPage(data: data, id: id),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                  parent: animation, curve: Curves.easeOut),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
        ),
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: Colors.white.withOpacity(0.6), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Hero(
                  tag: 'img_$id',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: Colors.grey.shade100,
                      child: imageUrl != null
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : Icon(Icons.image_outlined,
                              color: Colors.grey.shade400, size: 28),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$building · $floor · ห้อง $room',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          _buildSeverityBadge(
                              severityColor, severityLabel),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          _buildStatusChip(status),
                          const SizedBox(width: 8),
                          Icon(Icons.calendar_today_outlined,
                              size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'กำลังดำเนินการ':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        break;
      case 'เสร็จสิ้น':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      default:
        bg = _emasColor.withOpacity(0.1);
        fg = _emasColorDarker;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ReportDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String id;

  const ReportDetailPage({super.key, required this.data, required this.id});

  @override
  Widget build(BuildContext context) {
    final building = data['building'] ?? '-';
    final floor = data['floor'] ?? '-';
    final room = data['room'] ?? '-';
    final desc = data['description'] ?? '-';
    final status = data['status'] ?? '-';
    final date = data['date'] ?? '-';
    final username = data['username'] ?? '-';
    final phone = data['phone'] ?? '-';
    final severity = data['severity'] ?? 'none';
    final imageUrl = data['imageUrl'] as String?;

    final severityColor = (severityLevels[severity]?['color'] as Color?) ?? Colors.grey;
    final severityLabel = (severityLevels[severity]?['label'] as String?) ?? 'ยังไม่ระบุ';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_emasColor, _emasColorDarker],
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
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    : Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined,
                                size: 48,
                                color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('ไม่มีรูปภาพ',
                                style: TextStyle(
                                    color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            _buildGlassCard(
              child: Column(
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

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: severityColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: severityColor,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              severityLabel,
                              style: TextStyle(
                                color: severityColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _buildInfoChip(
                          Icons.info_outline_rounded, status,
                          _statusColor(status)),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                          Icons.calendar_today_outlined, date,
                          Colors.grey.shade600),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                      Icons.edit_note_rounded, 'รายละเอียดปัญหา'),
                  const SizedBox(height: 10),
                  Text(
                    desc,
                    style: const TextStyle(
                        fontSize: 14, height: 1.6, color: Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                      Icons.person_outline_rounded, 'ข้อมูลผู้แจ้ง'),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.person, 'ชื่อ', username),
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.phone, 'เบอร์', phone),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

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
            border: Border.all(
                color: Colors.white.withOpacity(0.6), width: 1),
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

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _emasColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _emasColor),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

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

  Color _statusColor(String status) {
    switch (status) {
      case 'กำลังดำเนินการ':
        return Colors.orange.shade700;
      case 'เสร็จสิ้น':
        return Colors.green.shade700;
      default:
        return _emasColorDarker;
    }
  }
}
