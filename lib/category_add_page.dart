// category_add_page.dart
import 'package:flutter/material.dart';

class CategoryAddPage extends StatefulWidget {
  const CategoryAddPage({Key? key}) : super(key: key);

  @override
  State<CategoryAddPage> createState() => _CategoryAddPageState();
}

class _CategoryAddPageState extends State<CategoryAddPage> {
  final List<String> _categories = [
    '영수증빙자료',
    '보충영수증빙자료',
    '기타증빙자료',
  ];

  final Map<String, List<String>> _defaultOptions = {
    '영수증빙자료': [
      '매출 전표(오프라인 카드결제)',
      '카드 전표(온라인 카드결제)',
      '이체증(계좌이체,본통장입금)',
      '현금영수증(현금결제)',
      '결제취소전표(취소시 발급되는 영수증)',
      '거래내역서',
      '간이영수증',
      '카드전표',
    ],
    '보충영수증빙자료': [
      '회비납부자명단',
      '참여자 명단',
      '상품수령명단(수령증)',
      '보험가입증서',
      '보험가입자명단',
      '수기증',
      '차용증명서',
    ],
    '기타증빙자료': [
      '사진',
      '공지사항',
      '차등회비선정 증빙자료',
      '대리작성동의 증빙자료',
      '회비 잔여금동의 증빙자료',
      '상품선정 증빙자료',
      '당첨자선정 증빙자료',
      '입금계좌 증빙자료',
      '입금자명상이 증빙자료',
      '축제 증빙자료',
      '사전답사 증빙자료',
      '숙소선정 증빙자료',
    ],
  };

  String _selectedCategory = '영수증빙자료';
  String _selectedSubcategory = '매출 전표(오프라인 카드결제)';

  @override
  Widget build(BuildContext context) {
    final subOptions = _defaultOptions[_selectedCategory]!;

    return Scaffold(
      appBar: AppBar(title: const Text('카테고리 추가')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) 대분류 선택 드롭다운
            const Text('대분류'),
            DropdownButton<String>(
              value: _selectedCategory,
              items: _categories
                  .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedCategory = v;
                  // 대분류 변경 시 서브 분류도 첫 항목으로 초기화
                  _selectedSubcategory = _defaultOptions[v]!.first;
                });
              },
            ),
            const SizedBox(height: 20),

            // 2) 소분류(세부 분류) 선택 드롭다운
            const Text('세부 분류'),
            DropdownButton<String>(
              value: _selectedSubcategory,
              items: subOptions
                  .map((sub) => DropdownMenuItem(
                value: sub,
                child: Text(sub),
              ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedSubcategory = v;
                });
              },
            ),
            const SizedBox(height: 30),

            // 3) 툴팁 영역
            Row(
              children: [
                // 세부 분류에 대한 툴팁
                Tooltip(
                  message: '세부 분류 선택: $_selectedSubcategory',
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, size: 20),
                      SizedBox(width: 4),
                      Text('세부 분류 힌트'),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // 대분류에 대한 툴팁
                Tooltip(
                  message: '대분류 선택: $_selectedCategory',
                  child: Row(
                    children: const [
                      Icon(Icons.help_outline, size: 20),
                      SizedBox(width: 4),
                      Text('대분류 힌트'),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // 확정 버튼
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // 선택된 대분류/세부분류를 넘기고 페이지 닫기
                  Navigator.pop<Map<String, String>>(
                    context,
                    {
                      'category': _selectedCategory,
                      'subcategory': _selectedSubcategory,
                    },
                  );
                },
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
