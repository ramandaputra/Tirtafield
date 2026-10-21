import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../state/auth_provider.dart';
import '../../auth/login_screen.dart';

class AkunKaryawanScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const AkunKaryawanScreen({
    super.key,
    this.onBackToHome,
  });

  @override
  State<AkunKaryawanScreen> createState() => _AkunKaryawanScreenState();
}

class _AkunKaryawanScreenState extends State<AkunKaryawanScreen> {
  late TextEditingController _nameController;
  late TextEditingController _divisionController;
  late TextEditingController _positionController;
  bool _reminderEnabled = true;

  static const String _defaultAvatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBHnouN4NhcfWmjDbG_twFO6sebw3bZ18Eh5o0S5X77EHF5sjwqdJN1_ReCmIRAXuAloD9dPZQaPaz6HVgpuNpNvmO58tfZnPqD0S2Or68H_L0RpASTtBWA4c84ApGfNtIT2D9Dp8lVoCp0JDnad7J_CE3txa5AZ09a1vR9wuxu1NBIUFtj4kKAYnne-NzoAjd5q04Al1Cu_2jIhmMuPgiIkaTQw-LExIXsFQapZNGSTxquu43ZR8o';

  UserModel? _lastSyncedUser;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user.name);
    _divisionController = TextEditingController(text: user.department);
    _positionController = TextEditingController(text: user.position);
    _lastSyncedUser = user;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthProvider>().currentUser;
    if (_lastSyncedUser?.id != user.id ||
        _lastSyncedUser?.name != user.name ||
        _lastSyncedUser?.department != user.department ||
        _lastSyncedUser?.position != user.position) {
      _nameController.text = user.name;
      _divisionController.text = user.department;
      _positionController.text = user.position;
      _lastSyncedUser = user;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _divisionController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.inverseSurface,
        elevation: 6,
        margin: const EdgeInsets.fromLTRB(32, 0, 32, 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.tertiaryFixed,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.inverseOnSurface,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _saveProfile() async {
    final authProv = context.read<AuthProvider>();
    final isSuperadmin = authProv.isStaffIT;
    final currentUser = authProv.currentUser;

    if (!isSuperadmin) {
      _showSuccessToast('Pengaturan preferensi akun Anda berhasil disimpan.');
      return;
    }

    final newName = _nameController.text.trim();
    final newDept = _divisionController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama lengkap tidak boleh kosong.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await authProv.updateUserInfoBySuperadmin(
      targetUserId: currentUser.id,
      newName: newName,
      newDepartment: newDept,
    );

    _showSuccessToast('Data kepegawaian berhasil diperbarui oleh Superadmin.');
  }

  void _showChangePhotoSheet() {
    final authProv = context.read<AuthProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Foto Profil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      fontFamily: 'Inter',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Opsi 1: Ambil Foto
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  final cameraPhotos = [
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
                    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
                  ];
                  final picked =
                      cameraPhotos[DateTime.now().second % cameraPhotos.length];
                  await authProv.updateProfilePhoto(picked);
                  _showSuccessToast('Foto profil baru berhasil diambil dari kamera.');
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ambil Foto',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                                fontFamily: 'Inter',
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Gunakan kamera langsung untuk mengambil foto profil',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.outline,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Opsi 2: Ambil dari Galeri
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  final galleryPhotos = [
                    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
                    'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=400&q=80',
                    'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=400&q=80',
                  ];
                  final picked =
                      galleryPhotos[DateTime.now().minute % galleryPhotos.length];
                  await authProv.updateProfilePhoto(picked);
                  _showSuccessToast('Foto profil berhasil dipilih dari galeri.');
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.photo_library_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ambil dari Galeri',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                                fontFamily: 'Inter',
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pilih berkas foto dari galeri penyimpanan perangkat',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.outline,
                        size: 20,
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

  void _showChangePinDialog() {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: AppColors.secondary, size: 22),
                SizedBox(width: 8),
                Text(
                  'Ubah PIN Presensi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masukkan PIN lama Anda terlebih dahulu untuk verifikasi keamanan sebelum menetapkan PIN baru:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                        fontFamily: 'Inter',
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Kotak Pesan Error (Jika ada)
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB91C1C),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Field 1: PIN Lama
                    const Text(
                      'PIN Lama',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: oldPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: obscureOld,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        letterSpacing: 3,
                      ),
                      decoration: InputDecoration(
                        hintText: 'PIN Lama (6 digit)',
                        hintStyle: const TextStyle(letterSpacing: 0, fontSize: 12),
                        prefixIcon: const Icon(Icons.lock_clock_rounded, color: AppColors.secondary, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureOld ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 18,
                            color: AppColors.outline,
                          ),
                          onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                        ),
                        counterText: '',
                        fillColor: AppColors.background,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Field 2: PIN Baru
                    const Text(
                      'PIN Baru',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: newPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: obscureNew,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        letterSpacing: 3,
                      ),
                      decoration: InputDecoration(
                        hintText: 'PIN Baru (6 digit)',
                        hintStyle: const TextStyle(letterSpacing: 0, fontSize: 12),
                        prefixIcon: const Icon(Icons.pin_rounded, color: AppColors.secondary, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 18,
                            color: AppColors.outline,
                          ),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                        counterText: '',
                        fillColor: AppColors.background,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Field 3: Konfirmasi PIN Baru
                    const Text(
                      'Konfirmasi PIN Baru',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: confirmPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: obscureConfirm,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        letterSpacing: 3,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Konfirmasi PIN Baru (6 digit)',
                        hintStyle: const TextStyle(letterSpacing: 0, fontSize: 12),
                        prefixIcon: const Icon(Icons.verified_user_outlined, color: AppColors.secondary, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 18,
                            color: AppColors.outline,
                          ),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                        counterText: '',
                        fillColor: AppColors.background,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(fontFamily: 'Inter')),
              ),
              ElevatedButton(
                onPressed: () async {
                  final oldPin = oldPinController.text.trim();
                  final newPin = newPinController.text.trim();
                  final confirmPin = confirmPinController.text.trim();

                  if (oldPin.isEmpty) {
                    setDialogState(() => errorMessage = 'PIN lama wajib diisi.');
                    return;
                  }
                  if (newPin.isEmpty) {
                    setDialogState(() => errorMessage = 'PIN baru wajib diisi.');
                    return;
                  }
                  if (newPin.length < 6) {
                    setDialogState(() => errorMessage = 'PIN baru harus 6 digit angka.');
                    return;
                  }
                  if (newPin == oldPin) {
                    setDialogState(() => errorMessage = 'PIN baru tidak boleh sama dengan PIN lama.');
                    return;
                  }
                  if (newPin != confirmPin) {
                    setDialogState(() => errorMessage = 'Konfirmasi PIN baru tidak sesuai.');
                    return;
                  }

                  final authProv = context.read<AuthProvider>();
                  final success = await authProv.changePin(oldPin: oldPin, newPin: newPin);
                  if (!success) {
                    setDialogState(() => errorMessage = 'PIN lama tidak sesuai. Silakan periksa kembali.');
                    return;
                  }

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    _showSuccessToast('PIN Presensi berhasil diperbarui.');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Simpan PIN Baru',
                  style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog(AuthProvider authProv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar dari Akun',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
            fontFamily: 'Inter',
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari sesi aplikasi saat ini?',
          style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              authProv.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final user = authProv.currentUser;
    final isSuperadmin = authProv.isStaffIT;
    final avatarUrl = user.avatarUrl ?? _defaultAvatarUrl;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HERO CARD: PROFILE OVERVIEW & BIOMETRIC PHOTO BADGE
              _buildHeroProfileCard(user, avatarUrl),
              const SizedBox(height: 14),

              // 2. FORM SECTION: DETAILED EMPLOYEE DATA
              _buildFormSection(isSuperadmin),
              const SizedBox(height: 14),

              // 3. PREFERENCES & SETTINGS MODULE
              _buildPreferencesSection(),
              const SizedBox(height: 16),

              // 4. ACTION BUTTONS (SAVE & LOGOUT)
              _buildActionButtons(authProv, isSuperadmin),
            ],
          ),
        ),
      ),
    );
  }

  // 1. HERO PROFILE CARD
  Widget _buildHeroProfileCard(UserModel user, String avatarUrl) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Ambient decorative gradient circle
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: 0.08),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with Upload Camera Button
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: _showChangePhotoSheet,
                        child: Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                              colors: [
                                AppColors.secondary,
                                AppColors.tertiaryFixedDim,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.surfaceContainer,
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Tooltip(
                          message: 'Ubah Foto Profil',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showChangePhotoSheet,
                              borderRadius: BorderRadius.circular(16),
                              child: Ink(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.surfaceContainerLowest,
                                    width: 2.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.18),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.photo_camera_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Identity Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isNotEmpty
                              ? user.name
                              : 'Budi Pratama',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 3),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              fontFamily: 'Inter',
                            ),
                            children: [
                              const TextSpan(text: 'NIK: '),
                              TextSpan(
                                text: user.nip.isNotEmpty ? user.nip : '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${user.department.isNotEmpty ? user.department : 'Product & Tech'} - ${user.position.isNotEmpty ? user.position : 'Staff Lapangan'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
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
    );
  }

  // 2. FORM SECTION: DETAILED EMPLOYEE DATA
  Widget _buildFormSection(bool isSuperadmin) {
    final user = context.watch<AuthProvider>().currentUser;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Kepegawaian',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 14),

          // Field 1: Nama Lengkap
          const Text(
            'Nama Lengkap',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            readOnly: true,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface.withValues(alpha: 0.8),
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.badge_rounded,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
              suffixIcon: const Tooltip(
                message: 'Hanya admin yang dapat merubah',
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.outline,
                ),
              ),
              helperText: 'Hanya admin yang dapat merubah',
              helperStyle: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
                fontFamily: 'Inter',
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryContainer,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Field 2: Bidang
          const Text(
            'Bidang',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _divisionController,
            readOnly: true,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface.withValues(alpha: 0.8),
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.business_outlined,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
              suffixIcon: const Tooltip(
                message: 'Hanya admin yang dapat merubah',
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.outline,
                ),
              ),
              helperText: 'Hanya admin yang dapat merubah',
              helperStyle: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
                fontFamily: 'Inter',
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryContainer,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Field 3: Seksi Bidang
          const Text(
            'Seksi Bidang',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _positionController,
            readOnly: true,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface.withValues(alpha: 0.8),
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.assignment_ind_rounded,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
              suffixIcon: const Tooltip(
                message: 'Hanya admin yang dapat merubah',
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.outline,
                ),
              ),
              helperText: 'Hanya admin yang dapat merubah',
              helperStyle: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
                fontFamily: 'Inter',
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryContainer,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Field 4: Kantor Penempatan (Titik Acuan Radius)
          const Text(
            'Kantor Penempatan (Acuan Radius Presensi)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
              fontFamily: 'Inter',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.apartment_rounded,
                  size: 20,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.officeName.isNotEmpty
                            ? user.officeName
                            : 'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Titik acuan perhitungan jarak dan radius presensi saat di lapangan',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                const Tooltip(
                  message: 'Ditetapkan oleh Superadmin',
                  child: Icon(
                    Icons.verified_rounded,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Security / Change PIN Row Button
          InkWell(
            onTap: _showChangePinDialog,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pin_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubah PIN Presensi & Keamanan',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Terakhir diubah 30 hari yang lalu',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.outline,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. PREFERENCES & SETTINGS MODULE
  Widget _buildPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengaturan & Preferensi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),

          // Attendance Reminder Toggle
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.alarm_rounded,
                  size: 19,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifikasi Pengingat Presensi',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Alarm 15 menit sebelum jam kerja',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _reminderEnabled,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.secondary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.surfaceContainerHighest,
                onChanged: (val) {
                  setState(() => _reminderEnabled = val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. ACTION BUTTONS (SAVE & LOGOUT)
  Widget _buildActionButtons(AuthProvider authProv, bool isSuperadmin) {
    return Column(
      children: [
        // Hanya Superadmin yang memiliki tombol simpan data (karena nama & divisi dapat diedit)
        if (isSuperadmin) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(
                Icons.save_rounded,
                size: 20,
                color: Colors.white,
              ),
              label: const Text(
                'Simpan Perubahan Data (Superadmin)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: AppColors.secondary.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Tombol Keluar dari Akun
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () => _showLogoutDialog(authProv),
            icon: const Icon(
              Icons.logout_rounded,
              size: 18,
              color: AppColors.error,
            ),
            label: const Text(
              'Keluar dari Akun',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
                fontFamily: 'Inter',
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerLowest,
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Footer Caption
        const Text(
          'Dikembangkan Oleh PUSIMPEL TIRTA KEPRI',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.2,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
