// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class LeafletMapViewWeb extends StatefulWidget {
  final double lat;
  final double lng;
  final int zoom;
  final String popupText;

  const LeafletMapViewWeb({
    super.key,
    required this.lat,
    required this.lng,
    required this.zoom,
    required this.popupText,
  });

  @override
  State<LeafletMapViewWeb> createState() => _LeafletMapViewWebState();
}

class _LeafletMapViewWebState extends State<LeafletMapViewWeb> {
  late String _viewType;
  html.IFrameElement? _iframe;

  @override
  void initState() {
    super.initState();
    _viewType =
        'leaflet-map-view-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src =
            'leaflet_map.html?lat=${widget.lat}&lng=${widget.lng}&zoom=${widget.zoom}&popup=${Uri.encodeComponent(widget.popupText)}'
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
        oldWidget.popupText != widget.popupText) {
      _iframe?.contentWindow?.postMessage({
        'type': 'UPDATE_LOCATION',
        'lat': widget.lat,
        'lng': widget.lng,
        'zoom': widget.zoom,
        'popup': widget.popupText,
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
}) {
  return LeafletMapViewWeb(
    lat: lat,
    lng: lng,
    zoom: zoom,
    popupText: popupText,
  );
}
