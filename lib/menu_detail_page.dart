import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  // 데이터 구조를 미리 초기화하여 항상 키가 존재하도록 보장
  final Map<String, List<Map<String, dynamic>>> _categoryData = {
    '영수증빙자료': [],
    '보충영수증빙자료': [],
    '기타증빙자료': [],
  };
  Map<String, dynamic>? _selectedItemInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataFromFirestore();
  }

  // Firestore에서 데이터를 불러오는 로직 수정
  Future<void> _loadDataFromFirestore() async {
    setState(() {
      _isLoading = true;
      // 각 카테고리의 리스트만 비움
      _categoryData.forEach((_, list) => list.clear());
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

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

    List<Map<String, dynamic>> allItems = [];
    List<Map<String, dynamic>> allFolders = [];

    for (var doc in snapshot.docs) {
      var data = doc.data();
      data['id'] = doc.id;
      if (data['type'] == 'folder') {
        data['items'] = <Map<String, dynamic>>[];
        allFolders.add(data);
      } else {
        allItems.add(data);
      }
    }

    Map<String, Map<String, dynamic>> folderMap = {
      for (var folder in allFolders) folder['id']: folder
    };

    List<Map<String, dynamic>> rootItems = [];
    for (var item in allItems) {
      final parentId = item['parentFolderId'];
      if (parentId != null && folderMap.containsKey(parentId)) {
        folderMap[parentId]!['items'].add(item);
      } else {
        rootItems.add(item);
      }
    }

    final combinedList = [...allFolders, ...rootItems];
    for (var entry in combinedList) {
      final category = entry['category'] as String;
      if (_categoryData.containsKey(category)) {
        _categoryData[category]!.add(entry);
      }
    }

    setState(() => _isLoading = false);
  }

  // 폴더 추가 다이얼로그 (변경 없음)
  Future<void> _showAddFolderDialog(String category) async {
    final folderNameController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final folderName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 폴더 추가'),
        content: TextField(
          controller: folderNameController,
          decoration: const InputDecoration(hintText: '폴더 이름을 입력하세요'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (folderNameController.text.isNotEmpty) {
                Navigator.pop(context, folderNameController.text);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (folderName != null && folderName.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('audits')
          .doc(widget.auditId)
          .collection('schedules')
          .doc(widget.scheduleId)
          .collection('categories')
          .add({
        'type': 'folder',
        'category': category,
        'displayName': folderName,
        'createdAt': Timestamp.now(),
      });
      _loadDataFromFirestore();
    }
  }

  // 항목 추가 로직 (변경 없음)
  Future<void> _navigateAndAddItem(String category, {String? parentFolderId}) async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const CategoryAddPage()),
    );

    if (result != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final subcategory = result['subcategory']!;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('audits')
          .doc(widget.auditId)
          .collection('schedules')
          .doc(widget.scheduleId)
          .collection('categories')
          .add({
        'type': 'item',
        'category': category,
        'subcategory': subcategory,
        'displayName': subcategory,
        'parentFolderId': parentFolderId,
        'createdAt': Timestamp.now(),
      });
      _loadDataFromFirestore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("항목 추가 및 이미지 업로드")),
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 250,
            color: Colors.grey[200],
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: _buildCategoryList(),
                  ),
          ),
          const VerticalDivider(width: 1),
          // Right Content Area
          Expanded(
            child: _selectedItemInfo == null
                ? const Center(child: Text("항목을 선택해주세요"))
                : GalleryUploadPage(
                    auditId: widget.auditId,
                    scheduleId: widget.scheduleId,
                    itemId: _selectedItemInfo!['id'],
                    itemDisplayName: _selectedItemInfo!['displayName'],
                  ),
          ),
        ],
      ),
    );
  }

  // 카테고리 리스트 UI 생성 로직 수정
  List<Widget> _buildCategoryList() {
    // 이제 _categoryData.entries를 직접 사용하여 순서대로 UI를 생성
    return _categoryData.entries.map((entry) {
      final categoryName = entry.key;
      final items = entry.value;

      return ExpansionTile(
        initiallyExpanded: true,
        title: Text(categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          ListTile(
            leading: const Icon(Icons.create_new_folder_outlined),
            title: const Text('폴더 추가', style: TextStyle(fontSize: 14)),
            dense: true,
            onTap: () => _showAddFolderDialog(categoryName),
          ),
          const Divider(),
          ...items.map((item) => _buildItemWidget(item, categoryName)).toList(),
        ],
      );
    }).toList();
  }

  // 개별 항목/폴더 위젯 (변경 없음)
  Widget _buildItemWidget(Map<String, dynamic> item, String categoryName) {
    bool isFolder = item['type'] == 'folder';

    if (isFolder) {
      return ExpansionTile(
        title: Row(
          children: [
            const Icon(Icons.folder, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(item['displayName'], style: const TextStyle(fontSize: 14))),
          ],
        ),
        children: [
          ListTile(
            leading: const Icon(Icons.add, size: 20),
            title: const Text('항목 추가', style: TextStyle(fontSize: 13)),
            dense: true,
            onTap: () => _navigateAndAddItem(categoryName, parentFolderId: item['id']),
          ),
          ...(item['items'] as List<Map<String, dynamic>>)
              .map((childItem) => _buildItemWidget(childItem, categoryName))
              .toList(),
        ],
      );
    } else {
      return ListTile(
        title: Text(item['displayName'], style: const TextStyle(fontSize: 14)),
        onTap: () {
          setState(() {
            _selectedItemInfo = item;
          });
        },
      );
    }
  }
}
