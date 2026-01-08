/// Enum representing the type of file being downloaded.
/// This determines how the file will be saved after download.
enum FileType {
  /// For DOCs, TXT, etc. - saved to Downloads/Documents folder
  document,

  /// For PDFs - saved to Downloads/Documents folder
  pdf,

  /// For JPG, PNG, etc. - saved to gallery
  image,

  /// For MP4, MOV, etc. - saved to gallery
  video,

  /// For MP3, WAV, etc. - saved to Downloads/Documents folder
  audio,

  /// For unknown types - saved to Downloads/Documents folder
  unknown,
}
