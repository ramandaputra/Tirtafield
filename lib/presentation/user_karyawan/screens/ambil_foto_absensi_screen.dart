import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../data/models/attendance_model.dart';
import '../../../state/attendance_provider.dart';
import '../../../state/auth_provider.dart';
import 'bukti_presensi_berhasil_screen.dart';

class AmbilFotoAbsensiScreen extends StatefulWidget {
  final AttendanceSlotType slotType;
  final String slotTitle;
  final String projectLocation;
  final String projectAddress;
  final String distanceHq;
  final double? latitude;
  final double? longitude;
  final String? coordinates;

  const AmbilFotoAbsensiScreen({
    super.key,
    this.slotType = AttendanceSlotType.istirahatKeluar,
    this.slotTitle = 'Absen Istirahat',
    this.projectLocation = 'Area Proyek Sudirman Office Tower',
    this.projectAddress =
        'Jl. Jenderal Sudirman Kav. 21, Karet Setiabudi, Jakarta Selatan, DKI Jakarta 12920',
    this.distanceHq = '8.5 km',
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

  // Animation controllers for scanning HUD & shutter flash
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  final TextEditingController _notesController = TextEditingController(
    text: 'Presensi penugasan lapangan Proyek Sudirman Office Tower',
  );

  bool _isSubmitting = false;
  double _biometricScore = 99.4;

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

    // Scan line animation (alternates up and down)
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0.10, end: 0.88).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    // Subtle HUD pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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
    _scanController.dispose();
    _pulseController.dispose();
    _flashController.dispose();
    _notesController.dispose();
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
          _biometricScore = 99.4;
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
                    'Foto selfie berhasil diambil & stempel verifikasi tercetak!',
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
                'Kamera aktif. Posisikan kembali wajah Anda untuk foto selfie baru.',
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onHelpPressed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildHelpSheet(ctx),
    );
  }

  Future<void> _onSubmitAttendance() async {
    final authProvider = context.read<AuthProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();
    final user = authProvider.currentUser;

    setState(() => _isSubmitting = true);

    final success = await attendanceProvider.performAttendance(
      user: user,
      slotType: widget.slotType,
      location: widget.projectLocation,
      notes: _notesController.text.trim(),
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
            latitude: widget.latitude,
            longitude: widget.longitude,
            coordinates: widget.coordinates,
            capturedDateTime: displayTime,
            photoUrl: _photoUrl,
            biometricScore: _biometricScore,
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



  Widget _buildHelpSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                color: AppColors.secondary,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Pusat Bantuan Verifikasi Presensi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildHelpItem(
            icon: Icons.camera_alt_rounded,
            title: 'Pengambilan Foto Selfie Wajib',
            desc:
                'Ambil foto selfie di area kerja dengan wajah terlihat jelas. Sistem akan mencetak stempel resmi secara otomatis.',
          ),
          const SizedBox(height: 12),
          _buildHelpItem(
            icon: Icons.pin_drop_rounded,
            title: 'Stempel Telemetri Otomatis',
            desc:
                'Hasil foto selfie langsung memuat timestamp waktu aktual, nama & alamat lokasi proyek, serta jarak radius dari kantor pusat.',
          ),
          const SizedBox(height: 12),
          _buildHelpItem(
            icon: Icons.gpp_good_rounded,
            title: 'Sistem Anti-Fake GPS & Radius 150m',
            desc:
                'Presensi hanya sah jika perangkat berada dalam radius toleransi kerja 150 meter dari titik penugasan.',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceContainer,
                foregroundColor: AppColors.onSurface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mengerti',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
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
                    // Step Indicator Banner
                    _buildStepIndicatorBanner(),
                    const SizedBox(height: 10),

                    // Peringatan Atribut Perusahaan (Sebelum Pengambilan Foto)
                    if (!_hasCapturedPhoto) ...[
                      _buildAttributeWarningBanner(),
                      const SizedBox(height: 12),
                    ],

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

  // STEP INDICATOR BANNER
  Widget _buildStepIndicatorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: _hasCapturedPhoto
            ? AppColors.tertiaryFixed.withValues(alpha: 0.22)
            : AppColors.primaryFixed.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasCapturedPhoto
              ? AppColors.tertiaryFixed
              : AppColors.primaryContainer.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hasCapturedPhoto
                ? Icons.check_circle_rounded
                : Icons.camera_alt_rounded,
            size: 18,
            color: _hasCapturedPhoto
                ? AppColors.tertiaryContainer
                : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _hasCapturedPhoto
                  ? 'Langkah 2 dari 2: Foto & Stempel Terverifikasi Siap Dikirim'
                  : 'Langkah 1 dari 2: Ambil Foto Selfie untuk Memvalidasi Kehadiran',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _hasCapturedPhoto
                    ? AppColors.tertiaryContainer
                    : AppColors.primary,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PERINGATAN ATRIBUT PERUSAHAAN (SEBELUM PENGAMBILAN FOTO)
  Widget _buildAttributeWarningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Soft Amber Alert
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFCD34D), // Amber-300
          width: 1.0,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD97706),
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pastikan anda menggunakan atribut perusahaan',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
                fontFamily: 'Inter',
              ),
            ),
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
            _hasCapturedPhoto ? 'Hasil Foto Selfie' : 'Ambil Foto Selfie',
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
                      ? 'Foto & Stempel Telemetri Siap Dikirim'
                      : 'Posisikan wajah Anda pada kamera depan',
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

              // Live Face Detection Guide Frame (Oval with pulsating guidance)
              Center(
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 210,
                    height: 270,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(105),
                      border: Border.all(
                        color: AppColors.tertiaryFixed.withValues(alpha: 0.85),
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tertiaryFixed.withValues(alpha: 0.25),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Animated Scanning Line
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: 270 * _scanAnimation.value,
                              left: 20,
                              right: 20,
                              child: Container(
                                height: 2,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.tertiaryFixed,
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.tertiaryFixed,
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Center Target Guide Icon
                        const Center(
                          child: Icon(
                            Icons.filter_center_focus_rounded,
                            size: 38,
                            color: Colors.white24,
                          ),
                        ),
                      ],
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
                        Icons.info_outline_rounded,
                        color: AppColors.tertiaryFixed,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Posisikan wajah Anda tegak lurus di dalam bingkai oval',
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
                            'Liveness Valid',
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
                          Icons.verified_rounded,
                          color: AppColors.tertiaryFixed,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Subtle Corner Brackets HUD & Biometric Score Badge
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
                      // Biometric Score Pill
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.inverseSurface.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.tertiaryFixed),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.done_all_rounded,
                                size: 14,
                                color: AppColors.tertiaryFixed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'VALID $_biometricScore%',
                                style: const TextStyle(
                                  color: AppColors.tertiaryFixed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
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
                                    '${widget.distanceHq} dari Kantor Pusat (HQ)',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.tertiaryFixed,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Radius 150m: Valid',
                                  style: TextStyle(
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
                  'Pastikan wajah Anda mendapat cahaya yang cukup dan tidak menggunakan masker atau penutup wajah.',
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
                'Ambil Foto Selfie',
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
                            'Seluruh parameter absensi valid & tersertifikasi',
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
                  value: 'Proyek Sudirman',
                  valueColor: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBentoStatItem(
                  title: 'JARAK HQ',
                  value: '${widget.distanceHq} (Valid)',
                  valueColor: AppColors.tertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

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

        // 2 Secondary Buttons: Ambil Ulang Foto & Pusat Bantuan
        Row(
          children: [
            // Ambil Ulang Foto Button
            Expanded(
              child: SizedBox(
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
            ),
            const SizedBox(width: 10),

            // Pusat Bantuan Button
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _onHelpPressed,
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    size: 18,
                    color: AppColors.outline,
                  ),
                  label: const Text(
                    'Pusat Bantuan',
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
            ),
          ],
        ),
      ],
    );
  }
}
