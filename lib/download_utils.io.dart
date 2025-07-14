import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadZipFile(Uint8List zipData, String fileName) async {
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(zipData);

  await Share.shareXFiles([XFile(filePath, mimeType: 'application/zip')], subject: 'ZIP File');
}
