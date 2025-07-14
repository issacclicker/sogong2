import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'HomePage.dart';

class AuditListPage extends StatefulWidget {
  const AuditListPage({Key? key}) : super(key: key);

  @override
  State<AuditListPage> createState() => _AuditListPageState();
}

class _AuditListPageState extends State<AuditListPage> {
  final _dueDateController = TextEditingController();

  @override
  void dispose() {
    _dueDateController.dispose();
    super.dispose();
  }

  void _showAddAuditDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '새 감사 추가',
          style: TextStyle(
            fontFamily: 'Spoqa Han Sans',
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Color(0xFF212121),
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.all(8.0), // Reduced padding for content
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3A49FF), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '설명',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3A49FF), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dueDateController,
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    _dueDateController.text = DateFormat('yyyy.MM.dd').format(pickedDate);
                  }
                },
                decoration: const InputDecoration(
                  labelText: '마감일',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3A49FF), width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              final title = titleController.text.trim();
              final description = descriptionController.text.trim();
              final dueDateText = _dueDateController.text.trim();
              DateTime? dueDate;
              if (dueDateText.isNotEmpty) {
                dueDate = DateFormat('yyyy.MM.dd').parse(dueDateText);
              }

              if (user != null && title.isNotEmpty) {
                await FirebaseFirestore.instance.collection('audits').add({
                  'title': title,
                  'description': description,
                  'ownerId': user.uid,
                  'createdAt': Timestamp.now(),
                  'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
                });
              }
              Navigator.pop(context);
            },
            child: const Text('추가', style: TextStyle(color: Color(0xFF3A49FF))),
          ),
        ],
      ),
    );
  }

  void _showEditAuditDialog(BuildContext context, String auditId, Map<String, dynamic> currentData) {
    final titleController = TextEditingController(text: currentData['title']);
    final descriptionController = TextEditingController(text: currentData['description']);
    final dueDateController = TextEditingController();

    final Timestamp? currentDueDateTimestamp = currentData['dueDate'];
    if (currentDueDateTimestamp != null) {
      dueDateController.text = DateFormat('yyyy.MM.dd').format(currentDueDateTimestamp.toDate());
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '감사 수정',
          style: TextStyle(
            fontFamily: 'Spoqa Han Sans',
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Color(0xFF212121),
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3A49FF), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '설명',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3A49FF), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dueDateController,
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: currentDueDateTimestamp?.toDate() ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    dueDateController.text = DateFormat('yyyy.MM.dd').format(pickedDate);
                  }
                },
                decoration: const InputDecoration(
                  labelText: '마감일',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3A49FF), width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final description = descriptionController.text.trim();
              final dueDateText = dueDateController.text.trim();
              DateTime? dueDate;
              if (dueDateText.isNotEmpty) {
                dueDate = DateFormat('yyyy.MM.dd').parse(dueDateText);
              }

              if (title.isNotEmpty) {
                await FirebaseFirestore.instance.collection('audits').doc(auditId).update({
                  'title': title,
                  'description': description,
                  'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
                });
              }
              Navigator.pop(context);
            },
            child: const Text('수정', style: TextStyle(color: Color(0xFF3A49FF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        automaticallyImplyLeading: false, // 뒤로가기 버튼 비활성화
        title: const Text(
          '감사 목록',
          style: TextStyle(
            fontFamily: 'Spoqa Han Sans',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF666666)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('audits')
            .where('ownerId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '오류가 발생했어요: ${snapshot.error}',
                style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3A49FF)),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                '아직 등록된 감사가 없어요.',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final auditId = docs[index].id;
              final Timestamp? dueDateTimestamp = data['dueDate'];
              final String dueDateText = dueDateTimestamp != null
                  ? '마감일 : '+DateFormat('yyyy.MM.dd').format(dueDateTimestamp.toDate())
                  : '마감일 미지정';

              return Card(
                elevation: 1,
                shadowColor: const Color(0x10000000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomePage(auditId: auditId),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? '제목 없음',
                          style: const TextStyle(
                            fontSize: 18, // Slightly larger for emphasis
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF212121),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dueDateText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data['description'] ?? '설명 없음',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF999999)),
                              onPressed: () => _showEditAuditDialog(context, auditId, data),
                              tooltip: '감사 수정',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Color(0xFF999999)),
                              onPressed: () async {
                                // Show confirmation dialog
                                final bool? confirmDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('감사 삭제'),
                                      content: const Text('정말로 이 감사를 삭제하시겠습니까?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('취소'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('삭제'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirmDelete == true) {
                                  await FirebaseFirestore.instance.collection('audits').doc(auditId).delete();
                                }
                              },
                              tooltip: '감사 삭제',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAuditDialog(context),
        backgroundColor: const Color(0xFF3A49FF),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: '감사 추가',
        elevation: 2,
      ),
    );
  }
}
