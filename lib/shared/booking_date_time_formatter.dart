class BookingDateTimeFormatter {
  BookingDateTimeFormatter._();

  static const _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatDateTime(String date, String time) {
    final formattedDate = formatDate(date);
    final formattedTime = formatTime(time);
    if (formattedDate == formattedTime) return formattedDate;
    if (formattedDate.isEmpty) return formattedTime;
    if (formattedTime.isEmpty) return formattedDate;
    return '$formattedDate · $formattedTime';
  }

  static String formatTimestamp(String value) {
    final raw = value.trim();
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final local = parsed.toLocal();
    final date = '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    final time = '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return formatDateTime(date, time);
  }

  static String formatDate(String value) {
    final raw = value.trim();
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:$|[T ])').firstMatch(raw);
    if (match == null) return raw;

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null ||
        month < 1 || month > 12 || day < 1 || day > 31) {
      return raw;
    }

    final parsed = DateTime.tryParse('${match.group(1)}-${match.group(2)}-${match.group(3)}');
    if (parsed == null) return raw;
    return '${parsed.day} ${_months[parsed.month - 1]} ${parsed.year}';
  }

  static String formatTime(String value) {
    final raw = value.trim();
    final twentyFourHour = RegExp(
      r'^([01]?\d|2[0-3]):([0-5]\d)(?::[0-5]\d(?:\.\d+)?)?$',
    ).firstMatch(raw);
    if (twentyFourHour != null) {
      final hour = int.parse(twentyFourHour.group(1)!);
      final minute = twentyFourHour.group(2)!;
      final period = hour < 12 ? 'AM' : 'PM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      return '$displayHour:$minute $period';
    }

    final twelveHour = RegExp(
      r'^(0?[1-9]|1[0-2]):([0-5]\d)\s*([AaPp][Mm])$',
    ).firstMatch(raw);
    if (twelveHour != null) {
      return '${int.parse(twelveHour.group(1)!)}:${twelveHour.group(2)} ${twelveHour.group(3)!.toUpperCase()}';
    }
    return raw;
  }
}