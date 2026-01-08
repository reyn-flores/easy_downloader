import 'package:dio/dio.dart';
import 'package:easy_flutter_downloader/easy_flutter_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DownloaderCubit(dio: Dio()),
      child: MaterialApp(
        title: 'Easy Downloader Example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const DownloadExamplePage(),
      ),
    );
  }
}

class DownloadExamplePage extends StatelessWidget {
  const DownloadExamplePage({super.key});

  /// Sample files for testing downloads
  /// https://sample-files.com/documents/pdf/
  /// Note: Open the files in a browser to verify they are accessible.
  static const _sampleFiles = [
    _SampleFile(
      name: 'Sample PDF',
      url: 'https://sample-files.com/downloads/documents/pdf/sample-report.pdf',
      filename: 'sample_document.pdf',
      fileType: FileType.pdf,
      icon: Icons.picture_as_pdf,
    ),
    _SampleFile(
      name: 'Sample Image',
      url:
          'https://sample-files.com/downloads/images/jpg/color_test_800x600_118kb.jpg',
      filename: 'sample_image.jpg',
      fileType: FileType.image,
      icon: Icons.image,
    ),
    _SampleFile(
      name: 'Sample Text',
      url: 'https://sample-files.com/downloads/documents/txt/simple.txt',
      filename: 'sample_text.txt',
      fileType: FileType.document,
      icon: Icons.description,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Easy Downloader'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear completed',
            onPressed: () {
              context.read<DownloaderCubit>().clearTerminalDownloads();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Download buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tap to download:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sampleFiles.map((file) {
                    return ElevatedButton.icon(
                      onPressed: () => _startDownload(context, file),
                      icon: Icon(file.icon),
                      label: Text(file.name),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _downloadAll(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Download All'),
                ),
              ],
            ),
          ),
          const Divider(),
          // Download list
          Expanded(
            child: BlocBuilder<DownloaderCubit, DownloaderState>(
              builder: (context, state) {
                if (state.downloadTasks.isEmpty) {
                  return const Center(
                    child: Text(
                      'No downloads yet.\nTap a button above to start.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: state.downloadTasks.length,
                  itemBuilder: (context, index) {
                    final task = state.downloadTasks[index];
                    return DownloadTaskTile(task: task);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _startDownload(BuildContext context, _SampleFile file) {
    context.read<DownloaderCubit>().addDownloadTask(
      url: file.url,
      filename: file.filename,
      fileType: file.fileType,
      tag: 'example',
    );
  }

  void _downloadAll(BuildContext context) {
    for (final file in _sampleFiles) {
      _startDownload(context, file);
    }
  }
}

class _SampleFile {
  const _SampleFile({
    required this.name,
    required this.url,
    required this.filename,
    required this.fileType,
    required this.icon,
  });

  final String name;
  final String url;
  final String filename;
  final FileType fileType;
  final IconData icon;
}

class DownloadTaskTile extends StatelessWidget {
  const DownloadTaskTile({required this.task, super.key});

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.filename,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.progressText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _buildActionButton(context),
              ],
            ),
            if (task.status == DownloadStatus.downloading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: task.progress),
            ],
            if (task.error != null) ...[
              const SizedBox(height: 8),
              Text(
                task.error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            if (task.savedPath != null) ...[
              const SizedBox(height: 4),
              Text(
                'Saved to: ${task.savedPath}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (task.status) {
      case DownloadStatus.queued:
        return const Icon(Icons.schedule, color: Colors.orange);
      case DownloadStatus.downloading:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case DownloadStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case DownloadStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
      case DownloadStatus.cancelled:
        return const Icon(Icons.cancel, color: Colors.grey);
    }
  }

  Widget _buildActionButton(BuildContext context) {
    final cubit = context.read<DownloaderCubit>();

    switch (task.status) {
      case DownloadStatus.queued:
      case DownloadStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => cubit.cancelDownload(task.id),
        );
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Retry',
              onPressed: () => cubit.retryDownload(task.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove',
              onPressed: () => cubit.removeDownload(task.id),
            ),
          ],
        );
      case DownloadStatus.completed:
        return IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Remove',
          onPressed: () => cubit.removeDownload(task.id),
        );
    }
  }
}
