import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../data/models/attendance_model.dart';
import '../../../state/attendance_provider.dart';
import '../../../state/auth_provider.dart';
import '../../../state/system_settings_provider.dart';
import 'bukti_presensi_berhasil_screen.dart';

class AmbilFotoAbsensiScreen extends StatefulWidget {
  final AttendanceSlotType slotType;
  final String slotTitle;
  final String projectLocation;
  final String projectAddress;
  final String distanceHq;
  final bool isWithinRadius;
  final String targetOfficeName;
  final String targetOfficeType;
  final double? latitude;
  final double? longitude;
  final String? coordinates;

  const AmbilFotoAbsensiScreen({
    super.key,
    this.slotType = AttendanceSlotType.istirahatKeluar,
    this.slotTitle = 'Presensi Istirahat Keluar',
    this.projectLocation = 'Kantor Tirtafield Tanjung Pinang',
    this.projectAddress =
        'Tj. Pinang Timur, Kota Tanjung Pinang, Kepulauan Riau 29113',
    this.distanceHq = '8.5 km',
    this.isWithinRadius = false,
    this.targetOfficeName = 'Kantor Pusat Tirtafield (Kantor Utama)',
    this.targetOfficeType = 'Kantor Utama',
    this.latitude,
    this.longitude,
    this.coordinates,
  });

  @override
  State<AmbilFotoAbsensiScreen> createState() => _AmbilFotoAbsensiScreenState();
}

