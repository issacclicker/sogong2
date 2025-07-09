// gallery_upload_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GalleryUploadPage extends StatefulWidget {
  /// 전달된 템플릿 이름을 받습니다.
  final String template;

  const GalleryUploadPage({
    Key? key,
    required this.template,
  }) : super(key: key);

  @override
  State<GalleryUploadPage> createState() => _GalleryUploadPageState();
}

class _GalleryUploadPageState extends State<GalleryUploadPage> {
  final ImagePicker _picker = ImagePicker();

  // 동적으로 추가되는 좌측 목록 데이터 (name, category)
  final List<Map<String, String>> _options = [];
  // 동적으로 추가되는 카테고리 목록
  final List<String> _categories = ['Work', 'Personal', 'Event', 'Other'];
  int _selectedOptionIndex = -1;
  // 각 옵션별 업로드된 이미지를 저장할 맵
  final Map<int, XFile?> _optionImages = {};

  // 주어진 옵션 인덱스에 대해 이미지 선택
  Future<void> _pickImageForOption(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _optionImages[index] = image;
      });
    }
  }

  // 현재 선택된 옵션 인덱스로 이미지 선택 호출
  Future<void> _pickImage() async {
    if (_selectedOptionIndex >= 0) {
      await _pickImageForOption(_selectedOptionIndex);
    }
  }

  // 카테고리 추가 다이얼로그
  void _showAddCategoryDialog() {
    final TextEditingController categoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('카테고리 추가'),
          content: TextField(
            controller: categoryController,
            decoration: const InputDecoration(labelText: '카테고리 이름'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final cat = categoryController.text.trim();
                if (cat.isNotEmpty) {
                  setState(() {
                    _categories.add(cat);
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

  // 좌측 바에 새 옵션을 추가하는 다이얼로그
  void _showAddOptionDialog() {
    final TextEditingController nameController = TextEditingController();
    String tempCategory = _categories.first;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('항목 추가'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '항목 이름'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: tempCategory,
                    items: _categories
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          tempCategory = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      setState(() {
                        _options.add({
                          'name': name,
                          'category': tempCategory,
                        });
                        _selectedOptionIndex = _options.length - 1;
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
          // 좌측 목록 바
          Container(
            width: 140,
            color: Colors.grey[200],
            child: Column(
              children: [
                // 카테고리 추가 버튼
                IconButton(
                  icon: const Icon(Icons.category),
                  tooltip: '카테고리 추가',
                  onPressed: _showAddCategoryDialog,
                ),
                // 항목 추가 버튼
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: '항목 추가',
                  onPressed: _showAddOptionDialog,
                ),
                const Divider(height: 1),
                // 옵션 리스트
                Expanded(
                  child: ListView.builder(
                    itemCount: _options.length,
                    itemBuilder: (context, index) {
                      final opt = _options[index];
                      return ListTile(
                        selected: index == _selectedOptionIndex,
                        title: Text(opt['name']!),
                        subtitle: Text(opt['category']!),
                        onTap: () {
                          setState(() {
                            _selectedOptionIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // 메인 콘텐츠
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 선택된 템플릿 및 카테고리 표시
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '템플릿: ${widget.template}   카테고리: ${_selectedOptionIndex >= 0 ? _options[_selectedOptionIndex]['category'] : '-'}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // 선택된 옵션의 이미지 미리보기
                  if (_selectedOptionIndex >= 0 && _optionImages[_selectedOptionIndex] != null)
                    Image.file(
                      File(_optionImages[_selectedOptionIndex]!.path),
                      width: 300,
                    )
                  else
                    const Text('선택된 사진 없음'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('갤러리에서 사진 선택'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}