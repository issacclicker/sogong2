import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<void> downloadZipFile(Uint8List zipData, String fileName) async {
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(zipData);

  // TODO: 실제 공유 기능 구현 (예: share_plus 패키지 사용)
  print('ZIP 파일이 $filePath에 저장되었습니다.');
}
