import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:easy_downloader/src/enums/download_status.dart';
import 'package:easy_downloader/src/enums/file_type.dart';
import 'package:easy_downloader/src/helpers/file_saver.dart';
import 'package:easy_downloader/src/helpers/filename_helper.dart';
import 'package:easy_downloader/src/models/download_task.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

part 'downloader_state.dart';

/// A Cubit for managing file downloads with a queue-based approach.
///
/// Downloads are processed one at a time to prevent overwhelming the device.
/// Downloads with the same tag are grouped together in the queue.
///
/// Example usage in app.dart:
/// ```dart
/// MultiBlocProvider(
///   providers: [
///     BlocProvider(
///       create: (context) => DownloaderCubit(dio: Injector.get<Dio>()),
///     ),
///   ],
///   child: MaterialApp(...),
/// )
/// ```
///
/// Example usage in UI:
/// ```dart
/// // Start a download
/// context.read<DownloaderCubit>().addDownloadTask(
///   url: 'https://example.com/file.pdf',
///   filename: 'document.pdf',
///   fileType: FileType.pdf,
///   tag: 'my_page', // Optional: group downloads
/// );
///
/// // Observe downloads
/// BlocBuilder<DownloaderCubit, DownloaderState>(
///   builder: (context, state) {
///     final downloads = state.downloadTasks;
///     return ListView.builder(
///       itemCount: downloads.length,
///       itemBuilder: (context, index) {
///         final task = downloads[index];
///         return DownloadTile(task: task);
///       },
///     );
///   },
/// )
/// ```
class DownloaderCubit extends Cubit<DownloaderState> {
  DownloaderCubit({required Dio dio})
    : _dio = dio,
      super(const DownloaderState());

  final Dio _dio;
  final _uuid = const Uuid();

  /// Flag to track if a download is currently in progress
  bool _isDownloading = false;

  /// Queue for pending download tasks
  final Queue<DownloadTask> _queue = Queue<DownloadTask>();

  /// Add a new download task to the queue.
  ///
  /// The download will be processed when previous downloads complete.
  /// Downloads with the same tag are grouped together.
  void addDownloadTask({
    required String url,
    required String filename,
    required FileType fileType,
    Map<String, dynamic>? postData,
    String? tag,
  }) {
    final task = DownloadTask(
      id: _uuid.v4(),
      url: url,
      filename: filename,
      fileType: fileType,
      postData: postData,
      tag: tag,
      cancelToken: CancelToken(),
    );

    // Add to state
    _safeEmit(state.copyWith(downloadTasks: [...state.downloadTasks, task]));

    // Add to queue (insert based on tag grouping)
    _enqueueTask(task);

    // Start processing
    unawaited(_processQueue());
  }

  /// Enqueue task
  void _enqueueTask(DownloadTask task) {
    _queue.addLast(task);
  }

  /// Process the download queue one task at a time.
  Future<void> _processQueue() async {
    if (_isDownloading || _queue.isEmpty) return;

    _isDownloading = true;
    final task = _queue.removeFirst();

    await _processDownload(task);

    _isDownloading = false;
    unawaited(_processQueue());
  }

  /// Process a single download task.
  Future<void> _processDownload(DownloadTask task) async {
    final preparedFilename = FilenameHelper.prepareFilename(
      task.filename,
      task.fileType,
    );
    final tempPath = await FileSaver.getTempPath(preparedFilename);

    try {
      // Update status to downloading
      _updateTask(task.id, status: DownloadStatus.downloading);

      // Perform the download
      await _dio.download(
        task.url,
        tempPath,
        options: Options(
          method: task.postData != null ? 'POST' : 'GET',
          headers: {'Content-Type': 'application/json'},
        ),
        data: task.postData,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            _updateTask(
              task.id,
              progress: progress,
              receivedBytes: received,
              totalBytes: total,
            );
          }
        },
        cancelToken: task.cancelToken,
      );

      // Save file to final destination
      final savedPath = await FileSaver.saveFile(
        tempPath: tempPath,
        filename: preparedFilename,
        fileType: task.fileType,
      );

      // Update status to completed
      _updateTask(
        task.id,
        status: DownloadStatus.completed,
        progress: 1,
        savedPath: savedPath,
      );

