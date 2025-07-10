// gallery_upload_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'category_add_page.dart';

class GalleryUploadPage extends StatefulWidget {
  final String template;

  const GalleryUploadPage({Key? key, required this.template}) : super(key: key);

  @override
  State<GalleryUploadPage> createState() => _GalleryUploadPageState();
}

class _GalleryUploadPageState extends State<GalleryUploadPage> {
  final ImagePicker _picker = ImagePicker();

  // 카테고리별 항목 저장
  final Map<String, List<String>> _categoryItems = {};
  // 카테고리별 항목 이미지 저장
  final Map<String, Map<String, XFile?>> _itemImages = {};

  // 이미지 선택
  Future<void> _pickImage(String category, String item) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _itemImages[category]![item] = image;
      });
    }
  }

  // 좌측 바 상단: 카테고리 추가 및 항목 추가
  Widget _buildAddButtons() {
    return Row(
      children: [
        TextButton(
          onPressed: () {
            // CategoryAddPage로 이동
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryAddPage()),
            );
          },
          child: const Text('카테고리 추가'),
        ),
        TextButton(
          onPressed: _showAddItemDialog,
          child: const Text('항목 추가'),
        ),
      ],
    );
  }

  // 항목 추가 다이얼로그
  void _showAddItemDialog() {
    final TextEditingController nameController = TextEditingController();
    String? selectedCategory;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('항목 추가'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: '카테고리 선택'),
                    items: _categoryItems.keys
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedCategory = val);
                    },
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '항목 이름'),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (selectedCategory != null && name.isNotEmpty) {
                  setState(() {
                    _categoryItems[selectedCategory!]!.add(name);
                    _itemImages[selectedCategory!]![name] = null;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('사진 업로드 • 템플릿: ${widget.template}'),
      ),
      body: Row(
        children: [
          // 좌측 트리 뷰
          Container(
            width: 200,
            color: Colors.grey[200],
            child: Column(
              children: [
                _buildAddButtons(),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: _categoryItems.entries.map((entry) {
                      final category = entry.key;
                      final items = entry.value;
                      return ExpansionTile(
                        title: Text(category),
                        children: items.map((item) {
                          final image = _itemImages[category]![item];
                          return ListTile(
                            title: Text(
                              item,
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: image != null
                                ? Image.file(File(image.path), width: 40, height: 40)
                                : const SizedBox(width: 40, height: 40),
                            onTap: () => _pickImage(category, item),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // 메인 콘텐츠
          Expanded(
            child: Center(
              child: const Text('카테고리와 항목을 선택하고 이미지를 업로드하세요.'),
            ),
          ),
        ],
      ),
    );
  }
}