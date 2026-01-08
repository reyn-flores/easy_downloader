import 'package:dio/dio.dart';
import 'package:easy_flutter_downloader/easy_flutter_downloader.dart';
import 'package:test/test.dart';

void main() {
  group('DownloadTask', () {
    late DownloadTask task;

    setUp(() {
      task = DownloadTask(
        id: 'test-id',
        url: 'https://example.com/file.pdf',
        filename: 'test.pdf',
        fileType: FileType.pdf,
        cancelToken: CancelToken(),
      );
    });

    test('should create with default values', () {
      expect(task.status, DownloadStatus.queued);
      expect(task.progress, 0);
      expect(task.receivedBytes, 0);
      expect(task.totalBytes, 0);
      expect(task.error, isNull);
      expect(task.savedPath, isNull);
    });

    test('isTerminal returns correct values', () {
      expect(task.isTerminal, isFalse); // queued
      expect(
        task.copyWith(status: DownloadStatus.downloading).isTerminal,
        isFalse,
      );
      expect(
        task.copyWith(status: DownloadStatus.completed).isTerminal,
        isTrue,
      );
      expect(task.copyWith(status: DownloadStatus.failed).isTerminal, isTrue);
      expect(
        task.copyWith(status: DownloadStatus.cancelled).isTerminal,
        isTrue,
      );
    });

    test('isActive returns correct values', () {
      expect(task.isActive, isTrue); // queued
      expect(
        task.copyWith(status: DownloadStatus.downloading).isActive,
        isTrue,
      );
      expect(task.copyWith(status: DownloadStatus.completed).isActive, isFalse);
      expect(task.copyWith(status: DownloadStatus.failed).isActive, isFalse);
      expect(task.copyWith(status: DownloadStatus.cancelled).isActive, isFalse);
    });

    test('progressText returns correct values for each status', () {
      expect(task.progressText, 'Queued');
      expect(
        task.copyWith(status: DownloadStatus.completed).progressText,
        'Completed',
      );
      expect(
        task.copyWith(status: DownloadStatus.cancelled).progressText,
        'Cancelled',
      );
      expect(
        task.copyWith(status: DownloadStatus.failed).progressText,
        'Failed',
      );
      expect(
        task
            .copyWith(status: DownloadStatus.failed, error: 'Network error')
            .progressText,
        'Network error',
      );
      expect(
        task
            .copyWith(
              status: DownloadStatus.downloading,
              receivedBytes: 1024,
              totalBytes: 2048,
            )
            .progressText,
        '1.00 KB / 2.00 KB',
      );
    });

    test('progressPercentage returns correct values', () {
      expect(task.progressPercentage, '0%');
      expect(task.copyWith(progress: 0.5).progressPercentage, '50%');
      expect(task.copyWith(progress: 1).progressPercentage, '100%');
    });

    test('copyWith creates new instance with updated values', () {
      final updated = task.copyWith(
        status: DownloadStatus.downloading,
        progress: 0.5,
        receivedBytes: 500,
        totalBytes: 1000,
      );

      expect(updated.id, task.id);
      expect(updated.url, task.url);
      expect(updated.filename, task.filename);
      expect(updated.status, DownloadStatus.downloading);
      expect(updated.progress, 0.5);
      expect(updated.receivedBytes, 500);
      expect(updated.totalBytes, 1000);
    });
  });

  group('FileTypeFromExtension', () {
    test('returns pdf for .pdf extension', () {
      expect('document.pdf'.toFileTypeFromExtension(), FileType.pdf);
      expect('FILE.PDF'.toFileTypeFromExtension(), FileType.pdf);
    });

    test('returns image for image extensions', () {
      expect('photo.jpg'.toFileTypeFromExtension(), FileType.image);
      expect('photo.jpeg'.toFileTypeFromExtension(), FileType.image);
      expect('photo.png'.toFileTypeFromExtension(), FileType.image);
      expect('photo.gif'.toFileTypeFromExtension(), FileType.image);
      expect('photo.webp'.toFileTypeFromExtension(), FileType.image);
      expect('photo.heic'.toFileTypeFromExtension(), FileType.image);
    });

    test('returns video for video extensions', () {
      expect('video.mp4'.toFileTypeFromExtension(), FileType.video);
      expect('video.mov'.toFileTypeFromExtension(), FileType.video);
      expect('video.avi'.toFileTypeFromExtension(), FileType.video);
      expect('video.mkv'.toFileTypeFromExtension(), FileType.video);
    });

    test('returns audio for audio extensions', () {
      expect('song.mp3'.toFileTypeFromExtension(), FileType.audio);
      expect('song.wav'.toFileTypeFromExtension(), FileType.audio);
      expect('song.flac'.toFileTypeFromExtension(), FileType.audio);
      expect('song.m4a'.toFileTypeFromExtension(), FileType.audio);
    });

    test('returns document for document extensions', () {
      expect('file.doc'.toFileTypeFromExtension(), FileType.document);
      expect('file.docx'.toFileTypeFromExtension(), FileType.document);
      expect('file.txt'.toFileTypeFromExtension(), FileType.document);
      expect('file.xlsx'.toFileTypeFromExtension(), FileType.document);
      expect('file.pptx'.toFileTypeFromExtension(), FileType.document);
    });

    test('returns unknown for unrecognized extensions', () {
      expect('file.xyz'.toFileTypeFromExtension(), FileType.unknown);
      expect('file.abc'.toFileTypeFromExtension(), FileType.unknown);
      expect('noextension'.toFileTypeFromExtension(), FileType.unknown);
    });
  });

  group('DownloaderState', () {
    late List<DownloadTask> tasks;

    setUp(() {
      tasks = [
        DownloadTask(
          id: '1',
          url: 'https://example.com/1.pdf',
          filename: 'file1.pdf',
          fileType: FileType.pdf,
          cancelToken: CancelToken(),
          tag: 'tag1',
        ),
        DownloadTask(
          id: '2',
          url: 'https://example.com/2.jpg',
          filename: 'file2.jpg',
          fileType: FileType.image,
          cancelToken: CancelToken(),
          status: DownloadStatus.downloading,
          tag: 'tag1',
        ),
        DownloadTask(
          id: '3',
          url: 'https://example.com/3.mp4',
          filename: 'file3.mp4',
          fileType: FileType.video,
          cancelToken: CancelToken(),
          status: DownloadStatus.completed,
          tag: 'tag2',
        ),
        DownloadTask(
          id: '4',
          url: 'https://example.com/4.txt',
          filename: 'file4.txt',
          fileType: FileType.document,
          cancelToken: CancelToken(),
          status: DownloadStatus.failed,
        ),
      ];
    });

    test('should create with empty list by default', () {
      const state = DownloaderState();
      expect(state.downloadTasks, isEmpty);
    });

    test('activeDownloads returns only queued and downloading tasks', () {
      final state = DownloaderState(downloadTasks: tasks);
      final active = state.activeDownloads;

      expect(active.length, 2);
      expect(active.any((t) => t.id == '1'), isTrue);
      expect(active.any((t) => t.id == '2'), isTrue);
    });

    test('completedDownloads returns only completed tasks', () {
      final state = DownloaderState(downloadTasks: tasks);
      expect(state.completedDownloads.length, 1);
      expect(state.completedDownloads.first.id, '3');
    });

    test('failedDownloads returns only failed tasks', () {
      final state = DownloaderState(downloadTasks: tasks);
      expect(state.failedDownloads.length, 1);
      expect(state.failedDownloads.first.id, '4');
    });

    test('getDownloadsByTag returns tasks with matching tag', () {
      final state = DownloaderState(downloadTasks: tasks);

      expect(state.getDownloadsByTag('tag1').length, 2);
      expect(state.getDownloadsByTag('tag2').length, 1);
      expect(state.getDownloadsByTag(null).length, 1);
    });

    test('getDownloadById returns correct task or null', () {
      final state = DownloaderState(downloadTasks: tasks);

      expect(state.getDownloadById('2')?.filename, 'file2.jpg');
      expect(state.getDownloadById('non-existent'), isNull);
    });

    test('hasActiveDownloads returns correct value', () {
      final state = DownloaderState(downloadTasks: tasks);
      expect(state.hasActiveDownloads, isTrue);

      final completedState = DownloaderState(
        downloadTasks: [
          DownloadTask(
            id: '1',
            url: 'https://example.com/1.pdf',
            filename: 'file1.pdf',
            fileType: FileType.pdf,
            cancelToken: CancelToken(),
            status: DownloadStatus.completed,
          ),
        ],
      );
      expect(completedState.hasActiveDownloads, isFalse);
    });

    test('currentDownload returns downloading task or null', () {
      final state = DownloaderState(downloadTasks: tasks);
      expect(state.currentDownload?.id, '2');

      const emptyState = DownloaderState();
      expect(emptyState.currentDownload, isNull);
    });
  });
}
