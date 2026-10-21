import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../data/models/attendance_model.dart';

class BuktiPresensiBerhasilScreen extends StatefulWidget {
  final AttendanceSlotType slotType;
  final String slotTitle;
  final String projectLocation;
  final String projectAddress;
  final String distanceHq;
  final bool isWithinRadius;
  final String targetOfficeName;
  final String targetOfficeType;
  final DateTime? capturedDateTime;
  final String? photoUrl;
  final double biometricScore;
  final double? latitude;
  final double? longitude;
  final String? coordinates;
  final bool isLate;
  final String? lateReason;
  final int lateDurationMinutes;

  const BuktiPresensiBerhasilScreen({
    super.key,
    this.slotType = AttendanceSlotType.masuk,
    this.slotTitle = 'Presensi Masuk',
    this.projectLocation = 'Kantor PERUMDA Tirta Kepri Tanjung Pinang',
    this.projectAddress =
        'Tj. Pinang Timur, Kota Tanjung Pinang, Kepulauan Riau 29113',
    this.distanceHq = '8.5 km',
    this.isWithinRadius = false,
    this.targetOfficeName = 'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang',
    this.targetOfficeType = 'Kantor Utama',
    this.capturedDateTime,
    this.photoUrl,
    this.biometricScore = 99.4,
    this.latitude,
    this.longitude,
    this.coordinates,
    this.isLate = false,
    this.lateReason,
    this.lateDurationMinutes = 0,
  });

  @override
  State<BuktiPresensiBerhasilScreen> createState() =>
      _BuktiPresensiBerhasilScreenState();
}

