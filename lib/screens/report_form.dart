import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReportForm extends StatefulWidget {
  const ReportForm({super.key});

  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {

  // ===== Controller =====
  final descController = TextEditingController();

  // ===== Selected Values =====
  String? selectedBuilding;
  String? selectedFloor;

  // ===== Selected Image =====
  File? selectedImage;

  // ===== Building List =====
  final List<String> buildings = [
    'อาคาร 1',
    'อาคาร 2',
    'อาคาร 3',
    'อาคาร 4',
    'อาคาร 5',
    'อาคาร 6',
    'อาคาร 7',
    'อาคาร 8',
    'อาคาร 9',
    'อาคาร 10',
    'อาคาร 11',
    'อาคาร 12',
  ];

  // ===== Floor List =====
  final List<String> floors = [
    'ชั้น 1',
    'ชั้น 2',
    'ชั้น 3',
    'ชั้น 4',
    'ชั้น 5',
    'ชั้น 6',
  ];

  // ===== Pick Image =====
  Future<void> pickImage() async {

    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {

      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  // ===== Submit Report =====
  void submitReport() {

    print("Building: $selectedBuilding");
    print("Floor: $selectedFloor");
    print("Description: ${descController.text}");
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      // ===== App Bar =====
      appBar: AppBar(
        title: const Text("แบบฟอร์มแจ้งปัญหา"),
        centerTitle: true,
      ),

      // ===== Body =====
      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            /// =====================================================
            /// 1. Google Maps
            /// =====================================================

            Container(

              height: 180,
              width: double.infinity,

              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),

              child: const Center(
                child: Text(
                  "Google Maps จะอยู่ตรงนี้",

                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// =====================================================
            /// 2. Image Section
            /// =====================================================

            const Text(
              "รูปภาพ",

              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (selectedImage != null)

              ClipRRect(

                borderRadius: BorderRadius.circular(12),

                child: Image.file(
                  selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 10),

            SizedBox(

              width: double.infinity,

              child: OutlinedButton.icon(

                onPressed: pickImage,

                icon: const Icon(Icons.image),

                label: const Text("อัปโหลดรูป"),
              ),
            ),

            const SizedBox(height: 30),

            /// =====================================================
            /// 3. Building Section
            /// =====================================================

            const Text(
              "อาคาร",

              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),


            const SizedBox(height: 8),

            DropdownButtonFormField<String>(

              value: selectedBuilding,

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "เลือกอาคาร",
              ),

              items: buildings.map((building) {

                return DropdownMenuItem(
                  value: building,
                  child: Text(building),
                );

              }).toList(),

              onChanged: (value) {

                setState(() {
                  selectedBuilding = value;
                });
              },
            ),

            const SizedBox(height: 20),

            /// =====================================================
            /// 4. Floor Section
            /// =====================================================

            const Text(
              "ชั้น",

              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(

              value: selectedFloor,

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "เลือกชั้น",
              ),

              items: floors.map((floor) {

                return DropdownMenuItem(
                  value: floor,
                  child: Text(floor),
                );

              }).toList(),

              onChanged: (value) {

                setState(() {
                  selectedFloor = value;
                });
              },
            ),

            const SizedBox(height: 20),

            /// =====================================================
            /// 5. Description Section
            /// =====================================================

            const Text(
              "รายละเอียดปัญหา",

              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(

              controller: descController,

              maxLines: 5,

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "กรอกรายละเอียด...",
              ),
            ),

            const SizedBox(height: 20),

            /// =====================================================
            /// 6. Submit Button
            /// =====================================================

            SizedBox(

              width: double.infinity,
              height: 50,

              child: ElevatedButton(

                onPressed: submitReport,

                child: const Text(
                  "ส่งแจ้งซ่อม",

                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
