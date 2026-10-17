import 'package:intl/intl.dart';

class DateTimeHelper {
  static const List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Format as HH:mm:ss (Contoh: 13:25:55)
  static String formatHHmmss(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  /// Format as HH:mm (Contoh: 08:15)
  static String formatHHmm(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Format as Hari, DD MMMM YYYY (Contoh: Senin, 14 Oktober 2024)
  static String formatIndonesianDate(DateTime dateTime) {
    final dayName = _days[dateTime.weekday - 1];
    final monthName = _months[dateTime.month - 1];
    return '$dayName, ${dateTime.day} $monthName ${dateTime.year}';
  }

  /// Format as DD MMM YYYY (Contoh: 14 Okt 2024)
  static String formatReadableDate(DateTime dateTime) {
    final monthShort = _months[dateTime.month - 1].substring(0, 3);
    return '${dateTime.day} $monthShort ${dateTime.year}';
  }

  /// Format Date for ID/Key (YYYY-MM-DD)
  static String formatDateKey(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}