class _BuktiPresensiBerhasilScreenState extends State<BuktiPresensiBerhasilScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final DateTime _recordedTime;

  static const String _defaultPhotoUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD55-eQFtOV4CY1tIoex3Ed6zg0_BE86IF9o8Xd4rJjHo_j7DfTl4fIakS_KLFk4fm5KmCOUrEgQ5uHbKFhv4Y267uvKsyxeiDb-ONmhW9cVTK0iR_cHIi8jv6WbGjoaK2vJfL8uvQRjiUpx0Igb5bs4MO19-0zDIwobKcdfmRRSq_SvUhSRoB9qIiuH4mCr1h5dPNad9rPkVCdYgkYHGHlr3iGXRtgv6sKUJbAXRkM_lX-SmaMcak';

  @override
  void initState() {
    super.initState();
    _recordedTime = widget.capturedDateTime ?? DateTime.now();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTimeOnly(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _generateFileName(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final sec = dt.second.toString().padLeft(2, '0');
    return 'Swafoto_$y$m${d}_$h$min$sec.jpg';
  }

  String _getNextActivityTitle() {
    switch (widget.slotType) {
      case AttendanceSlotType.masuk:
        return 'Presensi Istirahat Keluar (12:00 WIB)';
      case AttendanceSlotType.istirahatKeluar:
        return 'Presensi Istirahat Masuk (13:00 WIB)';
      case AttendanceSlotType.istirahatMasuk:
        return 'Presensi Pulang (17:00 WIB)';
      case AttendanceSlotType.pulang:
        return 'Jam Kerja Selesai Hari Ini';
    }
  }

  void _showFullImageModal(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 300,
                  height: 380,
                  color: AppColors.surfaceContainerLowest,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, size: 48),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.black.withValues(alpha: 0.6),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.photoUrl ?? _defaultPhotoUrl;
    final fileName = _generateFileName(_recordedTime);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.onSurface,
            size: 22,
          ),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        centerTitle: true,
        title: const Text(
          'Bukti Presensi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    // 1. VERIFIED SUCCESS STATE ANIMATION EMBLEM
                    _buildSuccessEmblem(),
                    const SizedBox(height: 18),

                    // 2. ATTENDANCE DIGITAL SLIP / RECEIPT CARD
                    _buildReceiptCard(context, photoUrl, fileName),
                    const SizedBox(height: 14),

                    // 3. NEXT SCHEDULED ACTIVITY ALERT BANNER
                    _buildNextActivityBanner(),
                  ],
                ),
              ),
            ),
          ),

          // 4. FIXED BOTTOM STICKY ACTION HUB
          _buildStickyFooter(context),
        ],
      ),
    );
  }

  // 1. EMBLEM
  Widget _buildSuccessEmblem() {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing halo effect
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryFixedDim.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
              // Center solid checkmark icon circle
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.tertiaryContainer.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Presensi Berhasil Terkirim!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.onSurface,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Data kehadiran Anda telah tercatat dan terverifikasi di sistem perusahaan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.35,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  // 2. RECEIPT CARD
  Widget _buildReceiptCard(
    BuildContext context,
    String photoUrl,
    String fileName,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Subtle Top Decorative Strip: Gradient from secondary to tertiary-fixed-dim
            Container(
              height: 4,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.secondary, AppColors.tertiaryFixedDim],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Receipt Header Badges
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated pulsing dot
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(
                                      alpha: _pulseAnimation.value > 1.1 ? 0.6 : 0.2,
                                    ),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Pending: Menunggu Disetujui oleh Direktur',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Shift & Status Category Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceContainer),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryFixed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.badge_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.slotTitle,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Shift Pagi • Lapangan',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.onSurfaceVariant,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isLate
                                ? const Color(0xFFFEF3C7)
                                : AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            border: widget.isLate
                                ? Border.all(color: const Color(0xFFF59E0B), width: 1.2)
                                : null,
                          ),
                          child: Text(
                            widget.isLate
                                ? 'Terlambat (${widget.lateDurationMinutes} menit)'
                                : 'Tepat Waktu',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: widget.isLate
                                  ? const Color(0xFFB45309)
                                  : AppColors.primary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isLate && widget.lateReason != null && widget.lateReason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFB45309)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Alasan Keterlambatan Tercatat:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.lateReason!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF78350F),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Metric & Verification Details
                  // 1. Timestamp Item
                  _buildMetricRow(
                    icon: Icons.schedule_rounded,
                    label: 'WAKTU STEMPEL',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _formatTimeOnly(_recordedTime),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'WIB',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateTimeHelper.formatIndonesianDate(_recordedTime),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.onSurfaceVariant,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 24, thickness: 0.8, color: Color(0x20C4C5D5)),

                  // 2. Geofence & Location Item
                  _buildMetricRow(
                    icon: Icons.location_on_rounded,
                    label: 'LOKASI PENUGASAN',
                    topTrailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.share_location_rounded,
                            size: 13,
                            color: AppColors.secondary,
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Penugasan Lapangan',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.projectLocation,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            height: 1.25,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.projectAddress} • Jarak ${widget.distanceHq} ke ${widget.targetOfficeName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                            fontFamily: 'Inter',
                          ),
                        ),
                        if (widget.coordinates != null || widget.latitude != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.pin_drop_rounded,
                                size: 12,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'GPS: ${widget.coordinates ?? '${widget.latitude?.toStringAsFixed(6)}, ${widget.longitude?.toStringAsFixed(6)}'} (Akurasi Presisi)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          InkWell(
                            onTap: () {
                              final lat = widget.latitude ?? LocationService.hqLatitude;
                              final lng = widget.longitude ?? LocationService.hqLongitude;
                              LocationService.showMapChooserSheet(context, lat, lng);
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.open_in_new_rounded,
                                  size: 11,
                                  color: Color(0xFF1A73E8),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Buka di Maps (Google / OSM)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A73E8),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Divider(height: 24, thickness: 0.8, color: Color(0x20C4C5D5)),

                  // 3. Attached Selfie Snapshot & Geotag Stamp
                  Row(
                    children: [
                      // Photo thumbnail with GEOTAGGED badge
                      GestureDetector(
                        onTap: () => _showFullImageModal(context, photoUrl),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(alpha: 0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.surfaceContainer,
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: AppColors.outline,
                                      size: 30,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    color: AppColors.inverseSurface
                                        .withValues(alpha: 0.85),
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: const Text(
                                      'BERSTEMPEL LOKASI',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.inverseOnSurface,
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Metadata info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LAMPIRAN BUKTI FISIK',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: AppColors.onSurfaceVariant,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Flexible(
                                  child: Text(
                                    'Menunggu Verifikasi Direktur',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.secondary,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Fullscreen view button
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.surfaceContainer,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.fullscreen_rounded,
                            size: 20,
                            color: AppColors.onSurfaceVariant,
                          ),
                          onPressed: () => _showFullImageModal(context, photoUrl),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. NEXT ACTIVITY BANNER
  Widget _buildNextActivityBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.surfaceContainerHigh,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.secondaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.upcoming_rounded,
              size: 17,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sesi Aktivitas Berikutnya',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getNextActivityTitle(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.outlineVariant,
          ),
        ],
      ),
    );
  }

  // Helper for metric rows (Timestamp & Location)
  Widget _buildMetricRow({
    required IconData icon,
    required String label,
    required Widget content,
    Widget? topTrailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppColors.onSurfaceVariant,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  if (topTrailing != null) ...[
                    const SizedBox(width: 6),
                    Flexible(child: topTrailing),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              content,
            ],
          ),
        ),
      ],
    );
  }

  // 4. STICKY FOOTER
  Widget _buildStickyFooter(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest.withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(
                    Icons.home_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
