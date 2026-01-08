/// Enum representing the status of a download.
enum DownloadStatus {
  /// Download is queued and waiting to start
  queued,

  /// Download is in progress
  downloading,

  /// Download completed successfully
  completed,

  /// Download failed due to an error
  failed,

  /// Download was cancelled by user
  cancelled,
}
