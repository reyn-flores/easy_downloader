import 'package:easy_downloader/src/enums/file_type.dart';

/// Extension to convert from file extension to [FileType].
extension FileTypeFromExtension on String {
  /// Converts a filename or extension to [FileType].
  ///
  /// Example:
  /// ```dart
  /// 'document.pdf'.toFileTypeFromExtension() // FileType.pdf
  /// '.jpg'.toFileTypeFromExtension() // FileType.image
  /// ```
  FileType toFileTypeFromExtension() {
    final ext = toLowerCase().split('.').last;

    // PDFs
    if (ext == 'pdf') {
      return FileType.pdf;
    }

    // Images
    if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'heic',
      'heif',
      'svg',
    ].contains(ext)) {
      return FileType.image;
    }

    // Videos
    if ([
      'mp4',
      'mov',
      'avi',
      'mkv',
      'webm',
      'flv',
      'wmv',
      'm4v',
    ].contains(ext)) {
      return FileType.video;
    }

    // Audio
    if (['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a', 'wma'].contains(ext)) {
      return FileType.audio;
    }

    // Documents
    if ([
      'doc',
      'docx',
      'txt',
      'rtf',
      'odt',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
    ].contains(ext)) {
      return FileType.document;
    }

    return FileType.unknown;
  }
}
