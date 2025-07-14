import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'download_utils.io.dart' if (dart.library.html) 'download_utils.web.dart' as platform_download;

Future<void> downloadZipFile(Uint8List zipData, String fileName) {
  return platform_download.downloadZipFile(zipData, fileName);
}
