import 'package:dio/dio.dart';
import 'package:easy_downloader/src/enums/download_status.dart';
import 'package:easy_downloader/src/enums/file_type.dart';
import 'package:equatable/equatable.dart';

/// Represents a single download task with its state.
class DownloadTask extends Equatable {
  const DownloadTask({
    required this.id,
    required this.url,
    required this.filename,
    required this.fileType,
    required this.cancelToken,
    this.postData,
    this.tag,
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.error,
    this.savedPath,
  });

  /// Unique identifier for this download
  final String id;

  /// URL to download from
  final String url;

  /// Filename for the downloaded file
  final String filename;

  /// Type of file being downloaded
  final FileType fileType;

  /// Cancel token for this download
  final CancelToken cancelToken;

  /// Optional POST data for the download request
  final Map<String, dynamic>? postData;

  /// Optional tag to group downloads (e.g., page identifier)
  final String? tag;

  /// Current status of the download
  final DownloadStatus status;

  /// Download progress (0.0 to 1.0)
  final double progress;

  /// Bytes received so far
  final int receivedBytes;

  /// Total bytes to download
  final int totalBytes;

  /// Error message if download failed
  final String? error;

  /// Path where the file was saved (available after completion)
  final String? savedPath;

  /// Returns true if download is in a terminal state
  bool get isTerminal =>
      status == DownloadStatus.completed ||
      status == DownloadStatus.failed ||
      status == DownloadStatus.cancelled;

  /// Returns true if download is active (queued or downloading)
  bool get isActive =>
      status == DownloadStatus.queued || status == DownloadStatus.downloading;

  /// Returns formatted progress text
  String get progressText {
    switch (status) {
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.downloading:
        return '${_formatBytes(receivedBytes)} / ${_formatBytes(totalBytes)}';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return error ?? 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Returns progress percentage as string
  String get progressPercentage => '${(progress * 100).toStringAsFixed(0)}%';

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '$bytes B';
  }

  DownloadTask copyWith({
    String? id,
    String? url,
    String? filename,
    FileType? fileType,
    CancelToken? cancelToken,
    Map<String, dynamic>? postData,
    String? tag,
    DownloadStatus? status,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    String? error,
    String? savedPath,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      filename: filename ?? this.filename,
      fileType: fileType ?? this.fileType,
      cancelToken: cancelToken ?? this.cancelToken,
      postData: postData ?? this.postData,
      tag: tag ?? this.tag,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error ?? this.error,
      savedPath: savedPath ?? this.savedPath,
    );
  }

  @override
  List<Object?> get props => [
    id,
    url,
    filename,
    fileType,
    postData,
    tag,
    status,
    progress,
    receivedBytes,
    totalBytes,
    error,
    savedPath,
  ];
}
