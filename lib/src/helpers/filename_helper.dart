import 'dart:io';

import 'package:easy_flutter_downloader/src/enums/file_type.dart';
import 'package:uuid/uuid.dart';

/// Helper class for preparing filenames for downloads.
class FilenameHelper {
  static const _uuid = Uuid();

  /// Prepare filename with proper extension and unique suffix for Android.
  static String prepareFilename(String filename, FileType fileType) {
    var result = filename;

    // Add extension if needed
    if (fileType == FileType.pdf && !result.endsWith('.pdf')) {
      result = '$result.pdf';
    }

    // Add unique suffix for Android to avoid conflicts
    if (Platform.isAndroid) {
      final extension = result.contains('.') ? result.split('.').last : '';
      final baseName = result.contains('.')
          ? result.substring(0, result.lastIndexOf('.'))
          : result;
      final uniqueId = _uuid.v4().substring(0, 8);
      result = extension.isNotEmpty
          ? '$baseName-$uniqueId.$extension'
          : '$baseName-$uniqueId';
    }

    return result;
  }
}
