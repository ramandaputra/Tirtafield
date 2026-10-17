import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double distanceMetersFromHq;
  final bool isWithinRadius;
  final bool isMocked;
  final String? errorMessage;
  final String address;
  final String locationName;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.distanceMetersFromHq,
    required this.isWithinRadius,
    this.isMocked = false,
    this.errorMessage,
    this.address =
        'Jl. Jenderal Sudirman Kav. 21, Karet Setiabudi, Jakarta Selatan, DKI Jakarta 12920',
    this.locationName = 'Area Proyek Sudirman Office Tower',
  });

  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

  String get formattedPreciseCoordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  String get formattedDistanceHq {
    if (distanceMetersFromHq >= 1000) {
      return '${(distanceMetersFromHq / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMetersFromHq.toStringAsFixed(0)} m';
  }

  String get formattedAccuracy => '±${accuracy.toStringAsFixed(0)}m';

  String get googleMapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
}

class LocationService {
  // Koordinat Kantor Pusat (HQ) Tirtafield / Sudirman Office
  static const double hqLatitude = -6.2146;
  static const double hqLongitude = 106.8219;
  static const double maxAllowedRadiusMeters = 150.0;

  /// Membuka lokasi GPS langsung di Google Maps (aplikasi atau web browser)
  static Future<bool> openInGoogleMaps(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        return await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        return await launchUrl(googleMapsUrl);
      }
    } catch (e) {
      debugPrint('Gagal membuka Google Maps: $e');
      return false;
    }
  }

  /// Reverse geocoding alamat riil dari koordinat GPS Google Maps / Nominatim
  static Future<Map<String, String>> reverseGeocode(
    double lat,
    double lng,
  ) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final response = await http
          .get(uri, headers: {'User-Agent': 'TirtafieldAttendance/1.0'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>? ?? {};
        final displayName = data['display_name'] as String?;

        final road = address['road'] ??
            address['residential'] ??
            address['suburb'] ??
            '';
        final city = address['city'] ??
            address['city_district'] ??
            address['county'] ??
            '';
        final state = address['state'] ?? '';

        String name = road.isNotEmpty ? road : 'Area Tugas Lapangan';
        String fullAddress = displayName ?? '$road, $city, $state';

        return {
          'name': name,
          'address': fullAddress,
        };
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }

    return {
      'name': 'Area Proyek Sudirman Office Tower',
      'address':
          'Jl. Jenderal Sudirman Kav. 21, Karet Setiabudi, Jakarta Selatan, DKI Jakarta 12920',
    };
  }

  /// Memeriksa izin & mengambil koordinat GPS riil perangkat
  static Future<LocationResult> getCurrentLocation({
    double targetLat = hqLatitude,
    double targetLng = hqLongitude,
  }) async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // 1. Cek apakah layanan GPS aktif
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _createFallbackResult(
          errorMessage: 'Layanan lokasi/GPS nonaktif di perangkat.',
        );
      }

      // 2. Periksa status izin lokasi
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _createFallbackResult(
            errorMessage: 'Izin lokasi ditolak oleh pengguna.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _createFallbackResult(
          errorMessage: 'Izin lokasi diblokir secara permanen.',
        );
      }

      // 3. Ambil posisi GPS aktual
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      // 4. Hitung jarak riil dari target / HQ
      final double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLat,
        targetLng,
      );

      final bool isWithin = distance <= maxAllowedRadiusMeters;

      // 5. Reverse geocode untuk mendapatkan alamat aktual Google Maps
      final geoInfo =
          await reverseGeocode(position.latitude, position.longitude);

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy > 0 ? position.accuracy : 5.0,
        distanceMetersFromHq: distance,
        isWithinRadius: isWithin,
        isMocked: position.isMocked,
        locationName: geoInfo['name'] ?? 'Area Proyek Sudirman Office Tower',
        address: geoInfo['address'] ??
            'Jl. Jenderal Sudirman Kav. 21, Karet Setiabudi, Jakarta Selatan, DKI Jakarta 12920',
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return _createFallbackResult(errorMessage: e.toString());
    }
  }

  /// Fallback koordinat jika GPS belum menyala atau diizinkan
  static LocationResult _createFallbackResult({String? errorMessage}) {
    final randomOffset = (Random().nextDouble() - 0.5) * 0.0005;
    final lat = hqLatitude + randomOffset;
    final lng = hqLongitude + randomOffset;

    final distance = Geolocator.distanceBetween(
      lat,
      lng,
      hqLatitude,
      hqLongitude,
    );

    return LocationResult(
      latitude: lat,
      longitude: lng,
      accuracy: 3.0,
      distanceMetersFromHq: distance,
      isWithinRadius: distance <= maxAllowedRadiusMeters,
      isMocked: true,
      errorMessage: errorMessage,
      locationName: 'Area Proyek Sudirman Office Tower',
      address:
          'Jl. Jenderal Sudirman Kav. 21, Karet Setiabudi, Jakarta Selatan, DKI Jakarta 12920',
    );
  }
}
