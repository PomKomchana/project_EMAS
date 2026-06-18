import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _appColor = Color(0xFFe85d6a);

// ── Data ──────────────────────────────────────────────────────────────────────

class _Contact {
  const _Contact({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.number,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final String number;
  final Color color;
}

const _contacts = [
  _Contact(
    icon: Icons.local_police_outlined,
    label: 'ตำรวจ',
    subtitle: 'สายด่วนตำรวจ',
    number: '191',
    color: Color(0xFF1565C0),
  ),
  _Contact(
    icon: Icons.local_fire_department_outlined,
    label: 'ดับเพลิง',
    subtitle: 'หน่วยดับเพลิง',
    number: '199',
    color: Color(0xFFBF360C),
  ),
  _Contact(
    icon: Icons.emergency_outlined,
    label: 'หน่วยกู้ชีพ EMS',
    subtitle: 'รถพยาบาลฉุกเฉิน',
    number: '1669',
    color: Color(0xFF2E7D32),
  ),
  _Contact(
    icon: Icons.flash_on_outlined,
    label: 'การไฟฟ้า',
    subtitle: 'การไฟฟ้าส่วนภูมิภาค',
    number: '1129',
    color: Color(0xFFF57F17),
  ),
  _Contact(
    icon: Icons.water_drop_outlined,
    label: 'การประปา',
    subtitle: 'การประปาส่วนภูมิภาค',
    number: '1662',
    color: Color(0xFF0277BD),
  ),
  _Contact(
    icon: Icons.school_outlined,
    label: 'รปภ. มศว องครักษ์',
    subtitle: 'งานรักษาความปลอดภัย',
    number: '037395397',
    color: _appColor,
  ),
];

// ── Page ──────────────────────────────────────────────────────────────────────

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เบอร์โทรฉุกเฉิน',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: _appColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            decoration: const BoxDecoration(
              color: _appColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phone_in_talk,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('กดที่การ์ดเพื่อโทรออกทันที',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('สายด่วนฉุกเฉินในพื้นที่',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // Contact list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ContactCard(contact: _contacts[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contact card ──────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});
  final _Contact contact;

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: contact.number);
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: _call,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: contact.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(contact.icon, color: contact.color, size: 26),
              ),
              const SizedBox(width: 14),

              // Label + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contact.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(contact.subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),

              // Number badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: contact.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      contact.number,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
