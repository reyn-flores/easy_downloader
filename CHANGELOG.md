# Changelog

All notable changes to this project will be documented in this file.

## 0.0.1

### Added

- Initial release of Easy Downloader
- `DownloaderCubit` for BLoC-based download state management
- Queue-based download processing (one download at a time)
- Download progress tracking with bytes received/total
- Support for multiple file types: documents, PDFs, images, videos, and audio
- Smart file saving:
  - Images and videos saved to device gallery
  - Documents, PDFs, and audio saved to Downloads folder (Android) or Documents (iOS)
- Download cancellation support (single, by tag, or all)
- Retry failed/cancelled downloads
- Tag-based grouping for download organization
- Collective progress tracking by tag
- Support for GET and POST download requests
- Automatic temporary file cleanup after successful downloads

## 1.0.2

### Added

- Created a Progress class for refined progress details ie: progress text, speed, time remaining 