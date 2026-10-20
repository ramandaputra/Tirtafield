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

  /// Format as HH:mm:ss WIB (Contoh: 13:25:55 WIB)
  static String formatHHmmssWib(DateTime dateTime) {
    return '${formatHHmmss(dateTime)} WIB';
  }

  /// Format as HH:mm (Contoh: 08:15)
  static String formatHHmm(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Format as HH:mm WIB (Contoh: 08:15 WIB)
  static String formatHHmmWib(DateTime dateTime) {
    return '${formatHHmm(dateTime)} WIB';
  }

  /// Format as Hari, DD MMMM YYYY (Contoh: Senin, 19 Oktober 2026)
  static String formatIndonesianDate(DateTime dateTime) {
    final dayName = _days[dateTime.weekday - 1];
    final monthName = _months[dateTime.month - 1];
    return '$dayName, ${dateTime.day} $monthName ${dateTime.year}';
  }

  /// Format as Hari, DD MMMM YYYY • HH:mm:ss WIB
  static String formatIndonesianFullDateTimeWib(DateTime dateTime) {
    return '${formatIndonesianDate(dateTime)} • ${formatHHmmssWib(dateTime)}';
  }

  /// Format as DD MMM YYYY (Contoh: 19 Okt 2026)
  static String formatReadableDate(DateTime dateTime) {
    final monthShort = _months[dateTime.month - 1].substring(0, 3);
    return '${dateTime.day} $monthShort ${dateTime.year}';
  }

  /// Format Date for ID/Key (YYYY-MM-DD)
  static String formatDateKey(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}