      // Clean up temp file
      unawaited(FileSaver.cleanupTempFile(tempPath));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        _updateTask(task.id, status: DownloadStatus.cancelled);
      } else {
        _updateTask(
          task.id,
          status: DownloadStatus.failed,
          error: e.message ?? 'Download failed',
        );
      }
    } on Exception catch (e) {
      _updateTask(task.id, status: DownloadStatus.failed, error: e.toString());
    }
  }

  /// Update a task in the state.
  void _updateTask(
    String taskId, {
    DownloadStatus? status,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    String? error,
    String? savedPath,
  }) {
    final tasks = [...state.downloadTasks];
    final taskIndex = tasks.indexWhere((t) => t.id == taskId);

    if (taskIndex != -1) {
      tasks[taskIndex] = tasks[taskIndex].copyWith(
        status: status,
        progress: progress ?? tasks[taskIndex].progress,
        receivedBytes: receivedBytes ?? tasks[taskIndex].receivedBytes,
        totalBytes: totalBytes ?? tasks[taskIndex].totalBytes,
        error: error,
        savedPath: savedPath,
      );
      _safeEmit(state.copyWith(downloadTasks: tasks));
    }
  }

  /// Remove a task from state and queue.
  void _removeTask(String taskId) {
    // Remove from state
    final tasks = [...state.downloadTasks]..removeWhere((t) => t.id == taskId);
    _safeEmit(state.copyWith(downloadTasks: tasks));

    // Remove from queue
    _queue.removeWhere((t) => t.id == taskId);
  }

  /// Cancel a download task.
  void cancelDownload(String taskId) {
    final task = state.getDownloadById(taskId);
    if (task == null) return;

    switch (task.status) {
      case DownloadStatus.downloading:
        // Cancel the actual download
        task.cancelToken.cancel();
      case DownloadStatus.queued:
        // Remove from queue and state
        _removeTask(taskId);
      case DownloadStatus.completed:
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        // Already terminal, just remove from state
        _removeTask(taskId);
    }
  }

  /// Cancel all downloads with a specific tag.
  void cancelDownloadsByTag(String tag) {
    final tasksToCancel = state.getDownloadsByTag(tag);
    for (final task in tasksToCancel) {
      cancelDownload(task.id);
    }
  }

  /// Cancel all active downloads.
  void cancelAllDownloads() {
    for (final task in state.downloadTasks) {
      if (task.isActive) {
        cancelDownload(task.id);
      }
    }
  }

  /// Retry a failed or cancelled download.
  void retryDownload(String taskId) {
    final task = state.getDownloadById(taskId);
    if (task == null) return;

    if (task.status != DownloadStatus.failed &&
        task.status != DownloadStatus.cancelled) {
      return;
    }

    // Remove the old task
    _removeTask(taskId);

    // Create a new download with the same parameters
    addDownloadTask(
      url: task.url,
      filename: task.filename,
      fileType: task.fileType,
      postData: task.postData,
      tag: task.tag,
    );
  }

  /// Remove a completed/failed/cancelled download from the list.
  void removeDownload(String taskId) {
    final task = state.getDownloadById(taskId);
    if (task != null && task.isTerminal) {
      _removeTask(taskId);
    }
  }

  /// Remove all completed downloads.
  void clearCompletedDownloads() {
    final tasks = state.downloadTasks.where((t) => !t.isTerminal).toList();
    _safeEmit(state.copyWith(downloadTasks: tasks));
  }

  /// Remove all terminal downloads (completed, failed, cancelled).
  void clearTerminalDownloads() {
    final tasks = state.downloadTasks.where((t) => t.isActive).toList();
    _safeEmit(state.copyWith(downloadTasks: tasks));
  }

  /// Get download tasks filtered by tag.
  List<DownloadTask> getDownloadTasks(String? tag) {
    return state.getDownloadsByTag(tag);
  }

  /// Check if a tag has any ongoing downloads (queued or downloading).
  bool hasOngoingDownloadsByTag(String? tag) {
    return state.downloadTasks.any((d) => d.tag == tag && d.isActive);
  }

  /// Get the collective progress (0.0 to 1.0) of all downloads under a tag.
  /// Returns 0.0 if there are no downloads for the tag.
  double getCollectiveProgressByTag(String? tag) {
    final taggedDownloads = state.getDownloadsByTag(tag);
    if (taggedDownloads.isEmpty) return 0;

    final totalProgress = taggedDownloads.fold<double>(
      0,
      (sum, task) => sum + task.progress,
    );

    return totalProgress / taggedDownloads.length;
  }

  /// Safely emit state only if cubit is not closed.
  void _safeEmit(DownloaderState newState) {
    if (!isClosed) {
      emit(newState);
    }
  }

  @override
  Future<void> close() {
    // Cancel all active downloads before closing
    cancelAllDownloads();
    return super.close();
  }
}
