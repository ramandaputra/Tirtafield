import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../constants/api_config.dart';


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

  /// Membuka lokasi di OpenStreetMap (100% Bebas API Key & Akses Global)
  static Future<bool> openInOpenStreetMap(double lat, double lng) async {
    final Uri osmUrl = Uri.parse(
      'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=17/$lat/$lng',
    );
    try {
      if (await canLaunchUrl(osmUrl)) {
        return await launchUrl(osmUrl, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(osmUrl);
      }
    } catch (e) {
      debugPrint('Gagal membuka OpenStreetMap: $e');
      return false;
    }
  }

  /// Membuka lokasi di Waze Navigation
  static Future<bool> openInWaze(double lat, double lng) async {
    final Uri wazeUrl = Uri.parse(
      'https://waze.com/ul?ll=$lat,$lng&navigate=yes',
    );
    try {
      if (await canLaunchUrl(wazeUrl)) {
        return await launchUrl(wazeUrl, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(wazeUrl);
      }
    } catch (e) {
      debugPrint('Gagal membuka Waze: $e');
      return false;
    }
  }

  /// Membuka lokasi dengan fallback otomatis: Google Maps -> OpenStreetMap
  static Future<bool> openInMapsWithFallback(double lat, double lng) async {
    final googleSuccess = await openInGoogleMaps(lat, lng);
    if (!googleSuccess) {
      debugPrint('Google Maps tidak dapat dibuka, mengalihkan ke OpenStreetMap...');
      return await openInOpenStreetMap(lat, lng);
    }
    return true;
  }

  /// Menampilkan lembar pilihan peta (Google Maps, OpenStreetMap, Waze)
  static void showMapChooserSheet(BuildContext context, double lat, double lng) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Layanan Peta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Text(
                'Buka koordinat lokasi presensi menggunakan aplikasi atau web pilihan:',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.map_rounded, color: Color(0xFF1A73E8)),
                ),
                title: const Text('Google Maps', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Aplikasi navigasi utama Google', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
                onTap: () {
                  Navigator.pop(ctx);
                  openInGoogleMaps(lat, lng);
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.public_rounded, color: Color(0xFF137333)),
                ),
                title: const Text('OpenStreetMap (Alternatif Bebas API)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Peta global open-source bebas kuota', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
                onTap: () {
                  Navigator.pop(ctx);
                  openInOpenStreetMap(lat, lng);
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF7E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.navigation_rounded, color: Color(0xFFF9AB00)),
                ),
                title: const Text('Waze Navigation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Navigasi rute & lalu lintas real-time', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
                onTap: () {
                  Navigator.pop(ctx);
                  openInWaze(lat, lng);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reverse geocoding alamat riil dari koordinat GPS (Google Maps API & OSM Nominatim Fallback)
  static Future<Map<String, String>> reverseGeocode(
    double lat,
    double lng,
  ) async {
    // 1. Coba Google Geocoding API resmi jika API Key tersedia
    if (ApiConfig.googleMapsApiKey.isNotEmpty) {
      try {
        final googleUri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=${ApiConfig.googleMapsApiKey}&language=id',
        );
        final response = await http.get(googleUri).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
            final results = data['results'] as List;
            final first = results[0] as Map<String, dynamic>;
            final formattedAddress = first['formatted_address'] as String? ?? '';

            String placeName = '';
            if (first['address_components'] is List) {
              for (final comp in first['address_components']) {
                final types = (comp['types'] as List?) ?? [];
                if (types.contains('point_of_interest') ||
                    types.contains('establishment') ||
                    types.contains('premise') ||
                    types.contains('route')) {
                  placeName = comp['long_name']?.toString() ?? '';
                  break;
                }
              }
            }

            if (placeName.isEmpty && results.length > 1) {
              final second = results[1] as Map<String, dynamic>;
              placeName = second['formatted_address']?.toString().split(',').first ?? '';
            }

            return {
              'name': placeName.isNotEmpty ? placeName : 'Area Presensi Lapangan',
              'address': formattedAddress,
            };
          }
        }
      } catch (e) {
        debugPrint('Google Geocoding error, falling back to OSM: $e');
      }
    }

    // 2. Fallback: OpenStreetMap Nominatim
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
      debugPrint('Reverse geocoding OSM error: $e');
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
