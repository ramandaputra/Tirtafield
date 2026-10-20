// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class LeafletMapViewWeb extends StatefulWidget {
  final double lat;
  final double lng;
  final int zoom;
  final String popupText;
  final double? targetLat;
  final double? targetLng;
  final String? targetName;
  final double? targetRadius;
  final String? allOfficesJson;

  const LeafletMapViewWeb({
    super.key,
    required this.lat,
    required this.lng,
    required this.zoom,
    required this.popupText,
    this.targetLat,
    this.targetLng,
    this.targetName,
    this.targetRadius,
    this.allOfficesJson,
  });

  @override
  State<LeafletMapViewWeb> createState() => _LeafletMapViewWebState();
}

class _LeafletMapViewWebState extends State<LeafletMapViewWeb> {
  late String _viewType;
  html.IFrameElement? _iframe;

  String _buildUrl() {
    var url =
        'leaflet_map.html?lat=${widget.lat}&lng=${widget.lng}&zoom=${widget.zoom}&popup=${Uri.encodeComponent(widget.popupText)}';
    if (widget.targetLat != null && widget.targetLng != null) {
      url +=
          '&tlat=${widget.targetLat}&tlng=${widget.targetLng}&tname=${Uri.encodeComponent(widget.targetName ?? "Kantor")}&trad=${widget.targetRadius ?? 150}';
    }
    if (widget.allOfficesJson != null && widget.allOfficesJson!.isNotEmpty) {
      url += '&all_offices=${Uri.encodeComponent(widget.allOfficesJson!)}';
    }
    return url;
  }

  @override
  void initState() {
    super.initState();
    _viewType =
        'leaflet-map-view-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = _buildUrl()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block';
      _iframe = iframe;
      return iframe;
    });
  }

  @override
  void didUpdateWidget(covariant LeafletMapViewWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat ||
        oldWidget.lng != widget.lng ||
        oldWidget.zoom != widget.zoom ||
        oldWidget.popupText != widget.popupText ||
        oldWidget.targetLat != widget.targetLat ||
        oldWidget.targetLng != widget.targetLng ||
        oldWidget.targetName != widget.targetName ||
        oldWidget.targetRadius != widget.targetRadius ||
        oldWidget.allOfficesJson != widget.allOfficesJson) {
      dynamic parsedOffices;
      if (widget.allOfficesJson != null && widget.allOfficesJson!.isNotEmpty) {
        try {
          parsedOffices = jsonDecode(widget.allOfficesJson!);
        } catch (_) {}
      }

      _iframe?.contentWindow?.postMessage({
        'type': 'UPDATE_LOCATION',
        'lat': widget.lat,
        'lng': widget.lng,
        'zoom': widget.zoom,
        'popup': widget.popupText,
        'targetLat': widget.targetLat,
        'targetLng': widget.targetLng,
        'targetName': widget.targetName,
        'targetRadius': widget.targetRadius,
        'allOffices': parsedOffices,
      }, '*');
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}

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
  return LeafletMapViewWeb(
    lat: lat,
    lng: lng,
    zoom: zoom,
    popupText: popupText,
    targetLat: targetLat,
    targetLng: targetLng,
    targetName: targetName,
    targetRadius: targetRadius,
    allOfficesJson: allOfficesJson,
  );
}

