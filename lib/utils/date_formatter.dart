import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _fullDateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _shortMonthYearFormat = DateFormat('MMM yyyy', 'id_ID');

  static String format(DateTime? date) {
    if (date == null) return '-';
    try {
      return _dateFormat.format(date);
    } catch (_) {
      // Fallback if locale data is not loaded
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    }
  }

  static String formatFull(DateTime? date) {
    if (date == null) return '-';
    try {
      return _fullDateFormat.format(date);
    } catch (_) {
      return format(date);
    }
  }

  static String formatMonthYear(DateTime? date) {
    if (date == null) return '-';
    try {
      return _monthYearFormat.format(date);
    } catch (_) {
      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${months[date.month - 1]} ${date.year}';
    }
  }

  static String formatShortMonthYear(DateTime? date) {
    if (date == null) return '-';
    try {
      return _shortMonthYearFormat.format(date);
    } catch (_) {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${months[date.month - 1]} ${date.year}';
    }
  }

  static String formatRelative(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = target.difference(today).inDays;

    if (diffDays == 0) return 'Hari ini';
    if (diffDays == 1) return 'Besok';
    if (diffDays == -1) return 'Kemarin';
    if (diffDays > 0) return '$diffDays hari lagi';
    return '${diffDays.abs()} hari lalu';
  }
}

