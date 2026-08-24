String formatLastSeen(DateTime? value, {DateTime? now}) {
  if (value == null) return 'Never seen';
  final difference = (now ?? DateTime.now()).difference(value.toLocal());
  if (difference.isNegative || difference.inSeconds < 60) return 'Just now';
  if (difference.inMinutes < 60) {
    return _ago(difference.inMinutes, 'minute');
  }
  if (difference.inHours < 24) {
    return _ago(difference.inHours, 'hour');
  }
  if (difference.inDays < 30) {
    return _ago(difference.inDays, 'day');
  }
  if (difference.inDays < 365) {
    return _ago(difference.inDays ~/ 30, 'month');
  }
  return _ago(difference.inDays ~/ 365, 'year');
}

String _ago(int amount, String unit) =>
    '$amount $unit${amount == 1 ? '' : 's'} ago';

String valueOrUnavailable(String value) =>
    value.isEmpty ? 'Unavailable' : value;
