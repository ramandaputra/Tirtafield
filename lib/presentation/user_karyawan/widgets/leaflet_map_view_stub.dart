import 'dart:math';
import 'package:flutter/material.dart';

Widget buildLeafletMapView({
  required double lat,
  required double lng,
  required int zoom,
  required String popupText,
  double? targetLat,
  double? targetLng,
  String? targetName,
  double? targetRadius,
  String? allOfficesJson,
}) {
  final n = pow(2.0, zoom).toDouble();
  final xExact = ((lng + 180.0) / 360.0) * n;
  final latRad = lat * pi / 180.0;
  final yExact = ((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / pi) / 2.0) * n;
  final tileX = xExact.floor();
  final tileY = yExact.floor();

  final tileUrl = 'https://tile.openstreetmap.org/$zoom/$tileX/$tileY.png';

  return Stack(
    children: [
      Positioned.fill(
        child: Image.network(
          tileUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFE5E7EB),
            child: const Center(
              child: Icon(Icons.map_outlined, size: 36, color: Colors.black38),
            ),
          ),
        ),
      ),
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.my_location_rounded, size: 16, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Lokasi Presensi',
                style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

