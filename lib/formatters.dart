import 'package:intl/intl.dart';

String formatLastSeen(DateTime? value, {DateTime? now}) {
  if (value == null) return 'Never seen';
  final local = value.toLocal();
  final difference = (now ?? DateTime.now()).difference(local);
  if (difference.isNegative || difference.inSeconds < 60) return 'Just now';
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours} hr ago';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  }
  return DateFormat.yMMMd().add_jm().format(local);
}

String valueOrUnavailable(String value) =>
    value.isEmpty ? 'Unavailable' : value;
