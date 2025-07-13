// menu_detail_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_add_page.dart';
import 'gallery_upload_page.dart';

class MenuDetailSidebarPage extends StatefulWidget {
  final String auditId;
  final String scheduleId;

  const MenuDetailSidebarPage({
    super.key,
    required this.auditId,
    required this.scheduleId,
  });

  @override
  State<MenuDetailSidebarPage> createState() => _MenuDetailSidebarPageState();
}

class _MenuDetailSidebarPageState extends State<MenuDetailSidebarPage> {
  final Map<String, List<String>> _categoryMap = {};
  String? _selectedCategory;
  String? _selectedSubcategory;

  @override
  void initState() {
    super.initState();
    _loadCategoriesFromFirestore();
  }

  Future<void> _loadCategoriesFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('audits')
        .doc(widget.auditId)
        .collection('schedules')
        .doc(widget.scheduleId)
        .collection('categories')
        .orderBy('createdAt')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'] as String;
      final subcategory = data['subcategory'] as String;
      _categoryMap.putIfAbsent(category, () => []);
      if (!_categoryMap[category]!.contains(subcategory)) {
        _categoryMap[category]!.add(subcategory);
      }
    }

    setState(() {});
  }

  Future<void> _addItem(String category, String subcategory) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _categoryMap.putIfAbsent(category, () => []);
      if (!_categoryMap[category]!.contains(subcategory)) {
        _categoryMap[category]!.add(subcategory);
      }
      _selectedCategory = category;
      _selectedSubcategory = subcategory;
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('audits')
        .doc(widget.auditId)
        .collection('schedules')
        .doc(widget.scheduleId)
        .collection('categories')
        .add({
      'category': category,
      'subcategory': subcategory,
      'createdAt': Timestamp.now(),
    });
  }

  void _navigateToAddCategory() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const CategoryAddPage()),
    );

    if (result != null) {
      final category = result['category']!;
      final subcategory = result['subcategory']!;
      await _addItem(category, subcategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("항목 추가 및 이미지 업로드")),
      body: Row(
        children: [
          Container(
            width: 250,
            color: Colors.grey[200],
            child: Column(
              children: [
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _navigateToAddCategory,
                  child: const Text('항목추가'),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: _categoryMap.entries.map((entry) {
                      final category = entry.key;
                      final subcategories = entry.value;
                      return ExpansionTile(
                        title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                        children: subcategories.map((sub) {
                          return ListTile(
                            title: Text(sub),
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                                _selectedSubcategory = sub;
                              });
                            },
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selectedSubcategory == null
                ? const Center(child: Text("세부분류를 선택해주세요"))
                : GalleryUploadPage(template: '$_selectedCategory > $_selectedSubcategory'),
          ),
        ],
      ),
    );
  }
}
