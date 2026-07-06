import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared/constants/emas_colors.dart';

// Emergency contact model [_Contact]
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

/// ============================== [Data] ==============================
// Static emergency contact directory [_contacts]
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
    color: emasColor,
  ),
];

// Emergency contacts directory: tap a card to dial directly [EmergencyPage]
class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  /// ============================== [Build] ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
      ),
      title: const Text('เบอร์โทรฉุกเฉิน',
        style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: emasColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            decoration: const BoxDecoration(
              color: emasColor,
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

// Single contact card, tap to dial [_ContactCard]
class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});
  final _Contact contact;

  /// ============================== [Logic] ==============================
  // Launch the phone dialer with this contact's number.
  // NOTE: errors are silently swallowed — user gets no feedback if launch fails. [_call]
  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: contact.number);
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  /// ============================== [Build] ==============================
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
