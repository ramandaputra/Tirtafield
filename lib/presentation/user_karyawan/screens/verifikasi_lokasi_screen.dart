import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../data/models/attendance_model.dart';
import '../../../core/services/location_service.dart';
import '../widgets/leaflet_map_view.dart';
import 'ambil_foto_absensi_screen.dart';

class VerifikasiLokasiScreen extends StatefulWidget {
  final AttendanceSlotType slotType;
  final String slotTitle;

  const VerifikasiLokasiScreen({
    super.key,
    this.slotType = AttendanceSlotType.masuk,
    this.slotTitle = 'Absen Masuk',
  });

  @override
  State<VerifikasiLokasiScreen> createState() => _VerifikasiLokasiScreenState();
}

class _VerifikasiLokasiScreenState extends State<VerifikasiLokasiScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _currentTime;
  Timer? _timer;
  bool _isRefreshingLocation = false;
  bool _isLoadingLocation = true;
  LocationResult? _locationResult;

  int _mapZoom = 16;
  // 0: Peta Jalan (Carto/Google Style), 1: OpenStreetMap Resmi (Bebas API), 2: Satelit ArcGIS
  int _mapProviderIndex = 0;
  Offset _panOffset = Offset.zero;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _fetchLocation();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation({bool isManualRefresh = false}) async {
    setState(() {
      _isLoadingLocation = true;
      if (isManualRefresh) _isRefreshingLocation = true;
    });

    final result = await LocationService.getCurrentLocation();

    if (mounted) {
      setState(() {
        _locationResult = result;
        _isLoadingLocation = false;
        _isRefreshingLocation = false;
      });

      if (isManualRefresh) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: result.isWithinRadius
                ? AppColors.tertiaryContainer
                : AppColors.secondary,
            content: Text(
              'Lokasi GPS: ${result.formattedCoordinates} (Akurasi ${result.formattedAccuracy})',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onRefreshLocation() {
    _fetchLocation(isManualRefresh: true);
  }

  void _onContinueToPhoto() {
    final distanceStr = _locationResult != null
        ? _locationResult!.formattedDistanceHq
        : '8.5 km';
    final projectLocation =
        _locationResult?.locationName ?? LocationService.hqLocationName;
    final projectAddress = _locationResult?.address ?? LocationService.hqAddress;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AmbilFotoAbsensiScreen(
          slotType: widget.slotType,
          slotTitle: widget.slotTitle,
          projectLocation: projectLocation,
          projectAddress: projectAddress,
          distanceHq: distanceStr,
          latitude: _locationResult?.latitude,
          longitude: _locationResult?.longitude,
          coordinates: _locationResult?.formattedCoordinates,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildTopAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Digital Time Card
                _buildDigitalTimeCard(),
                const SizedBox(height: 14),

                // 2. Interactive Vector Map Visualizer Card
                _buildMapVisualizerCard(),
                const SizedBox(height: 14),

                // 3. Field Work Location Details Card
                _buildLocationDetailsCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildStickyBottomFooter(context),
    );
  }

  // TOP APP BAR
  PreferredSizeWidget _buildTopAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.92),
      elevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.onSurface,
          size: 22,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Verifikasi Lokasi',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          fontFamily: 'Inter',
        ),
      ),
      actions: [
        // Live GPS Status Chip
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _isLoadingLocation
                        ? AppColors.warning
                        : AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isLoadingLocation ? 'Mencari GPS...' : 'GPS Aktif',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 1. DIGITAL TIME CARD
  Widget _buildDigitalTimeCard() {
    final hours = _currentTime.hour.toString().padLeft(2, '0');
    final minutes = _currentTime.minute.toString().padLeft(2, '0');
    final seconds = _currentTime.second.toString().padLeft(2, '0');
    final clockStr = '$hours:$minutes:$seconds';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateTimeHelper.formatIndonesianDate(_currentTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    clockStr,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontFamily: 'Inter',
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'WIB',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixed.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.tertiaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.slotTitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.tertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceContainer),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  // 2. REAL GOOGLE MAPS VIEWPORT & VISUALIZER CARD
  Widget _buildMapActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = AppColors.onSurfaceVariant,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildGoogleMapViewport() {
    final lat = _locationResult?.latitude ?? LocationService.hqLatitude;
    final lng = _locationResult?.longitude ?? LocationService.hqLongitude;
    final zoom = _mapZoom;
    final popupHtml = '<b>Lokasi Presensi Anda</b><br>'
        'Koordinat: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}<br>'
        'Akurasi: ${_locationResult?.formattedAccuracy ?? "12 m (Stabil)"}';

    // Jika di Web dan memilih Leaflet OSM (0), gunakan Real Leaflet JS Engine
    if (kIsWeb && _mapProviderIndex == 0) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Container(
          height: 250,
          color: const Color(0xFFE5E3DF),
          child: Stack(
            children: [
              // Real Leaflet JS Map (L.map, L.tileLayer, L.marker, L.popup)
              Positioned.fill(
                child: buildLeafletMapView(
                  lat: lat,
                  lng: lng,
                  zoom: zoom,
                  popupText: popupHtml,
                ),
              ),

              // Floating Layer Switcher
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _mapProviderIndex = (_mapProviderIndex + 1) % 3;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.public_rounded,
                            size: 16,
                            color: Color(0xFF137333),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Leaflet OSM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF202124),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Hitung posisi tile Mercator untuk koordinat GPS (Canvas fallback / Mobile)
    final n = pow(2.0, zoom).toDouble();
    final xExact = ((lng + 180.0) / 360.0) * n;
    final latRad = lat * pi / 180.0;
    final yExact =
        ((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / pi) / 2.0) * n;

    final tileX = xExact.floor();
    final tileY = yExact.floor();
    final fracX = xExact - tileX;
    final fracY = yExact - tileY;

    const tileSize = 256.0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Container(
        height: 250,
        color: const Color(0xFFE5E3DF),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            final centerX = w / 2 + _panOffset.dx;
            final centerY = h / 2 + _panOffset.dy;

            // Titik acuan kiri atas untuk tile sentral (0,0)
            final originX = centerX - (fracX * tileSize);
            final originY = centerY - (fracY * tileSize);

            return GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _panOffset += details.delta;
                });
              },
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // 1. Vector Map Fallback (Grid & roads)
                  Positioned.fill(
                    child: CustomPaint(painter: _VectorMapPainter()),
                  ),

                  // 2. Real Map Raster Tiles (3x3 grid around center tile)
                  ...[-1, 0, 1].expand((dx) {
                    return [-1, 0, 1].map((dy) {
                      final currentTileX = tileX + dx;
                      final currentTileY = tileY + dy;
                      final left = originX + (dx * tileSize);
                      final top = originY + (dy * tileSize);

                      final tileUrl = _mapProviderIndex == 0
                          ? 'https://tile.openstreetmap.org/$zoom/$currentTileX/$currentTileY.png'
                          : (_mapProviderIndex == 1
                              ? ApiConfig.cartoRasterTileUrl(zoom, currentTileX, currentTileY)
                              : 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$zoom/$currentTileY/$currentTileX');

                      final fallbackTileUrl = _mapProviderIndex == 0
                          ? ApiConfig.cartoRasterTileUrl(zoom, currentTileX, currentTileY)
                          : 'https://tile.openstreetmap.org/$zoom/$currentTileX/$currentTileY.png';

                      return Positioned(
                        left: left,
                        top: top,
                        width: tileSize,
                        height: tileSize,
                        child: Image.network(
                          tileUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.network(
                            fallbackTileUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                      );
                    });
                  }),

                  // 3. Radius Tolerance Circle overlay (Google Maps Style Geofence)
                  Positioned(
                    left: centerX - 55,
                    top: centerY - 55,
                    child: IgnorePointer(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                          border: Border.all(
                            color: const Color(0xFF1A73E8).withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4. Google Maps Pin Marker (Red Drop Pin at center)
                  Positioned(
                    left: centerX - 18,
                    top: centerY - 36,
                    child: IgnorePointer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF202124),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Lokasi GPS Anda',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Icon(
                            Icons.location_on_rounded,
                            size: 34,
                            color: Color(0xFFEA4335),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 5. Pulsing Blue Dot (GPS Live Beacon)
                  Positioned(
                    left: centerX - 8,
                    top: centerY - 8,
                    child: IgnorePointer(
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1A73E8),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1A73E8)
                                    .withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 6. Top Left: Layer Mode Switch (Peta / Satelit)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _mapProviderIndex = (_mapProviderIndex + 1) % 3;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _mapProviderIndex == 0
                                    ? Icons.public_rounded
                                    : (_mapProviderIndex == 1
                                        ? Icons.layers_rounded
                                        : Icons.satellite_alt_rounded),
                                size: 16,
                                color: const Color(0xFF1A73E8),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _mapProviderIndex == 0
                                    ? 'Leaflet OSM'
                                    : (_mapProviderIndex == 1
                                        ? 'Peta Jalan'
                                        : 'Satelit ArcGIS'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF202124),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 7. Top Right: Zoom & Recenter Controls (Google Maps Style)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Zoom In (+)
                        _buildMapActionButton(
                          icon: Icons.add,
                          onTap: () {
                            if (_mapZoom < 18) {
                              setState(() {
                                _mapZoom++;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 4),
                        // Zoom Out (-)
                        _buildMapActionButton(
                          icon: Icons.remove,
                          onTap: () {
                            if (_mapZoom > 14) {
                              setState(() {
                                _mapZoom--;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 4),
                        // Recenter GPS
                        _buildMapActionButton(
                          icon: Icons.my_location_rounded,
                          iconColor: const Color(0xFF1A73E8),
                          onTap: () {
                            setState(() {
                              _panOffset = Offset.zero;
                            });
                            _onRefreshLocation();
                          },
                        ),
                      ],
                    ),
                  ),

                  // 8. Bottom Left: Provider Logo / Brand Badge
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _mapProviderIndex == 0
                                ? Icons.public
                                : (_mapProviderIndex == 1
                                    ? Icons.place
                                    : Icons.satellite_alt),
                            color: _mapProviderIndex == 0
                                ? const Color(0xFF137333)
                                : (_mapProviderIndex == 1
                                    ? const Color(0xFFEA4335)
                                    : const Color(0xFF1A73E8)),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _mapProviderIndex == 0
                                ? 'Leaflet OpenStreetMap'
                                : (_mapProviderIndex == 1
                                    ? 'Carto Voyager'
                                    : 'ArcGIS Satellite'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF202124),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 9. Bottom Right: "Buka di Peta (Google / OSM)" Button
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => LocationService.showMapChooserSheet(context, lat, lng),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A73E8),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1A73E8)
                                    .withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Buka di Peta',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapVisualizerCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Real Google Maps Viewport with Live GPS Centering
            _buildGoogleMapViewport(),

            // Map Footer Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF2F3FF),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E7FF), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.tertiaryContainer,
                        size: 15,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Radius Toleransi Kerja: 150 meter',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Geo-Tag: ${_locationResult?.formattedCoordinates ?? '0.9203, 104.4607'}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. FIELD WORK LOCATION DETAILS CARD
  Widget _buildLocationDetailsCard() {
    final locationName = _locationResult?.locationName ?? LocationService.hqLocationName;
    final address = _locationResult?.address ?? LocationService.hqAddress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TUGAS LUAR KANTOR / LOKASI PRESENSI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      locationName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Address Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.outline,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Map Direct Navigation Link with Chooser
          InkWell(
            onTap: () {
              final lat = _locationResult?.latitude ?? LocationService.hqLatitude;
              final lng = _locationResult?.longitude ?? LocationService.hqLongitude;
              LocationService.showMapChooserSheet(context, lat, lng);
            },
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_outlined,
                    size: 16,
                    color: Color(0xFF1A73E8),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Buka & Navigasi di Maps (Google Maps / OpenStreetMap / Waze)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A73E8),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Color(0xFF1A73E8),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEAEDFF)),
          const SizedBox(height: 10),

          // Bento Box Distance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceContainer),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dari Kantor Utama (HQ)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'HQ Wisma Nusantara',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  _locationResult?.formattedDistanceHq ?? '8.5 km',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. STICKY BOTTOM ACTION FOOTER
  Widget _buildStickyBottomFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E7FF), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary Button: Lanjutkan Foto Absensi
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _onContinueToPhoto,
                  icon: const Icon(Icons.photo_camera_rounded, size: 22),
                  label: const Text(
                    'Lanjutkan Foto Absensi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Secondary Button: Segarkan Lokasi
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: _isRefreshingLocation ? null : _onRefreshLocation,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainer,
                    foregroundColor: AppColors.onSurfaceVariant,
                    side: const BorderSide(color: Color(0xFFDAE2FD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRefreshingLocation)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      else
                        const Icon(Icons.refresh_rounded, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Segarkan Lokasi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter to draw simulated vector map lines, roads & connections
class _VectorMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF2F3FF);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Matrix Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0xFFDAE2FD).withValues(alpha: 0.6)
      ..strokeWidth = 0.8;

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Road 1 Curve
    final roadPaint1 = Paint()
      ..color = const Color(0xFFC4C5D5).withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(-20, size.height * 0.75)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.7,
        size.width * 0.45,
        size.height * 0.8,
        size.width * 0.65,
        size.height * 0.5,
      )
      ..cubicTo(
        size.width * 0.8,
        size.height * 0.35,
        size.width * 0.9,
        size.height * 0.3,
        size.width + 20,
        size.height * 0.25,
      );
    canvas.drawPath(path1, roadPaint1);

    // Road 2 Curve
    final roadPaint2 = Paint()
      ..color = const Color(0xFFC4C5D5).withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path2 = Path()
      ..moveTo(size.width * 0.2, -10)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.25,
        size.width * 0.4,
        size.height * 0.5,
        size.width * 0.55,
        size.height * 0.7,
      )
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.85,
        size.width * 0.85,
        size.height * 0.95,
        size.width + 10,
        size.height + 10,
      );
    canvas.drawPath(path2, roadPaint2);

    // HQ Coordinates & Field Coordinates on Canvas
    const hqOffset = Offset(74, 52);
    final fieldOffset = Offset(size.width - 64, size.height - 52);

    // Direct Connecting Dashed Vector Line
    final vectorPaint = Paint()
      ..color = const Color(0xFF0051D5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    _drawDashedLine(canvas, hqOffset, fieldOffset, vectorPaint, 5, 4);

    // Tolerance Radius Circle around Field Location
    final circleFillPaint = Paint()
      ..color = const Color(0xFF316BF3).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(fieldOffset, 42, circleFillPaint);

    final circleBorderPaint = Paint()
      ..color = const Color(0xFF0051D5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    _drawDashedCircle(canvas, fieldOffset, 42, circleBorderPaint);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final count = (dx * dx + dy * dy);
    final distance = count > 0 ? (count / 2) : 0;
    final angle = (p2 - p1).direction;

    double currentDist = 0;
    while (currentDist < distance) {
      final start = p1 + Offset.fromDirection(angle, currentDist);
      final end = p1 + Offset.fromDirection(angle, currentDist + dashWidth);
      canvas.drawLine(start, end, paint);
      currentDist += dashWidth + dashSpace;
    }
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const totalDashes = 28;
    const sweep = (2 * 3.1415926535) / totalDashes;
    for (int i = 0; i < totalDashes; i += 2) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