class _AmbilFotoAbsensiScreenState extends State<AmbilFotoAbsensiScreen>
    with TickerProviderStateMixin {
  late DateTime _currentTime;
  Timer? _timer;

  // Flow State: false = Live Camera capture mode, true = Captured selfie result mode
  bool _hasCapturedPhoto = false;
  DateTime? _capturedDateTime;
  bool _isTakingPhoto = false;

  // Animation controller for shutter flash
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  final TextEditingController _notesController = TextEditingController(
    text: 'Presensi kehadiran operasional Kantor Tirtafield Tanjung Pinang',
  );
  final TextEditingController _lateReasonController = TextEditingController();

  bool _isSubmitting = false;

  static const String _photoUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAZYeBkPw4X6YbUMVThN8ZLdaDSM0yMMkiI6b11L5wW0kFYfuimQSTd3wzc8wk7AMPYmESX3bSnmrL1HE9Jy9PIpISRttZnRERF7lxBX56J50KwkOlmXyqlf7fJeXSgQ9wwCWkLcyeNXC_ZcoWYXygZV3PhN1enRGtRKfGx0_IsqccyGL_TtqGecv8ydzzaX9VrJyOoY6ATXkkOSfplGaKo-LS_yHXUWBX_2EXQPcr2-Z5N34b3bRA';

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // Camera flash animation
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 0.90).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flashController.dispose();
    _notesController.dispose();
    _lateReasonController.dispose();
    super.dispose();
  }

  // Trigger taking the selfie
  void _onCaptureSelfie() {
    if (_isTakingPhoto) return;

    setState(() {
      _isTakingPhoto = true;
      _capturedDateTime = DateTime.now();
    });

    // Shutter flash animation
    _flashController.forward().then((_) {
      _flashController.reverse();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isTakingPhoto = false;
          _hasCapturedPhoto = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.tertiaryContainer,
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Swafoto berhasil diambil & stempel verifikasi tercetak!',
                  ),
                ),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  // Retake photo: return to live camera mode
  void _onRetakePhoto() {
    setState(() {
      _hasCapturedPhoto = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primary,
        content: Row(
          children: [
            Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Kamera aktif. Silakan ambil swafoto baru di area penugasan.',
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }



  Future<void> _onSubmitAttendance() async {
    final authProvider = context.read<AuthProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();
    final settingsProvider = context.read<SystemSettingsProvider>();
    final user = authProvider.currentUser;

    final checkTime = _capturedDateTime ?? _currentTime;
    final isLate = widget.slotType == AttendanceSlotType.masuk &&
        settingsProvider.operationalHours.isLateForCheckIn(checkTime);
    final lateReason = _lateReasonController.text.trim();
    final lateMinutes = settingsProvider.operationalHours.getLateDurationMinutes(checkTime);

    if (isLate && lateReason.isEmpty) {
      _showMandatoryLateReasonDialog(
        context,
        lateMinutes,
        settingsProvider.operationalHours.masuk,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final latePrefix = isLate ? '[TERLAMBAT ($lateMinutes mnt): $lateReason] ' : '';
    final distancePrefix = '[Presensi Lapangan: ${widget.distanceHq} ke ${widget.targetOfficeName}] ';
    final effectiveNotes = '$latePrefix$distancePrefix${_notesController.text.trim()}'.trim();

    final success = await attendanceProvider.performAttendance(
      user: user,
      slotType: widget.slotType,
      location: widget.projectLocation,
      notes: effectiveNotes,
      latitude: widget.latitude,
      longitude: widget.longitude,
      distanceHq: widget.distanceHq,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      final displayTime = _capturedDateTime ?? _currentTime;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BuktiPresensiBerhasilScreen(
            slotType: widget.slotType,
            slotTitle: widget.slotTitle,
            projectLocation: widget.projectLocation,
            projectAddress: widget.projectAddress,
            distanceHq: widget.distanceHq,
            isWithinRadius: widget.isWithinRadius,
            targetOfficeName: widget.targetOfficeName,
            targetOfficeType: widget.targetOfficeType,
            latitude: widget.latitude,
            longitude: widget.longitude,
            coordinates: widget.coordinates,
            capturedDateTime: displayTime,
            photoUrl: _photoUrl,
            isLate: isLate,
            lateReason: isLate ? lateReason : null,
            lateDurationMinutes: isLate ? lateMinutes : 0,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            attendanceProvider.errorMessage ?? 'Gagal menyimpan presensi.',
          ),
        ),
      );
    }
  }

  void _showMandatoryLateReasonDialog(
    BuildContext context,
    int lateMinutes,
    String scheduledMasuk,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final reasonDialogController =
            TextEditingController(text: _lateReasonController.text);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.surfaceContainerLowest,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFD97706), size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alasan Keterlambatan Wajib Diisi',
                  style:
                      TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Text(
                  'Anda tercatat terlambat $lateMinutes menit dari batas jam operasional ($scheduledMasuk WIB). Sesuai ketentuan, Anda wajib memberikan alasan keterlambatan sebelum presensi dapat disimpan.',
                  style:
                      const TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Alasan Keterlambatan:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonDialogController,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText:
                      'Contoh: Penanganan darurat kebocoran pipa / kendala cuaca buruk...',
                  hintStyle:
                      const TextStyle(fontSize: 12, color: AppColors.outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonDialogController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Alasan keterlambatan tidak boleh kosong!'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                setState(() {
                  _lateReasonController.text = reason;
                });
                _onSubmitAttendance();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan & Kirim Presensi'),
            ),
          ],
        );
      },
    );
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildTopAppBar(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Viewfinder: either Live Camera or Captured Result
                    if (!_hasCapturedPhoto)
                      _buildLiveCameraViewfinder()
                    else
                      _buildCapturedSelfieResultViewfinder(),

                    const SizedBox(height: 16),

                    // Controls depending on whether photo is already taken
                    if (!_hasCapturedPhoto)
                      _buildShutterControls()
                    else ...[
                      // Geofencing & Location Verification Bento Module
                      _buildBentoVerificationModule(),
                      const SizedBox(height: 16),
                      // Primary Submission Button & Action Controls
                      _buildSubmissionActionButtons(),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Camera flash overlay animation
          AnimatedBuilder(
            animation: _flashAnimation,
            builder: (context, child) {
              if (_flashAnimation.value == 0) return const SizedBox.shrink();
              return Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.white.withValues(alpha: _flashAnimation.value),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // TOP CONTEXT APP BAR
  PreferredSizeWidget _buildTopAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLowest,
      elevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.onSurface,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _hasCapturedPhoto ? 'Hasil Swafoto' : 'Ambil Swafoto',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _hasCapturedPhoto
                      ? AppColors.tertiaryContainer
                      : AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  _hasCapturedPhoto
                      ? 'Foto & Stempel Lokasi Siap Dikirim'
                      : 'Posisikan kamera swafoto di lokasi tugas',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _hasCapturedPhoto
                        ? AppColors.secondary
                        : AppColors.onSurfaceVariant,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ],
    );
  }

  // 1A. LIVE CAMERA VIEWFINDER (BEFORE CAPTURE)
  Widget _buildLiveCameraViewfinder() {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131B2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.20),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Simulated Live Camera Feed
              Positioned.fill(
                child: Image.network(
                  _photoUrl,
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.15),
                  colorBlendMode: BlendMode.darken,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.face_retouching_natural_rounded,
                          size: 72,
                          color: AppColors.secondaryFixed,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Vignette Gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Live Top Bar Info Pill
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.videocam_rounded,
                              color: AppColors.tertiaryFixed,
                              size: 15,
                            ),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Kamera Depan',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.gps_fixed_rounded,
                            color: AppColors.tertiaryFixed,
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'GPS Terkunci',
                            style: TextStyle(
                              color: AppColors.tertiaryFixed,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Camera Viewfinder Frame
              Center(
                child: Container(
                  width: 240,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.tertiaryFixed.withValues(alpha: 0.85),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tertiaryFixed.withValues(alpha: 0.15),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.filter_center_focus_rounded,
                      size: 42,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ),

              // Bottom Overlay Hint
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.tertiaryFixed,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Posisikan kamera untuk swafoto di lokasi tugas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
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
    );
  }

  // 1B. CAPTURED SELFIE RESULT VIEWFINDER (WITH PROMINENT WATERMARK STAMP)
  Widget _buildCapturedSelfieResultViewfinder() {
    final stampTime = _capturedDateTime ?? _currentTime;
    final hours = stampTime.hour.toString().padLeft(2, '0');
    final minutes = stampTime.minute.toString().padLeft(2, '0');
    final seconds = stampTime.second.toString().padLeft(2, '0');
    final timeStr = '$hours:$minutes:$seconds';

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.inverseSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.tertiaryFixed.withValues(alpha: 0.8),
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.25),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Captured Photo Image
              Positioned.fill(
                child: Image.network(
                  _photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.face_retouching_natural_rounded,
                          size: 72,
                          color: AppColors.tertiaryFixed,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Vignette Scrim
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.inverseSurface.withValues(alpha: 0.55),
                        Colors.transparent,
                        AppColors.inverseSurface.withValues(alpha: 0.92),
                      ],
                      stops: const [0.0, 0.35, 1.0],
                    ),
                  ),
                ),
              ),

              // Top Overlay: Liveness Verified Pill & Security Badge
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inverseSurface.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.tertiaryFixed,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Swafoto Siap',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.inverseSurface.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.tertiaryFixed,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Subtle Corner Brackets HUD Framing
              Center(
                child: SizedBox(
                  width: 210,
                  height: 220,
                  child: Stack(
                    children: [
                      // Top Left Bracket
                      Align(
                        alignment: Alignment.topLeft,
                        child: _buildCornerBracket(isTop: true, isLeft: true),
                      ),
                      // Top Right Bracket
                      Align(
                        alignment: Alignment.topRight,
                        child: _buildCornerBracket(isTop: true, isLeft: false),
                      ),
                      // Bottom Left Bracket
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: _buildCornerBracket(isTop: false, isLeft: true),
                      ),
                      // Bottom Right Bracket
                      Align(
                        alignment: Alignment.bottomRight,
                        child: _buildCornerBracket(isTop: false, isLeft: false),
                      ),
                    ],
                  ),
                ),
              ),

              // PROMINENT WATERMARK STAMP DIRECTLY ON PHOTO
              // Contains: 1. Timestamp, 2. Lokasi, 3. Radius Jarak Lapangan dari Kantor Utama
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.inverseSurface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.tertiaryFixed.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Badge: Official Watermark Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.verified_user_rounded,
                                  size: 13,
                                  color: AppColors.tertiaryFixed,
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'BUKTI PRESENSI RESMI KORPORAT',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.tertiaryFixed,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.tertiaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.tertiaryFixed.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'ANTI-FAKE GPS',
                              style: TextStyle(
                                color: AppColors.tertiaryFixed,
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 6),

                      // 1. TIMESTAMP ROW
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: AppColors.tertiaryFixed,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${DateTimeHelper.formatIndonesianDate(stampTime)} • $timeStr WIB',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // 2. LOKASI ROW
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: AppColors.tertiaryFixed,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.projectLocation,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.projectAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 9.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // 3. RADIUS JARAK DARI KANTOR UTAMA ROW
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.straighten_rounded,
                            size: 13,
                            color: AppColors.tertiaryFixed,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    '${widget.distanceHq} dari ${widget.targetOfficeName}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.tertiaryFixed,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Jarak: ${widget.distanceHq} ke ${widget.targetOfficeName}',
                                  style: const TextStyle(
                                    color: AppColors.tertiaryFixed,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (widget.coordinates != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.gps_fixed_rounded,
                              size: 11,
                              color: AppColors.tertiaryFixedDim,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'GPS: ${widget.coordinates}',
                              style: const TextStyle(
                                color: AppColors.tertiaryFixedDim,
                                fontSize: 9.5,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  // HUD Corner Bracket
  Widget _buildCornerBracket({required bool isTop, required bool isLeft}) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: AppColors.tertiaryFixed, width: 3.0)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: AppColors.tertiaryFixed, width: 3.0)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: AppColors.tertiaryFixed, width: 3.0)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: AppColors.tertiaryFixed, width: 3.0)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(6) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(6) : Radius.zero,
          bottomLeft: !isTop && isLeft ? const Radius.circular(6) : Radius.zero,
          bottomRight: !isTop && !isLeft ? const Radius.circular(6) : Radius.zero,
        ),
      ),
    );
  }

  // SHUTTER CONTROLS (PHASE 1: BEFORE TAKING PHOTO)
  Widget _buildShutterControls() {
    return Column(
      children: [
        // Camera Guidance Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.light_mode_rounded,
                color: Color(0xFFEAB308),
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pastikan swafoto diambil dengan jelas di lokasi tugas dan pencahayaan cukup.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Shutter Button Row
        Center(
          child: Column(
            children: [
              GestureDetector(
                key: const ValueKey('capture_selfie_button'),
                onTap: _isTakingPhoto ? null : _onCaptureSelfie,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: AppColors.secondary,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary,
                      ),
                      child: Center(
                        child: _isTakingPhoto
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ambil Swafoto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Tekan tombol kamera untuk mengambil foto',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. GEOFENCING & LOCATION VERIFICATION BENTO MODULE (PHASE 2)
  Widget _buildBentoVerificationModule() {
    final stampTime = _capturedDateTime ?? _currentTime;
    final hours = stampTime.hour.toString().padLeft(2, '0');
    final minutes = stampTime.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryContainer.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.task_alt_rounded,
                        size: 22,
                        color: AppColors.tertiaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Foto & Lokasi Terverifikasi',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Seluruh parameter presensi terverifikasi sah',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixed.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.tertiaryFixed),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: AppColors.tertiaryContainer,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Siap Kirim',
                      style: TextStyle(
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
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEAEDFF)),
          const SizedBox(height: 12),

          // 3-Column Stats Row
          Row(
            children: [
              Expanded(
                child: _buildBentoStatItem(
                  title: 'WAKTU',
                  value: '$hours:$minutes WIB',
                  valueColor: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBentoStatItem(
                  title: 'LOKASI',
                  value: 'Tj. Pinang Timur',
                  valueColor: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBentoStatItem(
                  title: 'JARAK KE KANTOR',
                  value: widget.distanceHq,
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // LATE NOTICE & MANDATORY REASON INPUT
          Builder(
            builder: (context) {
              final settings = context.watch<SystemSettingsProvider>().operationalHours;
              final checkTime = _capturedDateTime ?? _currentTime;
              final isLate = widget.slotType == AttendanceSlotType.masuk &&
                  settings.isLateForCheckIn(checkTime);
              final lateMinutes = settings.getLateDurationMinutes(checkTime);

              if (!isLate) return const SizedBox.shrink();

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFB45309)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Tercatat Terlambat ($lateMinutes Menit)',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB45309),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'WAJIB ALASAN',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Batas jam masuk kantor: ${settings.masuk} WIB (+ toleransi ${settings.toleransiMenit} menit). Anda wajib memberikan alasan keterlambatan sebelum presensi dapat dikirim.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF92400E),
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _lateReasonController,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.onSurface,
                            fontFamily: 'Inter',
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            prefixIcon: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFFB45309)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFF59E0B)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFFCD34D)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFB45309), width: 1.5),
                            ),
                            hintText: 'Tuliskan alasan keterlambatan Anda di sini (wajib)...',
                            hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.outline),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),

          // Editable Note Input Field
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: TextFormField(
              controller: _notesController,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurface,
                fontFamily: 'Inter',
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                prefixIcon: Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                  color: AppColors.outline,
                ),
                border: InputBorder.none,
                hintText: 'Tambahkan catatan kegiatan...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: AppColors.outline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoStatItem({
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.outline,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: valueColor,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  // 3. SUBMISSION CONTROLS (PHASE 2: AFTER TAKING PHOTO)
  Widget _buildSubmissionActionButtons() {
    return Column(
      children: [
        // Primary Gradient Button: Kirim & Simpan Presensi
        SizedBox(
          width: double.infinity,
          height: 54,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _isSubmitting ? null : _onSubmitAttendance,
                child: Center(
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Mengirim Presensi...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Kirim & Simpan Presensi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Secondary Button: Ambil Ulang Foto
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _onRetakePhoto,
            icon: const Icon(
              Icons.replay_rounded,
              size: 18,
              color: AppColors.secondary,
            ),
            label: const Text(
              'Ambil Ulang Foto',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
                fontFamily: 'Inter',
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerLowest,
              side: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.35),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
