import 'package:equatable/equatable.dart';

/// A class to represent the progress of a file transfer operation
class Progress extends Equatable {
  /// Creates a new instance of [Progress] with the given parameters
  const Progress({
    this.transfer = 0,
    this.total = 1,
    this.elapsed = Duration.zero,
  });

  /// The amount of data transferred so far, in bytes
  final int transfer;

  /// The total amount of data to be transferred, in bytes
  final int total;

  /// The elapsed time since the transfer started
  final Duration elapsed;

  /// A human-readable string representing the current progress of the transfer
  String get progressText {
    final receivedText = _formatDataSize(transfer);
    final totalText = _formatDataSize(total);
    return '$receivedText/$totalText';
  }

  /// Calculates the progress as a percentage (0.0 to 1.0)
  double get progress => total > 0 ? transfer / total : 0.0;

  /// Calculates the download speed in bytes per second
  double get speedBytesPerSecond {
    if (elapsed.inMilliseconds == 0) return 0;
    return transfer / (elapsed.inMilliseconds / 1000);
  }

  /// Returns a human-readable speed string
  String get speedText {
    final speed = speedBytesPerSecond;
    if (speed <= 0) return '0 B/s';
    return '${_formatDataSize(speed.toInt())}/s';
  }

  /// Estimates the remaining time for the transfer to complete
  String get timeRemaining {
    if (elapsed.inSeconds == 0 || transfer == 0) {
      return 'Calculating...';
    }

    final speed = transfer / elapsed.inSeconds;

    if (speed <= 0) {
      return 'Calculating...';
    }

    final remainingTimeInSec = (total - transfer) / speed;
    return _formatTimeRemaining(
      remainingTimeInSec > 0 ? remainingTimeInSec.floor() : 0,
    );
  }

  String _formatTimeRemaining(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;

    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final secs = safeSeconds % 60;

    final parts = <String>[
      if (hours > 0) _formatUnit(hours, 'hour'),
      if (minutes > 0) _formatUnit(minutes, 'min'),
      if (secs > 0) _formatUnit(secs, 'sec'),
    ];

    if (parts.isEmpty) return '0 secs left';

    final topTwo = parts.take(2).toList();
    if (topTwo.length == 1) return '${topTwo[0]} left';
    return '${topTwo[0]} and ${topTwo[1]} left';
  }

  String _formatUnit(int value, String unit) {
    return '$value $unit${value == 1 ? '' : 's'}';
  }

  String _formatDataSize(int sizeInBytes) {
    if (sizeInBytes >= 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
    } else if (sizeInBytes >= 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)}MB';
    } else if (sizeInBytes >= 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(2)}KB';
    }
    return '${sizeInBytes}B';
  }

  Progress copyWith({int? transfer, int? total, Duration? elapsed}) {
    return Progress(
      transfer: transfer ?? this.transfer,
      total: total ?? this.total,
      elapsed: elapsed ?? this.elapsed,
    );
  }

  @override
  List<Object?> get props => [transfer, total, elapsed];
}
