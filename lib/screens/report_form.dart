import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _appColor = Color(0xFFe85d6a);

class ReportForm extends StatefulWidget {
  const ReportForm({super.key});

  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final _descController = TextEditingController();
  final _picker = ImagePicker();

  String? _building;
  String? _floor;
  File? _image;
  bool _isSubmitting = false;

  static const _buildings = [
    'อาคาร 1', 'อาคาร 2', 'อาคาร 3', 'อาคาร 4',
    'อาคาร 5', 'อาคาร 6', 'อาคาร 7', 'อาคาร 8',
    'อาคาร 9', 'อาคาร 10', 'อาคาร 11', 'อาคาร 12',
  ];

  static const _floors = [
    'ชั้น 1', 'ชั้น 2', 'ชั้น 3', 'ชั้น 4',
    'ชั้น 5', 'ชั้น 6', 'ชั้น 7', 'ชั้น 8',
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _image = File(image.path));
  }

  Future<void> _submit() async {
    if (_building == null || _floor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกอาคารและชั้น')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await FirebaseFirestore.instance.collection('reports').add({
      'building': _building,
      'floor': _floor,
      'description': _descController.text.trim(),
      'status': 'รอดำเนินการ',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ส่งแจ้งปัญหาเรียบร้อยแล้ว')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แบบฟอร์มแจ้งปัญหา'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แผนที่ placeholder
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('แผนที่จะอยู่ตรงนี้',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),

            // รูปภาพ
            const _SectionLabel('รูปภาพ'),
            const SizedBox(height: 10),
            if (_image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('อัปโหลดรูป'),
              ),
            ),
            const SizedBox(height: 24),

            // อาคาร
            const _SectionLabel('อาคาร'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _building,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: 'เลือกอาคาร'),
              items: _buildings
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (v) => setState(() => _building = v),
            ),
            const SizedBox(height: 20),

            // ชั้น
            const _SectionLabel('ชั้น'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _floor,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: 'เลือกชั้น'),
              items: _floors
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _floor = v),
            ),
            const SizedBox(height: 20),

            // รายละเอียด
            const _SectionLabel('รายละเอียดปัญหา'),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'กรอกรายละเอียด...'),
            ),
            const SizedBox(height: 24),

            // ปุ่มส่ง
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _appColor,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ส่งแจ้งซ่อม',
                        style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }
}
