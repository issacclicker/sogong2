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

  final Map<String, String> _tipMap = {
    //영수증빙자료
    '매출 전표(오프라인 카드결제)' : '오프라인으로 카드결제시 발급되는 영수증입니다. 사업자정보, 거래내역, 거래날짜, 거래수단(카드번호)이 드러나야 합니다.',
    '카드 전표(온라인 카드결제)' : '카드로 결제된 거래에 대해 은행에서 발급받을 수 있는 영수증입니다. 사업자 정보, 거래날짜, 결제금액, 카드번호가 드러나야 합니다.',
    '이체증(계좌이체,본통장입금)' : '계좌이체 또는 무통장입금 시 발급되는 영수증입니다. 입/출금 계좌번호와 예금주명, 이체금액, 이체날짜, 수수료가 드러나야 합니다.',
    '현금영수증(현금결제)' : '오프라인으로 현금결제 시 발급되는 영수증입니다. 사업자정보, 거래내역, 거래날짜, 거래수단(소득공제 번호)가 드러나야 합니다.',
    '결제취소전표(취소시 발급되는 영수증)' : '결제가 취소된 경우 발급되는 영수증입니다. 사업자 정보, 거래금액, 거래날짜, 거래수단(카드번호)가 드러나야 합니다. 결산안에 환불 사유를 명시해야 합니다.',
    '거래내역서(거래명세표)' : '업체, 매장, 인터넷 구매 시 거래내역에 대해 알 수 있는 영수증입니다. 상호명, 사업자명, 사업자 직인(또는 서명), 거래내역, 거래날짜가 드러나야 합니다.',
    '간이영수증' : '매장에서 수기로 발급해주는 영수증입니다. 상호명, 사업자명, 사업자 직인(또는 서명), 거래내역, 거래날짜가 드러나야 합니다.',
    '카드전표' : '카드로 결제된 거래에 대해 은행에서 발급받을 수 있는 영수증입니다. 사업자 정보, 거래날짜, 결제금액, 카드번호가 드러나야 합니다.',
    //보충영수증빙자료
    '회비납부자명단':'수입자료 중 하나로 학생들을 대상으로 입금 받는 모든 학생회비에 대해 작성하는 문서입니다.',
    '참여자 명단':'행사에 참여한 학생들에 대한 명단입니다. 이름, 학번이 드러나야 합니다.',
    '상품수령명단(수령증)':'행사에서 상품을 증정하는 경우 상품을 받은 학생들에 대해 작성하는 문서입니다.',
    '보험가입증서':'행사 중 사고나 위험에 대비하기 위해 보험을 가입한 경우 보험 가입을증빙할 수 있는 문서입니다.',
    '보험가입자명단':'행사 중 사고나 위험에 대비하기 위해 보험을 가입한 경우 보험 가입 대상을 확인할 수 있는 문서입니다.',
    '수기증':'학생회에서 학생회, 학생회에서 학우에게 돈을 지급하는 경우 작성하는문서입니다. 지급금액, 지급사유, 지급날짜, 공급하는 자/공급받는 자에 대한 정보가 드러나야 합니다.',
    '차용증명서':'학생회 간의, 동아리연합회와 동아리 간의 돈의 차용에 대해 작성하는 문서입니다. 차용금액, 변제기일, 이자, 차용하게 된 사유, 지급방법, 채권자와 채무자의 정보, 서명, 작성일이 드러나야 합니다.',
    //기타증빙자료
    '사진':'모든 행사에는 1개 이상의 사진자료를 필수적으로 제출해야 합니다.',
    '공지사항':'행사 집행에 대한 사실을 모두에게 공고했다는 것을 증빙하는 자료입니다. 공지의 주체, 공지내용, 공지날짜가 드러나야 합니다.',
    '차등회비선정 증빙자료':'차등회비가 선정된 사유를 증빙할 수 있는 자료입니다. 예산안이나 회의록 등이 적절합니다.',
    '대리작성동의 증빙자료':'양식이 제공되는 자료를 당사자를 대신하여 작성하는 경우 해당 사실에 동의했음을 증빙하는 자료입니다. 구글폼이나 카카오톡 투표 등이 적절합니다.',
    '회비 잔여금동의 증빙자료':'회비잔여금 기준을 넘어 회비가 남은 경우 해당 잔여금에 대한 처리방법에 대해 동의한 자료입니다.',
    '상품선정 증빙자료':'상품을 선정한 사유에 대해 증빙할 수 있는 자료입니다. 행사의 목적을 벗어나 과도하게 높은 금액의 상품으로 선정된 경우에 한하여 제출합니다.',
    '당첨자선정 증빙자료':'행사별로 당첨자가 상품에 당첨된 사유에 대해 증빙할수 있는 자료입니다.',
    '입금계좌 증빙자료':'계좌이체를 통한 지출이 발생한 경우, 해당 지출의 입금처에 대한 증빙자료입니다.',
    '입금자명상이 증빙자료':'수입에서 입금자의 실명과 예금거래실적증명서 상 입금자명이 상이한 경우 제출하는 증빙자료입니다.',
    '축제 증빙자료':'축제 기획 및 수입/지출에 대한 사실을 증빙하는 자료입니다.',
    '사전답사 증빙자료':'사전답사 계획 및 지출에 대한 사실을 증빙하는 자료입니다.',
    '숙소선정 증빙자료':'숙소가 선정된 사유를 증빙할 수 있는 자료입니다. 회의록 등이 적절합니다.',
  };

  String _selectedCategory = '영수증빙자료';
  String _selectedSubcategory = '매출 전표(오프라인 카드결제)';
  final TextEditingController _customNameController = TextEditingController(); // 추가됨

  @override
  void dispose() {
    _customNameController.dispose(); // 추가됨
    super.dispose();
  }

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
                  _selectedSubcategory = _defaultOptions[v]!.first;
                });
              },
            ),
            const SizedBox(height: 20),

            // 2) 소분류 선택 드롭다운
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

            // 3) 힌트 영역
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 대분류 힌트 (영수증빙자료일 때 커스텀 텍스트)
                Row(
                  children: [
                    Icon(Icons.help_outline, size: 20),
                    const SizedBox(width: 4),
                    Text('이렇게 어떻게 해요?',),
                  ],
                ),
                const SizedBox(height: 10),
                // 추가 힌트: 배달
                Text('배달 : 영수증에 배달팁 명시 필수!'),
                const SizedBox(height: 10),
                // 추가 힌트: 결제취소
                Text('결제취소 : 취소시 발급되는 영수증 필수!'),
                const SizedBox(height: 20),
                // 세부 분류 힌트
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 4),
                    Flexible(
                      child:Text(_tipMap[_selectedSubcategory] ?? ''),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30), // 추가됨: 간격

            // 4) 사용자 지정 이름 입력 필드 // 추가됨
            const Text('카테고리 표시 이름 (선택 사항)'), // 추가됨
            TextField( // 추가됨
              controller: _customNameController,
              decoration: const InputDecoration(
                hintText: '예: 점심 식대 (교직원 식당)',
              ),
            ),

            const Spacer(),

            // 확정 버튼
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // 변경됨: 사용자 지정 이름 사용 로직 추가
                  final String displayName = _customNameController.text.isNotEmpty
                      ? _customNameController.text
                      : _selectedSubcategory;

                  Navigator.pop<Map<String, String>>(
                    context,
                    {
                      'category': _selectedCategory,
                      'subcategory': _selectedSubcategory, // 원래 소분류 이름
                      'displayName': displayName,        // 표시될 이름 (사용자 지정 또는 소분류)
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
