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

  Future<void> saveSchedule(String text, DateTime date) async {
    await FirebaseFirestore.instance
        .collection('audits')
        .doc(_auditId)
        .collection('schedules')
        .add({'text': text, 'date': Timestamp.fromDate(date)});
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

  void _showAddScheduleDialog() {
    final titleController = TextEditingController();
    DateTime? pickedDate;
    const templates = ["새내기 배움터", "MT", "간식행사", "기본"];
    String selectedTemplate = templates[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                  if (selected != null) pickedDate = selected;
                },
                child: const Text("날짜 선택"),
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: selectedTemplate,
                items: templates
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedTemplate = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final dateToUse = pickedDate ?? DateTime.now();
                final text = titleController.text;
                if (text.isNotEmpty) _addSchedule(text, dateToUse);
                Navigator.pop(context);
              },
              child: const Text("추가"),
            ),
          ],
        ),
      ),
    );
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
