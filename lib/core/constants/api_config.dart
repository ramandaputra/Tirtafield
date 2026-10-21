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
  static String get updateProfileUrl => '$baseUrl/update_profile.php';
  static String get employeesUrl => '$baseUrl/employees.php';
  static String get officesUrl => '$baseUrl/offices.php';
  static String get settingsUrl => '$baseUrl/settings.php';
  static String get resolveMapsUrl => '$baseUrl/resolve_maps.php';

  /// Carto Basemap API Key
  static const String cartoApiKey =
      'cb1_4ns5_1_ac9e8b38ad585a28159bf506';

  /// Carto Vector Voyager GL Style URL (MapLibre / Mapbox GL)
  static const String cartoVectorStyleUrl =
      'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json?key=cb1_4ns5_1_ac9e8b38ad585a28159bf506';

  /// Carto Raster Voyager Tile URL Helper
  static String cartoRasterTileUrl(int zoom, int x, int y) =>
      'https://basemaps.cartocdn.com/rastertiles/voyager/$zoom/$x/$y.png?key=$cartoApiKey';

  /// Google Maps API Key (Opsional, kosongkan jika menggunakan OpenStreetMap Nominatim bebas API)
  static const String googleMapsApiKey = '';
}

