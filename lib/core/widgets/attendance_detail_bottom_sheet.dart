import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../data/models/system_settings_model.dart';
import '../../presentation/user_karyawan/widgets/leaflet_map_view.dart';
import '../../state/system_settings_provider.dart';
import '../constants/app_colors.dart';
import '../services/location_service.dart';

class AttendanceDetailBottomSheet extends StatelessWidget {
  final String userName;
  final String nip;
  final String department;
  final String recordedTimeStr;
  final String status;
  final bool isLate;
  final String absenUntukApa;
  final String locationName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String distancePlacement;
  final String? officePlacement;
  final String? fotoUrl;
  final String? slotTitle;
  final bool isApproval;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const AttendanceDetailBottomSheet({
    super.key,
    required this.userName,
    required this.nip,
    required this.department,
    required this.recordedTimeStr,
    required this.status,
    required this.isLate,
    required this.absenUntukApa,
    required this.locationName,
    this.address,
    this.latitude,
    this.longitude,
    required this.distancePlacement,
    this.officePlacement,
    this.fotoUrl,
    this.slotTitle,
    this.isApproval = false,
    this.onApprove,
    this.onReject,
  });

  static void show(
    BuildContext context, {
    required String userName,
    required String nip,
    required String department,
    required String recordedTimeStr,
    required String status,
    required bool isLate,
    required String absenUntukApa,
    required String locationName,
    String? address,
    double? latitude,
    double? longitude,
    required String distancePlacement,
    String? officePlacement,
    String? fotoUrl,
    String? slotTitle,
    bool isApproval = false,
    VoidCallback? onApprove,
    VoidCallback? onReject,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
          maxWidth: 600,
        ),
        child: AttendanceDetailBottomSheet(
          userName: userName,
          nip: nip,
          department: department,
          recordedTimeStr: recordedTimeStr,
          status: status,
          isLate: isLate,
          absenUntukApa: absenUntukApa,
          locationName: locationName,
          address: address,
          latitude: latitude,
          longitude: longitude,
          distancePlacement: distancePlacement,
          officePlacement: officePlacement,
          fotoUrl: fotoUrl,
          slotTitle: slotTitle,
          isApproval: isApproval,
          onApprove: onApprove,
          onReject: onReject,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        isLate ? const Color(0xFFD97706) : const Color(0xFF16A34A);
    final statusBg =
        isLate ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7);
    final statusIcon =
        isLate ? Icons.schedule_rounded : Icons.check_circle_outline_rounded;
    final statusLabel = isLate ? 'Terlambat' : 'Tepat Waktu';

    // 1. Resolve kantor penempatan pegawai dari SystemSettingsProvider
    final settingsProv = context.watch<SystemSettingsProvider>();
    final offices = settingsProv.geofencing.offices;
    OfficeLocationItem targetOffice = settingsProv.primaryOffice;
    if (officePlacement != null && officePlacement!.trim().isNotEmpty) {
      final query = officePlacement!.trim().toLowerCase();
      for (final o in offices) {
        final oName = o.name.toLowerCase();
        if (oName == query || oName.contains(query) || query.contains(oName)) {
          targetOffice = o;
          break;
        }
      }
    }

    final targetLat = targetOffice.latitude;
    final targetLng = targetOffice.longitude;
    final targetName = targetOffice.name;
    final targetRad = targetOffice.radius;

    final lat = latitude ?? targetLat;
    final lng = longitude ?? targetLng;

    // 2. Hitung jarak matematis akurat (Geodesic WGS-84) antara titik GPS presensi & kantor penempatan
    double? calculatedMeters;
    if (latitude != null && longitude != null) {
      calculatedMeters =
          Geolocator.distanceBetween(lat, lng, targetLat, targetLng);
    }

    final String accurateDistance;
    if (calculatedMeters != null) {
      if (calculatedMeters >= 1000) {
        accurateDistance = '${(calculatedMeters / 1000).toStringAsFixed(1)} km';
      } else {
        accurateDistance = '${calculatedMeters.toStringAsFixed(0)} m';
      }
    } else {
      accurateDistance = _cleanDistance(distancePlacement);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Header: Title & Close Button
            Row(
              children: [
                const Icon(
                  Icons.assignment_ind_outlined,
                  size: 20,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Rincian Riwayat Presensi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                if (slotTitle != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      slotTitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 14),

            // Scrollable Detail Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // 1 & 2. NAMA, NIK, DIVISI + STATUS TEPAT WAKTU/TERLAMBAT
                    // ==========================================
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 55,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.outlineVariant.withValues(alpha: 0.4),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: fotoUrl != null && fotoUrl!.isNotEmpty
                                  ? Image.network(
                                      fotoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          userName.isNotEmpty ? userName[0] : 'P',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        userName.isNotEmpty ? userName[0] : 'P',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'NIK: $nip  •  $department',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // 7. STATUS TEPAT WAKTU ATAU TERLAMBAT
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: statusColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon, size: 12, color: statusColor),
                                      const SizedBox(width: 4.5),
                                      Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ==========================================
                    // FOTO BUKTI SWAFOTO PRESENSI
                    // ==========================================
                    _buildSectionHeader(
                      icon: Icons.camera_alt_outlined,
                      title: 'Bukti Swafoto Presensi',
                    ),
                    const SizedBox(height: 6),
                    _buildSelfiePhotoCard(context),
                    const SizedBox(height: 12),

                    // ==========================================
                    // 3. WAKTU PEREKAMAN PRESENSI
                    // ==========================================
                    _buildSectionHeader(
                      icon: Icons.access_time_rounded,
                      title: 'Waktu Perekaman Presensi',
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recordedTimeStr,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Metode Presensi: Swafoto Kamera Langsung',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ==========================================
                    // 6. KETERANGAN KEPERLUAN PRESENSI
                    // ==========================================
                    _buildSectionHeader(
                      icon: Icons.assignment_outlined,
                      title: 'Keterangan Keperluan Presensi',
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.work_outline_rounded,
                              size: 15,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              absenUntukApa.isNotEmpty
                                  ? absenUntukApa
                                  : 'Penugasan operasional lapangan PDAM Tirtafield',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ==========================================
                    // 4 & 5. LOKASI PRESENSI & JARAK KE KANTOR PENEMPATAN
                    // ==========================================
                    _buildSectionHeader(
                      icon: Icons.near_me_rounded,
                      title: 'Lokasi & Jarak ke Kantor Penempatan',
                    ),
                    const SizedBox(height: 6),

                    // Kartu Sorotan Jarak Utama (Kompak, Akurat & Tidak Menumpuk)
                    _buildDistanceHighlightCard(
                      accurateDistance: accurateDistance,
                      targetOfficeName: targetName,
                      currentLocationName: locationName,
                    ),
                    const SizedBox(height: 8),

                    // Peta Interaktif Preview (Bebas dari pill ganda yang bertabrakan)
                    _buildMapPreviewCard(
                      context: context,
                      lat: lat,
                      lng: lng,
                      targetLat: targetLat,
                      targetLng: targetLng,
                      targetName: targetName,
                      targetRad: targetRad,
                      offices: offices,
                    ),
                  ],
                ),
              ),
            ),

            // Modal Footer Actions
            const SizedBox(height: 12),
            if (isApproval) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      label: const Text('Tolak'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded, size: 14),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                child: const Text(
                  'Tutup Rincian',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  // WIDGET FOTO SELFIE PRESENSI
  Widget _buildSelfiePhotoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _showPhotoPreviewDialog(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              child: Container(
                color: const Color(0xFF0F172A),
                width: double.infinity,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 380,
                    ),
                    child: AspectRatio(
                      aspectRatio: 4 / 5,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          fotoUrl != null && fotoUrl!.isNotEmpty
                              ? Image.network(
                                  fotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildFallbackPhotoCard(),
                                )
                              : _buildFallbackPhotoCard(),
                          // Vignette / Shadow Overlay for watermarks
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.35),
                                    Colors.transparent,
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.70),
                                  ],
                                  stops: const [0.0, 0.2, 0.7, 1.0],
                                ),
                              ),
                            ),
                          ),
                          // Badge Orientasi Portrait di pojok kiri atas
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.stay_current_portrait_rounded,
                                      size: 11, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Portrait 4:5',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Indikator Zoom di pojok atas
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 0.8,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.zoom_in_rounded,
                                      size: 13, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text(
                                    'Ketuk Perbesar',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Watermark / Badge di pojok bawah
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.verified_user_rounded,
                                          size: 13, color: Color(0xFF38BDF8)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Swafoto Asli Kamera',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    recordedTimeStr.contains('•')
                                        ? recordedTimeStr.split('•')[1].trim()
                                        : '',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
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
                ),
              ),
            ),
          ),
          // Caption Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(13)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stay_current_portrait_rounded,
                    size: 14, color: AppColors.secondary),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Swafoto tersimpan dalam format portrait sesuai pengambilan kamera pegawai.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showPhotoPreviewDialog(context),
                  icon: const Icon(Icons.fullscreen_rounded, size: 14),
                  label: const Text(
                    'Lihat Penuh',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackPhotoCard() {
    return Container(
      color: AppColors.surfaceContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 44,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            const Text(
              'Swafoto Presensi Pegawai (Portrait)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Format Kamera Langsung 4:5',
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanDistance(String raw) {
    if (raw.contains(' dari ')) {
      return raw.split(' dari ')[0].trim();
    }
    return raw.trim();
  }

  // KARTU RINGKASAN JARAK KE KANTOR PENEMPATAN (Kompak, Elegan, Bebas Redundansi)
  Widget _buildDistanceHighlightCard({
    required String accurateDistance,
    required String targetOfficeName,
    required String currentLocationName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // clean light blue
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.straighten_rounded,
              size: 18,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Jarak ke Kantor Penempatan: ',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    Text(
                      accurateDistance,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2.5),
                Text(
                  '$targetOfficeName  •  $currentLocationName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET BENTUK PETA (LEAFLET INTERAKTIF BERSIH & FOKUS JARAK)
  Widget _buildMapPreviewCard({
    required BuildContext context,
    required double lat,
    required double lng,
    required double targetLat,
    required double targetLng,
    required String targetName,
    required double targetRad,
    required List<OfficeLocationItem> offices,
  }) {
    final cleanLocationName = locationName.replaceAll("'", "").trim();
    final cleanUserName = userName.replaceAll("'", "").trim();
    final cleanTimeStr = recordedTimeStr.replaceAll("'", "").trim();

    final popupHtml =
        '<b>$cleanLocationName</b><br>'
        'Pegawai: $cleanUserName<br>'
        'Waktu: $cleanTimeStr<br>'
        'Koordinat: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';

    String? allOfficesJson;
    try {
      allOfficesJson = jsonEncode(
        offices
            .map((o) => {
                  'id': o.id,
                  'name': o.name,
                  'lat': o.latitude,
                  'lng': o.longitude,
                  'radius': o.radius,
                  'isPrimary': o.isPrimary,
                })
            .toList(),
      );
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          // Leaflet Interactive OpenStreetMap Viewport (Tanpa overlay tumpang tindih)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: buildLeafletMapView(
                lat: lat,
                lng: lng,
                zoom: 15,
                popupText: popupHtml,
                targetLat: targetLat,
                targetLng: targetLng,
                targetName: targetName,
                targetRadius: targetRad,
                allOfficesJson: allOfficesJson,
              ),
            ),
          ),

          // Map Action Bar (Info Lokasi & Navigasi Eksternal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(13)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.pin_drop_outlined,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          address != null && address!.isNotEmpty
                              ? address!
                              : '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    LocationService.showMapChooserSheet(context, lat, lng);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 13),
                  label: const Text(
                    'Buka di Maps',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoPreviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.stay_current_portrait_rounded,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Swafoto Presensi (Portrait)',
                        style: TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.65,
                  maxWidth: 360,
                ),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        fotoUrl != null && fotoUrl!.isNotEmpty
                            ? Image.network(
                                fotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.surfaceContainer,
                                  child: const Center(
                                    child: Text('Foto tidak dapat dimuat'),
                                  ),
                                ),
                              )
                            : Container(
                                color: AppColors.surfaceContainer,
                                child: const Center(
                                  child: Text('Tidak ada lampiran swafoto'),
                                ),
                              ),
                        // Watermark / Verified Badge di pojok bawah
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified_user_rounded,
                                    size: 14, color: Color(0xFF38BDF8)),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Kamera Asli Terverifikasi • Rasio 4:5 Portrait',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
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
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'NIK: $nip • $department',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Waktu: $recordedTimeStr',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

