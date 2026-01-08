
# Easy Downloader

[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A Flutter plugin for easy file downloading with queue management, progress tracking, and automatic file saving to gallery or downloads folder.

## Features

- 🔄 **Queue-based downloads** - Downloads processed one at a time to prevent overwhelming the device
- 📊 **Progress tracking** - Real-time progress updates with bytes received/total
- 📁 **Smart file saving** - Automatically saves to the appropriate location based on file type
- 🏷️ **Tag support** - Group and manage downloads by tags
- ❌ **Cancellation** - Cancel single downloads, by tag, or all at once
- 🔁 **Retry support** - Easily retry failed or cancelled downloads
- 📱 **Platform-aware** - Works on both Android and iOS

## File Type Handling

| File Type | Android | iOS |
|-----------|---------|-----|
| Images | Gallery | Gallery |
| Videos | Gallery | Gallery |
| Documents | Downloads folder | Documents folder |
| PDFs | Downloads folder | Documents folder |
| Audio | Downloads folder | Documents folder |

## Getting Started

### Installation

Add `easy_downloader` to your `pubspec.yaml`:

```yaml
dependencies:
  easy_downloader: ^0.0.1
```

### Platform Setup

#### Android

Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29"/>
```

#### iOS

Add the following to your `Info.plist` for saving to gallery:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save downloaded images and videos to your gallery.</string>
```

To make downloaded files visible in the iOS Files app, also add:

```xml
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

## Usage

### Setup

Provide the `DownloaderCubit` at the top of your widget tree:

```dart
import 'package:dio/dio.dart';
import 'package:easy_downloader/easy_downloader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(
    BlocProvider(
      create: (context) => DownloaderCubit(dio: Dio()),
      child: MyApp(),
    ),
  );
}
```

### Start a Download

```dart
context.read<DownloaderCubit>().addDownloadTask(
  url: 'https://example.com/document.pdf',
  filename: 'my_document.pdf',
  fileType: FileType.pdf,
  tag: 'invoices', // Optional: group downloads
);
```

### Track Downloads

```dart
BlocBuilder<DownloaderCubit, DownloaderState>(
  builder: (context, state) {
    return ListView.builder(
      itemCount: state.downloadTasks.length,
      itemBuilder: (context, index) {
        final task = state.downloadTasks[index];
        return ListTile(
          title: Text(task.filename),
          subtitle: Text(task.progressText),
          trailing: _buildTrailingWidget(task),
        );
      },
    );
  },
)
```

### Cancel Downloads

```dart
// Cancel a single download
context.read<DownloaderCubit>().cancelDownload(taskId);

// Cancel all downloads with a specific tag
context.read<DownloaderCubit>().cancelDownloadsByTag('invoices');

// Cancel all downloads
context.read<DownloaderCubit>().cancelAllDownloads();
```

### Retry a Download

```dart
context.read<DownloaderCubit>().retryDownload(taskId);
```

### Check Progress by Tag

```dart
final progress = context.read<DownloaderCubit>().getCollectiveProgressByTag('invoices');
final hasOngoing = context.read<DownloaderCubit>().hasOngoingDownloadsByTag('invoices');
```

### Clean Up

```dart
// Remove completed downloads from the list
context.read<DownloaderCubit>().clearCompletedDownloads();

// Remove all terminal downloads (completed, failed, cancelled)
context.read<DownloaderCubit>().clearTerminalDownloads();
```

## Download Status

Each download task has one of the following statuses:

| Status | Description |
|--------|-------------|
| `queued` | Waiting in queue to start |
| `downloading` | Currently downloading |
| `completed` | Successfully downloaded and saved |
| `failed` | Download failed (can be retried) |
| `cancelled` | Cancelled by user (can be retried) |

## Additional Information

### Dependencies

This package uses the following dependencies:

- [dio](https://pub.dev/packages/dio) - HTTP client for downloads
- [flutter_bloc](https://pub.dev/packages/flutter_bloc) - State management
- [gal](https://pub.dev/packages/gal) - Save images/videos to gallery
- [downloadsfolder](https://pub.dev/packages/downloadsfolder) - Access downloads folder on Android
- [path_provider](https://pub.dev/packages/path_provider) - Access file system paths

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Issues

If you encounter any issues, please file them on the [issue tracker](https://github.com/YOUR_USERNAME/easy_downloader/issues).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.