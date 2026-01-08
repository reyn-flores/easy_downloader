import 'dart:io';

import 'package:downloadsfolder/downloadsfolder.dart' as downloadsfolder;
import 'package:easy_downloader/src/enums/file_type.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// Helper class for saving downloaded files to appropriate locations.
class FileSaver {
  /// Get temporary directory path for downloads
  static Future<String> getTempPath(String filename) async {
    final tempDir = await getTemporaryDirectory();
    return '${tempDir.path}/$filename';
  }

  /// Save file to final destination based on file type.
  /// Returns the saved path or location description.
  static Future<String> saveFile({
    required String tempPath,
    required String filename,
    required FileType fileType,
  }) async {
    final file = File(tempPath);

    switch (fileType) {
      case FileType.image:
        await Gal.putImageBytes(file.readAsBytesSync(), name: filename);
        return 'Gallery';

      case FileType.video:
        await Gal.putVideo(tempPath);
        return 'Gallery';

      case FileType.document:
      case FileType.pdf:
      case FileType.audio:
      case FileType.unknown:
        if (Platform.isAndroid) {
          await downloadsfolder.copyFileIntoDownloadFolder(tempPath, filename);
          return 'Downloads';
        } else if (Platform.isIOS) {
          final documentsDir = await getApplicationDocumentsDirectory();
          final savedPath = '${documentsDir.path}/$filename';
          await file.copy(savedPath);
          return savedPath;
        }
        return tempPath;
    }
  }

  /// Clean up temporary file
  static Future<void> cleanupTempFile(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
    } on Exception catch (_) {
      // Ignore cleanup errors
    }
  }
}
