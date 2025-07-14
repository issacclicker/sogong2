import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadZipFile(Uint8List zipData, String fileName) async {
  final blob = html.Blob([zipData]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
