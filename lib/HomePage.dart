import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'menu_detail_page.dart';
import 'package:collection/collection.dart';
import 'theme.dart';

class HomePage extends StatefulWidget {
  final String auditId;
  const HomePage({Key? key, required this.auditId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

const double spacing8 = 8.0;
const double spacing16 = 16.0;
const double spacing24 = 24.0;
const double spacing32 = 32.0;
const double spacing40 = 40.0;
const double spacing48 = 48.0;

// New Schedule class
class Schedule {
  final String id;
  final String text;
  final DateTime startDate;
  final DateTime endDate;

  Schedule({required this.id, required this.text, required this.startDate, required this.endDate});
}

class _HomePageState extends State<HomePage> {
  late String _auditId;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Schedule> _schedules = []; // Changed to List<Schedule>
  final List<String> _sidebarItems = [];
  bool _isSidebarVisible = false;
  String? _duplicateScheduleError;

  @override
  void initState() {
    super.initState();
    _auditId = widget.auditId;
    loadSchedules();
  }

  Future<String> saveSchedule(String text, DateTime startDate, DateTime endDate) async {
    try {
      print('Saving schedule to Firestore: text=$text, startDate=$startDate, endDate=$endDate');
      final docRef = await FirebaseFirestore.instance
          .collection('audits')
          .doc(_auditId)
          .collection('schedules')
          .add({'text': text, 'startDate': Timestamp.fromDate(startDate), 'endDate': Timestamp.fromDate(endDate)});
      print('Schedule saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error saving schedule: $e');
      rethrow; // Re-throw the error so it can be caught higher up
    }
  }

  Future<void> loadSchedules() async {
    try {
      print('Attempting to load schedules from Firebase...');
      final snapshot = await FirebaseFirestore.instance
          .collection('audits')
          .doc(_auditId)
          .collection('schedules')
          .get();

      _schedules.clear(); // Clear existing schedules
      _sidebarItems.clear(); // Clear existing sidebar items

      print('Fetched ${snapshot.docs.length} schedules.');
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        final text = data['text'] as String?; // Make text nullable for safety
        final dynamic rawStartDate = data['startDate'];
        final dynamic rawEndDate = data['endDate'];

        if (text == null || rawStartDate == null || rawEndDate == null || rawStartDate is! Timestamp || rawEndDate is! Timestamp) {
          print('Skipping invalid schedule document (ID: $id) due to missing or invalid data: $data');
          continue; // Skip this document if data is invalid
        }

        final startDate = rawStartDate.toDate();
        final endDate = rawEndDate.toDate();

        _schedules.add(Schedule(id: id, text: text, startDate: startDate, endDate: endDate));

        if (!_sidebarItems.contains(text)) {
          _sidebarItems.add(text);
        }
        print('Loaded schedule: $text (ID: $id)');
      }
      setState(() {});
    } catch (e) {
      print('Error loading schedules: $e');
    }
  }

  List<String> _getSchedulesForDay(DateTime day) {
    return _schedules
        .where((schedule) =>
            !day.isBefore(schedule.startDate) && day.isBefore(schedule.endDate.add(const Duration(days: 1))))
        .map((schedule) => schedule.text)
        .toList();
  }

  void _addSchedule(String text, DateTime startDate, DateTime endDate) async {
    print('Attempting to add schedule: $text, Start: $startDate, End: $endDate');
    final newScheduleId = await saveSchedule(text, startDate, endDate);
    _schedules.add(Schedule(id: newScheduleId, text: text, startDate: startDate, endDate: endDate));
    if (!_sidebarItems.contains(text)) {
      _sidebarItems.add(text);
    }
    setState(() {});
  }

  void _showTemplateSelectionDialog(String originalName, DateTime startDate, DateTime endDate) {
    const templates = [
      "뒤풀이",
      "공동구매(ex.과잠)",
      "단체행사(ex.새내기 새로배움터, MT 등)",
      "체육대회",
      "간식행사",
      "축제",
      "인스타그램 비대면 행사",
      "기념일 행사",
      "대여사업",
      "소모임 지원금 사업",
    ];
    String selectedTemplate = templates[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          surfaceTintColor: Colors.transparent, // Remove default surface tint
          title: Text(
            "템플릿 선택",
            style: Theme.of(context).textTheme.displayMedium,
          ),
          contentPadding: const EdgeInsets.all(spacing24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedTemplate,
                items: templates
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedTemplate = v);
                },
                isExpanded: true,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.all(spacing24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: Text("취소", style: Theme.of(context).textTheme.bodyLarge),
            ),
            ElevatedButton(
              onPressed: () {
                _createNewScheduleFromTemplate(
                  originalName,
                  selectedTemplate,
                  startDate,
                  endDate,
                );
                Navigator.pop(context); // Pop template selection dialog
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.pureWhite,
              ),
              child: Text("추가"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createNewScheduleFromTemplate(
    String originalName,
    String templateName,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // 1. Save the main schedule entry and get its ID
    final scheduleId = await saveSchedule(originalName, startDate, endDate);

    // 2. Apply the template structure using the new ID
    await _applyTemplateItems(scheduleId, templateName);

    // 3. Update local UI state
    _schedules.add(Schedule(id: scheduleId, text: originalName, startDate: startDate, endDate: endDate));
    if (!_sidebarItems.contains(originalName)) {
      _sidebarItems.add(originalName);
    }
    setState(() {});
  }

  Future<void> _applyTemplateItems(
    String scheduleId,
    String templateName,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final templateStructure = _getTemplateStructure(templateName);

    for (var itemData in templateStructure) {
      await _createFirestoreEntry(user.uid, scheduleId, itemData);
    }
  }

  Future<void> _createFirestoreEntry(
    String userId,
    String scheduleId,
    Map<String, dynamic> itemData, {
    String? parentFolderId,
  }) async {
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
        await _createFirestoreEntry(
          userId,
          scheduleId,
          subItem,
          parentFolderId: docRef.id,
        );
      }
    }
  }

  List<Map<String, dynamic>> _getTemplateStructure(String templateName) {
    switch (templateName) {
      case "뒤풀이":
        return [
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '매출전표',
            'items': [
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '28포차'},
            ],
          },
          {
            'type': 'folder',
            'category': '보충영수증빙자료',
            'displayName': '회비 납부자 명단',
          },
          {'type': 'folder', 'category': '보충영수증빙자료', 'displayName': '공지사항'},
          {'type': 'folder', 'category': '보충영수증빙자료', 'displayName': '참가자 명단'},
          {'type': 'folder', 'category': '기타증빙자료', 'displayName': '사진자료'},
        ];
      case "공동구매(ex.과잠)":
        return [
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '거래명세표',
            'items': [
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '28포차'},
            ],
          },
          {'type': 'folder', 'category': '영수증빙자료', 'displayName': '카드전표(카드결제)'},
          {'type': 'folder', 'category': '영수증빙자료', 'displayName': '이체증(계좌이체)'},
          {
            'type': 'folder',
            'category': '보충영수증빙자료',
            'displayName': '회비 납부자 명단',
          },
          {'type': 'folder', 'category': '보충영수증빙자료', 'displayName': '공지사항'},
          {'type': 'folder', 'category': '보충영수증빙자료', 'displayName': '상품 수령 명단'},
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '사진자료',
            'items': [
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '공동구매 구매사진',
              },
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '공동구매 수령사진(*품목 당 1개 이상 제출)',
              },
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '남은 물품 있는 경우 보관사진',
              },
            ],
          },
        ];
      case "간식행사":
        return [
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '거래명세표',
            'items': [
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '간식 가게 이름'},
            ],
          },
          {'type': 'folder', 'category': '영수증빙자료', 'displayName': '카드전표(카드결제)'},
          {'type': 'folder', 'category': '영수증빙자료', 'displayName': '이체증(계좌이체)'},
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '배달전표(배달비용이 있는 경우)',
          },
          {'type': 'folder', 'category': '보충영수증빙자료', 'displayName': '공지사항'},
          {'type': 'folder', 'category': '보충영수증빙자료', 'displayName': '상품 수령 명단'},
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '사진자료',
            'items': [
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '행사 진행사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '간식 수령사진'},
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '남은 물품 있는 경우 보관사진',
              },
            ],
          },
        ];
      case "체육대회":
        return [
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '매출전표',
            'items': [
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '물품 구매'},
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '상품 구매'},
            ],
          },
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '카드전표(카드번호가 미비한 경우)',
          },
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '거래명세표(거래내역이 미비한 경우)',
          },
          {'type': 'folder', 'category': '보충영수증빙자료', 'displayName': '공지사항'},
          {
            'type': 'folder',
            'category': '보충영수증빙자료',
            'displayName': '회비 납부자 명단',
          },
          {'type': 'folder', 'category': '보충영수증빙자료', 'displayName': '참여자 명단'},
          {'type': 'folder', 'category': '보충영수증빙자료', 'displayName': '상품 수령 명단'},
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '입금자명상이 증빙자료(필요시)',
          },
          {'type': 'folder', 'category': '기타증빙자료', 'displayName': '당첨자선정 증빙자료'},
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '사진자료',
            'items': [
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '행사 진행사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '물품 구매사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '물품 사용사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '상품 구매사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '상품 수령사진'},
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '남은 물품 있는 경우 보관사진',
              },
            ],
          },
        ];
      case "인스타그램 비대면 행사":
        return [
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '카드전표',
            'items': [
              {
                'type': 'item',
                'category': '영수증빙자료',
                'displayName': '(ex)0월0일 빽다방 쿠폰',
              },
            ],
          },
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '카카오톡 주문내역(카카오톡 선물하기의 경우, 거래명세표 역할)',
            'items': [
              {
                'type': 'item',
                'category': '영수증빙자료',
                'displayName': '(ex)0월0일 빽다방 쿠폰',
              },
            ],
          },
          {
            'type': 'folder',
            'category': '보충증빙자료',
            'displayName': '참여자 명단(인스타그램 아이디 명시)',
          },
          {'type': 'folder', 'category': '보충증빙자료', 'displayName': '상품수령 명단'},
          {'type': 'folder', 'category': '기타증빙자료', 'displayName': '공지사항'},
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '당첨자선정 증빙자료',
            'items': [
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '스토리의 경우 언급날짜가 포함된 당첨자 스토리 제출',
              },
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '댓글의 경우 댓글 단 내역 제출',
              },
            ],
          },
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '대리작성동의 증빙자료',
            'items': [
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '대리작성동의 증빙자료(상품 수령 명단)',
              },
            ],
          },
        ];
      case "기념일 행사":
        return [
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '매출전표(카드결제)',
            'items': [
              {
                'type': 'item',
                'category': '영수증빙자료',
                'displayName': '0월 0일 쿠팡주문',
              },
            ],
          },
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '이체증(계좌이체)',
            'items': [
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '물품 구매'},
            ],
          },
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '거래명세표(거래내역 미비)',
          },
          {
            'type': 'folder',
            'category': '보충증빙자료',
            'displayName': '참여자 명단(인스타그램 아이디 명시)',
          },
          {'type': 'folder', 'category': '보충증빙자료', 'displayName': '상품수령 명단'},
          {'type': 'folder', 'category': '기타증빙자료', 'displayName': '공지사항'},
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '대리작성동의 증빙자료',
            'items': [
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '대리작성동의 증빙자료(상품 수령 명단)',
              },
            ],
          },
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '사진자료',
            'items': [
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '행사 진행사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '물품 구매사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '물품 사용사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '상품 구매사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '상품 수령사진'},
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '남은 물품 있는 경우 보관사진',
              },
            ],
          },
        ];
      case "대여사업":
        return [
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '거래명세표',
            'items': [
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '28포차'},
            ],
          },
          {'type': 'folder', 'category': '영수증빙자료', 'displayName': '카드전표(카드결제)'},
          {'type': 'folder', 'category': '영수증빙자료', 'displayName': '이체증(계좌이체)'},
          {'type': 'folder', 'category': '보충영수증빙자료', 'displayName': '공지사항'},
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '사진자료',
            'items': [
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '공동구매 구매사진',
              },
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '공동구매 수령사진(*품목 당 1개 이상 제출)',
              },
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '남은 물품 있는 경우 보관사진',
              },
            ],
          },
        ];
      case "소모임 지원금 사업":
        return [
          {'type': 'folder', 'category': '영수증빙자료', 'displayName': '이체증'},
          {'type': 'folder', 'category': '보충영수증빙자료', 'displayName': '공지사항'},
          {'type': 'folder', 'category': '보충영수증빙자료', 'displayName': '수기증'},
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '대리작성동의 증빙자료(수기증)',
          },
          {'type': 'folder', 'category': '기타증빙자료', 'displayName': '당첨자선정 증빙자료'},
        ];
      case "축제":
        return [
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '매출전표',
            'items': [
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '상품 구매'},
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '물품 구매'},
              {
                'type': 'item',
                'category': '영수증빙자료',
                'displayName': '대여비(기계 렌탈비용)',
              },
            ],
          },
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '이체증(제2통장으로 수익 이월 시)',
          },
          {'type': 'folder', 'category': '보충증빙자료', 'displayName': '상품수령 명단'},
          {'type': 'folder', 'category': '보충증빙자료', 'displayName': '수기증'},

          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '공지사항',
            'items': [
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '행사 공지사항'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '계좌 공지사항'},
            ],
          },
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '축제 증빙자료',
            'items': [
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '축제 부스에 대해 논의한 자료',
              },
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '축제 수입금에 대한 예금거래실적증명서 및 결산안',
              },
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '중앙감사위원회 직인, 부스명, 예금주, 계좌번호가 포함된 계좌 공고',
              },
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '공고한 계좌번호를 부착한 사진자료',
              },
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '부스에서 판매하는 메뉴에 대한 정보가 담긴 사진자료',
              },
            ],
          },
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '대리작성동의 증빙자료',
            'items': [
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '대리작성동의 증빙자료(수기증)',
              },
            ],
          },
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '사진자료',
            'items': [
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '행사 진행사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '물품 구매사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '물품 사용사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '상품 구매사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '상품 수령사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '렌탈 물품사진'},
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '렌탈 물품 사용사진',
              },
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '남은 물품 있는 경우 보관사진',
              },
            ],
          },
        ];
      case "단체행사(ex.새내기 새로배움터, MT 등)":
        return [
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '매출전표',
            'items': [
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '상품 구매'},
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '물품 구매'},
            ],
          },
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '이체증',
            'items': [
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '숙소'},
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '버스'},
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '보험'},
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '안주업체'},
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '환불'},
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '정산'},
            ],
          },
          {
            'type': 'folder',
            'category': '영수증빙자료',
            'displayName': '거래명세표',
            'items': [
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '숙소'},
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '버스'},
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '보험'},
              {'type': 'item', 'category': '영수증빙자료', 'displayName': '안주업체'},
            ],
          },

          {'type': 'folder', 'category': '보충증빙자료', 'displayName': '회비 납부자 명단'},
          {'type': 'folder', 'category': '보충증빙자료', 'displayName': '참여자 명단'},
          {'type': 'folder', 'category': '보충증빙자료', 'displayName': '보험가입자 명단'},
          {'type': 'folder', 'category': '보충증빙자료', 'displayName': '보험가입 증서'},
          {'type': 'folder', 'category': '보충증빙자료', 'displayName': '상품수령 명단'},
          {
            'type': 'folder',
            'category': '보충증빙자료',
            'displayName': '수기증',
            'items': [
              {'type': 'item', 'category': '보충증빙자료', 'displayName': '환불'},
              {'type': 'item', 'category': '보충증빙자료', 'displayName': '정산'},
            ],
          },

          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '입금자명상이 증빙자료',
          },
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '차등회비선정 증빙자료',
          },
          {'type': 'folder', 'category': '기타증빙자료', 'displayName': '공지사항'},
          {'type': 'folder', 'category': '기타증빙자료', 'displayName': '숙소선정 증빙자료'},
          {'type': 'folder', 'category': '기타증빙자료', 'displayName': '당첨자선정 증빙자료'},
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '대리작성동의 증빙자료',
            'items': [
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '대리작성동의 증빙자료(수기증-환불)',
              },
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '대리작성동의 증빙자료(수기증-정산)',
              },
            ],
          },
          {
            'type': 'folder',
            'category': '기타증빙자료',
            'displayName': '사진자료',
            'items': [
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '행사 진행사진'},
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '숙소 대여사진 (숙소/강당 별로 1개씩)',
              },
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '버스 대여사진 (버스 번호판이 나오도록)',
              },
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '물품 구매사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '물품 사용사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '상품 구매사진'},
              {'type': 'item', 'category': '기타증빙자료', 'displayName': '상품 수령사진'},
              {
                'type': 'item',
                'category': '기타증빙자료',
                'displayName': '남은 물품 있는 경우 보관사진',
              },
            ],
          },
        ];
      default: // 기본
        return [];
    }
  }

  void _showTemplateChoiceDialog(String text, DateTime startDate, DateTime endDate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        surfaceTintColor: Colors.transparent,
        title: Text("템플릿 사용", style: Theme.of(context).textTheme.displayMedium),
        contentPadding: const EdgeInsets.all(spacing24),
        content: Text(
          "기본 제공 템플릿을 사용하시겠습니까?",
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actionsPadding: const EdgeInsets.all(spacing24),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Pop choice dialog
              _addSchedule(text, startDate, endDate);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            child: Text("아니오", style: Theme.of(context).textTheme.bodyLarge),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Pop choice dialog
              _showTemplateSelectionDialog(text, startDate, endDate);
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.pureWhite,
            ),
            child: Text("예"),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog() {
    final titleController = TextEditingController();
    DateTime? pickedStartDate; // Changed to pickedStartDate
    DateTime? pickedEndDate; // Added pickedEndDate
    String? currentDuplicateError; // Local variable for the dialog's state

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              surfaceTintColor: Colors.transparent,
              title: Text(
                "일정 추가",
                style: Theme.of(context).textTheme.displayMedium,
              ),
              contentPadding: const EdgeInsets.all(spacing24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "일정 내용",
                      errorText: currentDuplicateError,
                      labelStyle: Theme.of(context).textTheme.bodyLarge,
                      errorStyle: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppColors.error),
                    ),
                    onChanged: (value) async {
                      if (value.isNotEmpty) {
                        final isDuplicate = await _checkDuplicateScheduleName(
                          value,
                        );
                        setState(() {
                          if (isDuplicate) {
                            currentDuplicateError =
                                "'$value'은(는) 이미 등록된 일정입니다.";
                          } else {
                            currentDuplicateError = null;
                          }
                        });
                      } else {
                        setState(() {
                          currentDuplicateError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: spacing16),
                  ElevatedButton(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: pickedStartDate ?? _focusedDay,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selected != null) {
                        setState(() {
                          pickedStartDate = selected;
                        });
                      }
                    },
                    child: Text(
                      pickedStartDate == null
                          ? "시작 날짜 선택"
                          : "${pickedStartDate!.year}년 ${pickedStartDate!.month}월 ${pickedStartDate!.day}일",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.pureWhite),
                    ),
                  ),
                  const SizedBox(height: spacing8), // Added spacing
                  ElevatedButton(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: pickedEndDate ?? pickedStartDate ?? _focusedDay,
                        firstDate: pickedStartDate ?? DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selected != null) {
                        setState(() {
                          pickedEndDate = selected;
                        });
                      }
                    },
                    child: Text(
                      pickedEndDate == null
                          ? "끝 날짜 선택"
                          : "${pickedEndDate!.year}년 ${pickedEndDate!.month}월 ${pickedEndDate!.day}일",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.pureWhite),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.all(spacing24),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "취소",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final text = titleController.text.trim();
                    if (text.isEmpty) {
                      setState(() {
                        currentDuplicateError = "일정 내용을 입력해주세요.";
                      });
                      return;
                    }

                    if (pickedStartDate == null) {
                      setState(() {
                        currentDuplicateError = "시작 날짜를 선택해주세요.";
                      });
                      return;
                    }

                    if (pickedEndDate == null) {
                      setState(() {
                        currentDuplicateError = "끝 날짜를 선택해주세요.";
                      });
                      return;
                    }

                    if (pickedEndDate!.isBefore(pickedStartDate!)) {
                      setState(() {
                        currentDuplicateError = "끝 날짜는 시작 날짜보다 빠를 수 없습니다.";
                      });
                      return;
                    }

                    final isDuplicate = await _checkDuplicateScheduleName(text);
                    if (isDuplicate) {
                      setState(() {
                        currentDuplicateError = "'$text'은(는) 이미 등록된 일정입니다.";
                      });
                      return;
                    }

                    Navigator.pop(context); // Pop the initial dialog
                    _showTemplateChoiceDialog(text, pickedStartDate!, pickedEndDate!); // Pass both dates
                  },
                  child: Text(
                    "다음",
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.pureWhite,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditScheduleDialog(String oldName) {
    final titleController = TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        surfaceTintColor: Colors.transparent,
        title: Text(
          '일정 이름 수정',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        contentPadding: const EdgeInsets.all(spacing24),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: "새 일정 이름",
            labelStyle: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        actionsPadding: const EdgeInsets.all(spacing24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: Theme.of(context).textTheme.bodyLarge),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = titleController.text;
              if (newName.isNotEmpty && newName != oldName) {
                _updateScheduleName(oldName, newName);
              }
              Navigator.pop(context);
            },
            child: Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateScheduleName(String oldName, String newName) async {
    // Find the schedule by its old name
    final scheduleToUpdate = _schedules.firstWhere((s) => s.text == oldName);
    final scheduleId = scheduleToUpdate.id;

    // Update Firestore
    await FirebaseFirestore.instance
        .collection('audits')
        .doc(_auditId)
        .collection('schedules')
        .doc(scheduleId)
        .update({'text': newName});

    // Update local state
    setState(() {
      final index = _schedules.indexOf(scheduleToUpdate);
      if (index != -1) {
        _schedules[index] = Schedule(
          id: scheduleToUpdate.id,
          text: newName,
          startDate: scheduleToUpdate.startDate,
          endDate: scheduleToUpdate.endDate,
        );
      }
      // Also update sidebar items if necessary
      final sidebarIndex = _sidebarItems.indexOf(oldName);
      if (sidebarIndex != -1) {
        _sidebarItems[sidebarIndex] = newName;
      }
    });
  }

  void _showDeleteConfirmDialog(String scheduleText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        surfaceTintColor: Colors.transparent,
        title: Text('일정 삭제', style: Theme.of(context).textTheme.displayMedium),
        contentPadding: const EdgeInsets.all(spacing24),
        content: Text(
          '$scheduleText 일정을 정말 삭제하시겠습니까?',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actionsPadding: const EdgeInsets.all(spacing24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: Theme.of(context).textTheme.bodyLarge),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteSchedule(scheduleText);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.pureWhite,
            ),
            child: Text(
              '삭제',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSchedule(String scheduleText) async {
    // Find the schedule by its text
    final scheduleToDelete = _schedules.firstWhere((s) => s.text == scheduleText);
    final scheduleId = scheduleToDelete.id;

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
    setState(() {
      _schedules.removeWhere((s) => s.id == scheduleId);
      _sidebarItems.remove(scheduleText);
    });
  }

  Future<String?> _getScheduleIdByText(String text) async {
    final schedule = _schedules.firstWhereOrNull((s) => s.text == text);
    return schedule?.id;
  }

  Future<bool> _checkDuplicateScheduleName(String scheduleName) async {
    if (scheduleName.isEmpty) return false;
    // Check if any existing schedule has the same name
    return _schedules.any((s) => s.text == scheduleName);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> groupedSidebarItems = {'일정 목록': []};

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
        title: Text("홈 화면", style: Theme.of(context).textTheme.displayLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textSecondary),
            onPressed: () =>
                setState(() => _isSidebarVisible = !_isSidebarVisible),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Ensure left-aligned content
        children: [
          if (_isSidebarVisible)
            Container(
              width: 200.0,
              color: AppColors.grey100,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(spacing8),
                    child: IconButton(
                      icon: Icon(Icons.add, color: AppColors.textPrimary),
                      onPressed: _showAddScheduleDialog,
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: groupedSidebarItems.entries.expand((entry) {
                        if (entry.key == '일정 목록') {
                          return entry.value.map((sub) {
                            return ListTile(
                              title: Text(
                                sub,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 20.0,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () =>
                                        _showEditScheduleDialog(sub),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 20.0,
                                      color: AppColors.error,
                                    ),
                                    onPressed: () =>
                                        _showDeleteConfirmDialog(sub),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                final selectedScheduleId =
                                    await _getScheduleIdByText(sub);
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
                              title: Text(
                                entry.key,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              children: entry.value.map((sub) {
                                return ListTile(
                                  title: Text(
                                    sub,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                );
                              }).toList(),
                            ),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Ensure left-aligned content
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
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                  ),
                  daysOfWeekHeight: 40.0,
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (ctx, day, events) {
                      final ev = _getSchedulesForDay(day);
                      if (ev.isNotEmpty) {
                        return Positioned(
                          bottom: spacing8 / 2, // Use spacing constant
                          child: Container(
                            width: spacing8 / 2, // Use spacing constant
                            height: spacing8 / 2, // Use spacing constant
                            decoration: const BoxDecoration(
                              color: AppColors.error, // Use theme color
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
                  ..._getSchedulesForDay(_selectedDay!).map(
                    (e) => Padding(
                      padding: const EdgeInsets.all(
                        spacing8,
                      ), // Use spacing constant
                      child: Text(
                        "• $e",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ), // Use theme text style
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        backgroundColor: AppColors.primary, // Explicitly set background color
        child: const Icon(
          Icons.add,
          color: AppColors.pureWhite,
        ), // Set icon color
      ),
    );
  }
}

