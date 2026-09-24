import 'package:intl/intl.dart';

/// Date & Time utilities tailored for field inspectors
class DateFormatter {
  DateFormatter._();

  static final DateFormat _fullFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static String formatFull(DateTime dateTime) {
    return _fullFormat.format(dateTime.toLocal());
  }

  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime.toLocal());
  }

  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime.toLocal());
  }

  /// Relative human-readable time (e.g. "Vừa xong", "5 phút trước", "Hôm nay 14:20")
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 45) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24 && now.day == dateTime.day) {
      return 'Hôm nay, ${_timeFormat.format(dateTime.toLocal())}';
    } else if (difference.inDays == 1 ||
        (difference.inDays < 2 && now.day != dateTime.day)) {
      return 'Hôm qua, ${_timeFormat.format(dateTime.toLocal())}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return _fullFormat.format(dateTime.toLocal());
    }
  }

  /// Format recording timer duration (e.g., "00:08", "01:25")
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
