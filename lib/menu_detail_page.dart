import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  Map<String, List<Map<String, dynamic>>> _categoryData = {
    '영수증빙자료': [],
    '보충영수증빙자료': [],
    '기타증빙자료': [],
  };
  Map<String, dynamic>? _selectedItemInfo;
  bool _isLoading = true;
  bool _isSendingEmail = false;

  @override
  void initState() {
    super.initState();
    _loadDataFromFirestore();
  }

  // Firestore에서 데이터를 불러오는 로직 수정
  Future<void> _loadDataFromFirestore() async {
    setState(() {
      _isLoading = true;
      // 각 카테고리의 리스트만 비움 (기본 카테고리는 유지)
      _categoryData.forEach((key, list) {
        if (['영수증빙자료', '보충영수증빙자료', '기타증빙자료'].contains(key)) {
          list.clear(); // Clear items within default categories
        } else {
          // Remove categories that are not default and have no items
          // This part might need more sophisticated logic if dynamic categories are allowed
        }
      });
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
        .orderBy('orderIndex', descending: false) // orderIndex를 기준으로 정렬
        .get();

    // Map to hold all items/folders by their ID for easy lookup and hierarchy building
    Map<String, Map<String, dynamic>> allEntitiesMap = {};

    for (var doc in snapshot.docs) {
      var data = doc.data();
      data['id'] = doc.id;
      if (data['type'] == 'folder') {
        data['items'] = <Map<String, dynamic>>[]; // Initialize items list for folders
      }
      allEntitiesMap[doc.id] = data;
    }

    // Build the hierarchy and populate _categoryData
    allEntitiesMap.forEach((id, entity) {
      final parentId = entity['parentFolderId'];
      if (parentId != null && allEntitiesMap.containsKey(parentId) && allEntitiesMap[parentId]!['type'] == 'folder') {
        // This entity is a child of a folder
        allEntitiesMap[parentId]!['items'].add(entity);
      } else {
        // This entity is a root item or a root folder
        final category = entity['category'] as String;
        _categoryData.putIfAbsent(category, () => []).add(entity);
      }
    });

    setState(() => _isLoading = false);
  }

  // 항목/폴더 추가 로직 (수정됨)
  Future<void> _navigateAndAddItem(String category, {bool isCreatingFolder = false, String? parentFolderId}) async {
    // isCreatingFolder가 true이면, CategoryAddPage로 이동하여 폴더로 사용할 항목을 선택
    if (isCreatingFolder) {
      final result = await Navigator.push<Map<String, String>>(
        context,
        MaterialPageRoute(builder: (_) => CategoryAddPage(initialCategory: category, isForFolder: true)),
      );

      if (result != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final displayName = result['displayName']!;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('audits')
            .doc(widget.auditId)
            .collection('schedules')
            .doc(widget.scheduleId)
            .collection('categories')
            .add({
          'type': 'folder', // 항상 'folder' 타입으로 저장
          'category': category,
          'displayName': displayName,
          'createdAt': Timestamp.now(),
          'orderIndex': Timestamp.now().millisecondsSinceEpoch,
        });
        _loadDataFromFirestore();
      }
    } else {
      // isCreatingFolder가 false이면, 사용자 지정 이름을 입력받는 다이얼로그를 표시
      _showAddItemDialog(category, parentFolderId);
    }
  }

  Future<void> _showEditOrDeleteChoiceDialog(Map<String, dynamic> item) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('무엇을 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close choice dialog
              if (item['type'] == 'folder') {
                _showEditFolderDialog(item);
              } else {
                _showEditItemDialog(item);
              }
            },
            child: const Text('수정'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirm dialog
              await _deleteItem(item);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),

        ],
      ),
    );
  }

  Future<void> _showEditFolderDialog(Map<String, dynamic> folder) async {
    final folderNameController = TextEditingController(text: folder['displayName']);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 이름 수정'),
        content: TextField(
          controller: folderNameController,
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
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != folder['displayName']) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('audits')
          .doc(widget.auditId)
          .collection('schedules')
          .doc(widget.scheduleId)
          .collection('categories')
          .doc(folder['id'])
          .update({'displayName': newName});

      _loadDataFromFirestore();
    }
  }

  Future<void> _showEditItemDialog(Map<String, dynamic> item) async {
    final itemNameController = TextEditingController(text: item['displayName']);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('항목 이름 수정'),
        content: TextField(
          controller: itemNameController,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (itemNameController.text.isNotEmpty) {
                Navigator.pop(context, itemNameController.text);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != item['displayName']) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('audits')
          .doc(widget.auditId)
          .collection('schedules')
          .doc(widget.scheduleId)
          .collection('categories')
          .doc(item['id'])
          .update({'displayName': newName});

      _loadDataFromFirestore();
    }
  }

  Future<void> _showAddItemDialog(String category, String? parentFolderId) async {
    final itemNameController = TextEditingController();

    final itemName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('항목 추가'),
        content: TextField(
          controller: itemNameController,
          decoration: const InputDecoration(hintText: '항목 이름을 입력하세요'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (itemNameController.text.isNotEmpty) {
                Navigator.pop(context, itemNameController.text);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (itemName != null && itemName.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

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
        'displayName': itemName,
        'parentFolderId': parentFolderId,
        'createdAt': Timestamp.now(),
        'orderIndex': Timestamp.now().millisecondsSinceEpoch,
      });
      _loadDataFromFirestore();
    }
  }

  Future<void> _showSendEmailDialog() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('이메일 발송'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: emailController,
              decoration: const InputDecoration(hintText: "받는 사람 이메일 주소"),
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return '유효한 이메일 주소를 입력하세요.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  _triggerSendEmail(emailController.text);
                }
              },
              child: const Text('발송'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _triggerSendEmail(String recipientEmail) async {
    setState(() {
      _isSendingEmail = true;
    });

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendEmailWithImages');
      final response = await callable.call(<String, dynamic>{
        'auditId': widget.auditId,
        'scheduleId': widget.scheduleId,
        'recipientEmail': recipientEmail,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.data['message'] ?? '이메일이 발송되었습니다.')),
      );
    } on FirebaseFunctionsException catch (e) {
      print('Cloud Function Error: ${e.code} - ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일 발송 실패: ${e.message}')),
      );
    } catch (e) {
      print('Generic Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알 수 없는 오류로 이메일 발송에 실패했습니다.')),
      );
    }

    setState(() {
      _isSendingEmail = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("항목 추가 및 이미지 업로드"),
        actions: [
          if (_isSendingEmail)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.email),
              onPressed: _showSendEmailDialog,
            ),
        ],
      ),
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
              key: ValueKey(_selectedItemInfo!['id']), // Add key to force widget rebuild
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

  Future<void> _updateItemOrder(String categoryName, int oldIndex, int newIndex, {String? parentFolderId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<Map<String, dynamic>> items;
    if (parentFolderId == null) {
      // Root level items
      items = _categoryData[categoryName]!;
    } else {
      // Child items within a folder
      // Find the parent folder in _categoryData
      final parentFolder = _categoryData[categoryName]!.firstWhere(
            (element) => element['id'] == parentFolderId,
        orElse: () => throw Exception("Parent folder not found"),
      );
      items = parentFolder['items'];
    }

    // Adjust newIndex if it's moving down
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // Reorder the list locally
    final Map<String, dynamic> itemToMove = items.removeAt(oldIndex);
    items.insert(newIndex, itemToMove);

    // Update orderIndex in Firestore for affected items
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < items.length; i++) {
      DocumentReference docRef;
      if (parentFolderId == null) {
        docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('audits')
            .doc(widget.auditId)
            .collection('schedules')
            .doc(widget.scheduleId)
            .collection('categories')
            .doc(items[i]['id']);
      } else {
        docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('audits')
            .doc(widget.auditId)
            .collection('schedules')
            .doc(widget.scheduleId)
            .collection('categories')
            .doc(parentFolderId) // Parent folder ID
            .collection('items') // Assuming sub-collection for items within a folder
            .doc(items[i]['id']);
      }

      batch.update(
        docRef,
        {'orderIndex': i}, // Use index as new orderIndex
      );
    }
    await batch.commit();

    // Reload data to ensure UI is consistent with Firestore
    _loadDataFromFirestore();
  }

  // 카테고리 리스트 UI 생성 로직 수정
  List<Widget> _buildCategoryList() {
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
            onTap: () => _navigateAndAddItem(categoryName, isCreatingFolder: true),
          ),
          const Divider(),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false, // Add this line
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildItemWidget(item, categoryName, key: ValueKey(item['id']), itemIndex: index); // Pass itemIndex
            },
            onReorder: (oldIndex, newIndex) {
              _updateItemOrder(categoryName, oldIndex, newIndex);
            },
          ),
        ],
      );
    }).toList();
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('audits')
          .doc(widget.auditId)
          .collection('schedules')
          .doc(widget.scheduleId)
          .collection('categories')
          .doc(item['id'])
          .delete();

      // If it's a folder, also delete its children (optional, depending on desired behavior)
      if (item['type'] == 'folder' && item.containsKey('items')) {
        for (var childItem in item['items']) {
          await _deleteItem(childItem); // Recursively delete children
        }
      }

      _loadDataFromFirestore(); // Reload data to update UI
    } catch (e) {
      print("Error deleting item: $e");
      // Optionally show a SnackBar or AlertDialog to the user
    }
  }

  // 개별 항목/폴더 위젯 (변경 없음)
  Widget _buildItemWidget(Map<String, dynamic> item, String categoryName, {Key? key, int? itemIndex}) {
    bool isFolder = item['type'] == 'folder';

    if (isFolder) {
      return ExpansionTile(
        key: key, // Add key for ReorderableListView
        title: Row(
          children: [
            const Icon(Icons.folder, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(item['displayName'], style: const TextStyle(fontSize: 14))),
            ReorderableDragStartListener(
              index: itemIndex!, // Use itemIndex here
              child: const Icon(Icons.drag_handle, size: 20), // Drag handle for folders
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditOrDeleteChoiceDialog(item),
            ),
          ],
        ),
        children: [
          ListTile(
            leading: const Icon(Icons.add, size: 20),
            title: const Text('항목 추가', style: TextStyle(fontSize: 13)),
            dense: true,
            onTap: () => _navigateAndAddItem(categoryName, parentFolderId: item['id']),
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false, // Add this line
            itemCount: (item['items'] as List<Map<String, dynamic>>).length,
            itemBuilder: (context, index) {
              final childItem = (item['items'] as List<Map<String, dynamic>>)[index];
              return _buildItemWidget(childItem, categoryName, key: ValueKey(childItem['id']), itemIndex: index); // Pass index here
            },
            onReorder: (oldIndex, newIndex) {
              _updateItemOrder(categoryName, oldIndex, newIndex, parentFolderId: item['id']);
            },
          ),
        ],
      );
    } else {
      return ListTile(
        key: key, // Add key for ReorderableListView
        title: Text(item['displayName'], style: const TextStyle(fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: itemIndex!, // Use itemIndex here
              child: const Icon(Icons.drag_handle, size: 20), // Drag handle for items
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditOrDeleteChoiceDialog(item),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            _selectedItemInfo = item;
          });
        },
      );
    }
  }
}
