import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'menu_detail_page.dart';

class HomePage extends StatefulWidget {
  final String auditId;
  const HomePage({Key? key, required this.auditId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _auditId;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<String>> _schedules = {};
  final List<String> _sidebarItems = [];
  bool _isSidebarVisible = false;

  @override
  void initState() {
    super.initState();
    _auditId = widget.auditId;
    loadSchedules();
  }

  Future<String> saveSchedule(String text, DateTime date) async {
    final docRef = await FirebaseFirestore.instance
        .collection('audits')
        .doc(_auditId)
        .collection('schedules')
        .add({'text': text, 'date': Timestamp.fromDate(date)});
    return docRef.id;
  }

  Future<void> loadSchedules() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('audits')
        .doc(_auditId)
        .collection('schedules')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final key = DateTime(date.year, date.month, date.day);
      final text = data['text'] as String;
      _schedules.putIfAbsent(key, () => []).add(text);
      if (!_sidebarItems.contains(text)) {
        _sidebarItems.add(text);
      }
    }
    setState(() {});
  }

  List<String> _getSchedulesForDay(DateTime day) {
    return _schedules[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _addSchedule(String text, DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    _schedules.putIfAbsent(key, () => []).add(text);
    if (!_sidebarItems.contains(text)) {
      _sidebarItems.add(text);
    }
    saveSchedule(text, date);
    setState(() {});
  }

  void _showTemplateSelectionDialog(String originalName, DateTime date) {
    const templates = ["새내기 배움터", "MT", "간식행사","뒤풀이", "기본"];
    String selectedTemplate = templates[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("템플릿 선택"),
          content: DropdownButton<String>(
            value: selectedTemplate,
            items: templates
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => selectedTemplate = v);
            },
            isExpanded: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소"),
            ),
            TextButton(
              onPressed: () {
                _createNewScheduleFromTemplate(originalName, selectedTemplate, date);
                Navigator.pop(context); // Pop template selection dialog
              },
              child: const Text("추가"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createNewScheduleFromTemplate(String originalName, String templateName, DateTime date) async {
    // 1. Save the main schedule entry and get its ID
    final scheduleId = await saveSchedule(originalName, date);

    // 2. Apply the template structure using the new ID
    await _applyTemplateItems(scheduleId, templateName);

    // 3. Update local UI state
    final key = DateTime(date.year, date.month, date.day);
    _schedules.putIfAbsent(key, () => []).add(originalName);
    if (!_sidebarItems.contains(originalName)) {
      _sidebarItems.add(originalName);
    }
    setState(() {});
  }

  Future<void> _applyTemplateItems(String scheduleId, String templateName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final templateStructure = _getTemplateStructure(templateName);

    for (var itemData in templateStructure) {
      await _createFirestoreEntry(user.uid, scheduleId, itemData);
    }
  }

  Future<void> _createFirestoreEntry(String userId, String scheduleId, Map<String, dynamic> itemData, {String? parentFolderId}) async {
    final collectionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('audits')
        .doc(_auditId)
        .collection('schedules')
        .doc(scheduleId)
        .collection('categories');

    Map<String, dynamic> dataToSave = {
      'type': itemData['type'],
      'category': itemData['category'],
      'displayName': itemData['displayName'],
      'createdAt': Timestamp.now(),
      'orderIndex': Timestamp.now().millisecondsSinceEpoch, // orderIndex 추가
    };

    if (parentFolderId != null) {
      dataToSave['parentFolderId'] = parentFolderId;
    }

    final docRef = await collectionRef.add(dataToSave);

    if (itemData['type'] == 'folder' && itemData.containsKey('items')) {
      for (var subItem in itemData['items']) {
        await _createFirestoreEntry(userId, scheduleId, subItem, parentFolderId: docRef.id);
      }
    }
  }

  List<Map<String, dynamic>> _getTemplateStructure(String templateName) {
    switch (templateName) {
      case "뒤풀이":
        return [
          {'type': 'folder', 'category': '영수증빙자료', 'displayName': '매출전표', 'items': [
            {'type': 'item', 'category': '영수증빙자료', 'displayName': '28포차'}
          ]},
          {'type': 'folder', 'category': '보충영수증빙자료', 'displayName': '회비 납부자 명단'},
          {'type': 'folder', 'category': '보충영수증빙자료', 'displayName': '공지사항'},
          {'type': 'folder', 'category': '기타증빙자료', 'displayName': '참가자 명단'},
          {'type': 'folder', 'category': '기타증빙자료', 'displayName': '사진자료'},
        ];
      case "새내기 배움터":
        return [
          {'type': 'folder', 'category': '영수증빙자료', 'displayName': '식비', 'items': [
            {'type': 'item', 'category': '영수증빙자료', 'displayName': '1일차 점심'},
            {'type': 'item', 'category': '영수증빙자료', 'displayName': '1일차 저녁'},
            {'type': 'item', 'category': '영수증빙자료', 'displayName': '2일차 아침'},
          ]},
          {'type': 'folder', 'category': '영수증빙자료', 'displayName': '교통비', 'items': [
            {'type': 'item', 'category': '영수증빙자료', 'displayName': '버스 대절'},
          ]},
          {'type': 'item', 'category': '기타증빙자료', 'displayName': '참가자 명단'},
          {'type': 'item', 'category': '기타증빙자료', 'displayName': '행사 계획서'},
        ];
      case "MT":
        return [
          {'type': 'folder', 'category': '영수증빙자료', 'displayName': '장보기', 'items': [
            {'type': 'item', 'category': '영수증빙자료', 'displayName': '1차 장보기'},
            {'type': 'item', 'category': '영수증빙자료', 'displayName': '2차 장보기'},
          ]},
          {'type': 'folder', 'category': '영수증빙자료', 'displayName': '숙소', 'items': [
            {'type': 'item', 'category': '영수증빙자료', 'displayName': '숙소 예약금'},
            {'type': 'item', 'category': '영수증빙자료', 'displayName': '숙소 잔금'},
          ]},
          {'type': 'item', 'category': '기타증빙자료', 'displayName': 'MT 참가자 명단'},
        ];
      case "간식행사":
        return [
          {'type': 'item', 'category': '영수증빙자료', 'displayName': '간식 구매'},
          {'type': 'item', 'category': '기타증빙자료', 'displayName': '수령자 명단'},
        ];
      default: // 기본
        return [];
    }
  }

  void _showTemplateChoiceDialog(String text, DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("템플릿 사용"),
        content: const Text("기본 제공 템플릿을 사용하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Pop choice dialog
              _addSchedule(text, date);
            },
            child: const Text("아니오"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Pop choice dialog
              _showTemplateSelectionDialog(text, date);
            },
            child: const Text("예"),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog() {
    final titleController = TextEditingController();
    DateTime? pickedDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("일정 추가"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "일정 내용"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: _focusedDay,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (selected != null) {
                  pickedDate = selected;
                }
              },
              child: const Text("날짜 선택"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              final dateToUse = pickedDate ?? _focusedDay;
              final text = titleController.text;
              if (text.isNotEmpty) {
                Navigator.pop(context); // Pop the initial dialog
                _showTemplateChoiceDialog(text, dateToUse);
              }
            },
            child: const Text("다음"),
          ),
        ],
      ),
    );
  }

  void _showEditScheduleDialog(String oldName) {
    final titleController = TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 이름 수정'),
        content: TextField(
          controller: titleController,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final newName = titleController.text;
              if (newName.isNotEmpty && newName != oldName) {
                _updateScheduleName(oldName, newName);
              }
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateScheduleName(String oldName, String newName) async {
    final scheduleId = await _getScheduleIdByText(oldName);
    if (scheduleId == null) return;

    // Update Firestore
    await FirebaseFirestore.instance
        .collection('audits')
        .doc(_auditId)
        .collection('schedules')
        .doc(scheduleId)
        .update({'text': newName});

    // Update local state
    final index = _sidebarItems.indexOf(oldName);
    if (index != -1) {
      _sidebarItems[index] = newName;
    }

    DateTime? keyToUpdate;
    List<String>? listToUpdate;

    for (var entry in _schedules.entries) {
      if (entry.value.contains(oldName)) {
        keyToUpdate = entry.key;
        listToUpdate = entry.value;
        break;
      }
    }

    if (keyToUpdate != null && listToUpdate != null) {
      final itemIndex = listToUpdate.indexOf(oldName);
      if (itemIndex != -1) {
        listToUpdate[itemIndex] = newName;
        _schedules[keyToUpdate] = listToUpdate;
      }
    }

    setState(() {});
  }

  void _showDeleteConfirmDialog(String scheduleText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text('$scheduleText 일정을 정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              _deleteSchedule(scheduleText);
              Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSchedule(String scheduleText) async {
    final scheduleId = await _getScheduleIdByText(scheduleText);
    if (scheduleId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Delete from Firestore
    await FirebaseFirestore.instance
        .collection('audits')
        .doc(_auditId)
        .collection('schedules')
        .doc(scheduleId)
        .delete();

    // Delete from local state
    _sidebarItems.remove(scheduleText);
    DateTime? keyToRemove;
    for (var entry in _schedules.entries) {
      if (entry.value.contains(scheduleText)) {
        entry.value.remove(scheduleText);
        if (entry.value.isEmpty) {
          keyToRemove = entry.key;
        }
        break;
      }
    }
    if (keyToRemove != null) {
      _schedules.remove(keyToRemove);
    }

    setState(() {});
  }

  Future<String?> _getScheduleIdByText(String text) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('audits')
        .doc(_auditId)
        .collection('schedules')
        .where('text', isEqualTo: text)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> groupedSidebarItems = {
      '일정 목록': [],
    };

    for (var item in _sidebarItems) {
      final parts = item.split(" > ");
      if (parts.length == 2) {
        groupedSidebarItems.putIfAbsent(parts[0], () => []).add(parts[1]);
      } else {
        groupedSidebarItems['일정 목록']!.add(item);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("홈 화면"),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (_isSidebarVisible)
            Container(
              width: 200,
              color: Colors.grey[200],
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _showAddScheduleDialog,
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: groupedSidebarItems.entries.expand((entry) {
                        if (entry.key == '일정 목록') {
                          return entry.value.map((sub) {
                            return ListTile(
                              title: Text(sub),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showEditScheduleDialog(sub),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _showDeleteConfirmDialog(sub),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                final selectedScheduleId = await _getScheduleIdByText(sub);
                                if (selectedScheduleId != null) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MenuDetailSidebarPage(
                                        auditId: _auditId,
                                        scheduleId: selectedScheduleId,
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          }).toList();
                        } else {
                          return [
                            ExpansionTile(
                              title: Text(entry.key),
                              children: entry.value.map((sub) {
                                return ListTile(title: Text(sub));
                              }).toList(),
                            )
                          ];
                        }
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Column(
              children: [
                TableCalendar(
                  focusedDay: _focusedDay,
                  firstDay: DateTime.utc(2000, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (sd, fd) => setState(() {
                    _selectedDay = sd;
                    _focusedDay = fd;
                  }),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (ctx, day, events) {
                      final ev = _getSchedulesForDay(day);
                      if (ev.isNotEmpty) {
                        return Positioned(
                          bottom: 1,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
                if (_selectedDay != null)
                  ..._getSchedulesForDay(_selectedDay!).map((e) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("• $e"),
                  )),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
