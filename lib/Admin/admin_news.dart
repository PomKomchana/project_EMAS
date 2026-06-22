import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _appColor = Color(0xFFe85d6a);

class AdminNewsPage extends StatelessWidget {
  const AdminNewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _appColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มข่าวสาร'),
        onPressed: () => _showNewsDialog(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('news')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.newspaper, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('ยังไม่มีข่าวสาร',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    backgroundColor: _appColor.withOpacity(0.1),
                    child: const Icon(Icons.campaign, color: _appColor),
                  ),
                  title: Text(data['title'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['content'] ?? '-',
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () =>
                            _showNewsDialog(context, doc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: Colors.red),
                        onPressed: () => _deleteNews(context, doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showNewsDialog(BuildContext context,
      {QueryDocumentSnapshot? doc}) {
    final titleCtrl = TextEditingController(
        text: doc != null
            ? (doc.data() as Map<String, dynamic>)['title'] ?? ''
            : '');
    final contentCtrl = TextEditingController(
        text: doc != null
            ? (doc.data() as Map<String, dynamic>)['content'] ?? ''
            : '');
    final isEdit = doc != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'แก้ไขข่าวสาร' : 'เพิ่มข่าวสารใหม่'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'หัวข้อ *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'เนื้อหา',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _appColor),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;

              final newsData = {
                'title': titleCtrl.text.trim(),
                'content': contentCtrl.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              };

              if (isEdit) {
                await FirebaseFirestore.instance
                    .collection('news')
                    .doc(doc!.id)
                    .update(newsData);
              } else {
                newsData['createdAt'] = FieldValue.serverTimestamp();
                await FirebaseFirestore.instance
                    .collection('news')
                    .add(newsData);
              }

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'บันทึก' : 'เพิ่ม',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteNews(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('ต้องการลบข่าวสารนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('news')
                  .doc(docId)
                  .delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
