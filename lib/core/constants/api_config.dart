import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Base URL for PHP REST API in Laragon
  /// Web & Windows Desktop: http://localhost/tirtafield/api
  /// Android Emulator: http://10.0.2.2/tirtafield/api
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/tirtafield/api';
    }
    // Android emulator alias for host machine
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/tirtafield/api';
    }
    return 'http://localhost/tirtafield/api';
  }

  static String get loginUrl => '$baseUrl/login.php';
  static String get attendanceUrl => '$baseUrl/attendance.php';
  static String get approvalUrl => '$baseUrl/approval.php';
}
