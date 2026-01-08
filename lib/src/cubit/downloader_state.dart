part of 'downloader_cubit.dart';

/// State class for the DownloaderCubit.
class DownloaderState extends Equatable {
  const DownloaderState({this.downloadTasks = const []});

  /// List of all download tasks
  final List<DownloadTask> downloadTasks;

  /// Get all active downloads
  List<DownloadTask> get activeDownloads =>
      downloadTasks.where((d) => d.isActive).toList();

  /// Get all completed downloads
  List<DownloadTask> get completedDownloads =>
      downloadTasks.where((d) => d.status == DownloadStatus.completed).toList();

  /// Get all failed downloads
  List<DownloadTask> get failedDownloads =>
      downloadTasks.where((d) => d.status == DownloadStatus.failed).toList();

  /// Get downloads by tag
  List<DownloadTask> getDownloadsByTag(String? tag) =>
      downloadTasks.where((d) => d.tag == tag).toList();

  /// Get a specific download by ID
  DownloadTask? getDownloadById(String id) {
    return downloadTasks.where((d) => d.id == id).firstOrNull;
  }

  /// Check if there are any active downloads
  bool get hasActiveDownloads => activeDownloads.isNotEmpty;

  /// Get the count of active downloads
  int get activeDownloadCount => activeDownloads.length;

  /// Get the current download (the one being processed)
  DownloadTask? get currentDownload {
    try {
      return downloadTasks.firstWhere(
        (d) => d.status == DownloadStatus.downloading,
      );
    } on Exception catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [downloadTasks];

  DownloaderState copyWith({List<DownloadTask>? downloadTasks}) {
    return DownloaderState(downloadTasks: downloadTasks ?? this.downloadTasks);
  }
}
