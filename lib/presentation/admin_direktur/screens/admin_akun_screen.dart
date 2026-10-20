import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../state/auth_provider.dart';
import '../../auth/login_screen.dart';

class AdminAkunScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onBackToHome;

  const AdminAkunScreen({
    super.key,
    this.showAppBar = true,
    this.onBackToHome,
  });

  @override
  State<AdminAkunScreen> createState() => _AdminAkunScreenState();
}

class _AdminAkunScreenState extends State<AdminAkunScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _divisionController;
  late TextEditingController _positionController;
  late TextEditingController _phoneController;

  bool _presenceAlertsEnabled = true;
  bool _approvalAlertsEnabled = true;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const String _defaultAdminAvatar =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAY_9kE1y44LkWkF_5c4gS_T9uF6N9qM4o8k_2_wXz7qA';

  UserModel? _lastSyncedUser;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user.name);
    _divisionController = TextEditingController(text: user.department);
    _positionController = TextEditingController(text: user.position);
    _phoneController = TextEditingController(text: user.phone);
    _lastSyncedUser = user;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthProvider>().currentUser;
    if (_lastSyncedUser?.id != user.id ||
        _lastSyncedUser?.name != user.name ||
        _lastSyncedUser?.department != user.department ||
        _lastSyncedUser?.position != user.position ||
        _lastSyncedUser?.phone != user.phone) {
      _nameController.text = user.name;
      _divisionController.text = user.department;
      _positionController.text = user.position;
      _phoneController.text = user.phone;
      _lastSyncedUser = user;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _divisionController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _pulseController.dispose();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
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

    final newName = _nameController.text.trim();
    final newDept = _divisionController.text.trim();
    final newPos = _positionController.text.trim();
    final newPhone = _phoneController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama lengkap tidak boleh kosong.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await authProv.updateCurrentUserProfile(
      newName: newName,
      newDepartment: newDept,
      newPosition: newPos,
      newPhone: newPhone,
    );

    _showSuccessToast('Pengaturan profil akun Admin berhasil disimpan.');
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
                    'Pilih Foto Profil Admin',
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

              // Opsi 1: Kamera Langsung
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  final cameraPhotos = [
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
                    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
                    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=400&q=80',
                  ];
                  final picked =
                      cameraPhotos[DateTime.now().second % cameraPhotos.length];
                  await authProv.updateProfilePhoto(picked);
                  _showSuccessToast('Foto profil Admin berhasil diambil dari kamera.');
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
                              'Ambil Foto Kamera',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                                fontFamily: 'Inter',
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Gunakan kamera untuk mengambil foto profil resmi',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.onSurfaceVariant,
                                fontFamily: 'Inter',
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

              // Opsi 2: Unggah Galeri
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  final galleryPhotos = [
                    'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=400&q=80',
                    'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=400&q=80',
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
                  ];
                  final picked =
                      galleryPhotos[DateTime.now().second % galleryPhotos.length];
                  await authProv.updateProfilePhoto(picked);
                  _showSuccessToast('Foto profil Admin berhasil diperbarui dari galeri.');
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
                          Icons.photo_library_rounded,
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
                              'Pilih dari Galeri',
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
                                fontFamily: 'Inter',
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
                  'Ubah PIN Otorisasi Admin',
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
                      'Masukkan PIN otorisasi lama Anda terlebih dahulu untuk verifikasi keamanan sebelum menetapkan PIN baru:',
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
                    _showSuccessToast('PIN Otorisasi Admin Direktur berhasil diperbarui.');
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
          'Keluar dari Akun Admin',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
            fontFamily: 'Inter',
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari sesi Admin Direktur saat ini?',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(fontFamily: 'Inter')),
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
            child: const Text(
              'Ya, Keluar',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final user = authProv.currentUser;
    final avatarUrl = user.avatarUrl ?? _defaultAdminAvatar;

    final content = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HERO CARD: PROFILE OVERVIEW & AVATAR
              _buildHeroProfileCard(user, avatarUrl),
              const SizedBox(height: 14),

              // 2. FORM SECTION: DETAILED ADMIN DATA
              _buildFormSection(user),
              const SizedBox(height: 14),

              // 3. PREFERENCES & SETTINGS MODULE
              _buildPreferencesSection(),
              const SizedBox(height: 16),

              // 4. ACTION BUTTONS (SAVE, ROLE SWITCHER, LOGOUT)
              _buildActionButtons(authProv),
            ],
          ),
        ),
      ),
    );

    if (!widget.showAppBar) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        leading: widget.onBackToHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
                onPressed: widget.onBackToHome,
              )
            : null,
        title: const Text(
          'Akun & Profil Admin',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
            onPressed: () => _showLogoutDialog(authProv),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: content,
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
                  color: AppColors.roleDirektur.withValues(alpha: 0.08),
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
                                AppColors.roleDirektur,
                                AppColors.secondary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.roleDirektur.withValues(alpha: 0.25),
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
                                  color: AppColors.roleDirektur,
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name
                                    : 'Abdul Kholik, S.T.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.verified_rounded,
                              color: AppColors.roleDirektur,
                              size: 18,
                            ),
                          ],
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
                                text: user.nip.isNotEmpty ? user.nip : 'D001',
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
                          '${user.department} - ${user.position}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Pulsing status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryContainer.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.tertiaryContainer.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: AppColors.tertiaryContainer,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.tertiaryContainer.withValues(
                                            alpha: _pulseAnimation.value > 1.0 ? 0.5 : 0.1,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Admin Direktur (Aktif)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tertiaryContainer,
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
          ],
        ),
      ),
    );
  }

  // 2. FORM SECTION: DETAILED ADMIN DATA
  Widget _buildFormSection(UserModel user) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Informasi Kepegawaian Admin',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Akses Direktur',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.roleDirektur,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),


          // Field 1: Nama Lengkap
          _buildFieldRow(
            label: 'Nama Lengkap',
            controller: _nameController,
            prefixIcon: Icons.badge_rounded,
          ),
          const SizedBox(height: 14),

          // Field 2: Divisi Penempatan
          _buildFieldRow(
            label: 'Divisi Penempatan',
            controller: _divisionController,
            prefixIcon: Icons.business_outlined,
          ),
          const SizedBox(height: 14),

          // Field 3: Jabatan Resmi
          _buildFieldRow(
            label: 'Jabatan Resmi',
            controller: _positionController,
            prefixIcon: Icons.admin_panel_settings_outlined,
          ),
          const SizedBox(height: 14),

          // Field 4: Nomor WhatsApp / HP
          _buildFieldRow(
            label: 'Nomor WhatsApp / HP',
            controller: _phoneController,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),

          // Field 5: Kantor Penempatan (Titik Acuan)
          Row(
            children: [
              const Expanded(
                child: Text(
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
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Terkunci',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
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
                  color: AppColors.roleDirektur,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.officeName.isNotEmpty
                            ? user.officeName
                            : 'Kantor Pusat Tirtafield Tanjung Pinang',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Titik acuan operasional dan pemantauan presensi wilayah',
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
                  message: 'Ditetapkan oleh Pusimpel IT',
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

          // Security / Ubah PIN Row Button
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
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubah PIN Otorisasi Direktur',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Terakhir diperbarui 30 hari yang lalu',
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

  Widget _buildFieldRow({
    required String label,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                  fontFamily: 'Inter',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Dapat Diedit',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              prefixIcon,
              size: 20,
              color: AppColors.onSurfaceVariant,
            ),
            suffixIcon: const Icon(
              Icons.edit_rounded,
              size: 18,
              color: AppColors.secondary,
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                color: AppColors.secondary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
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

          // Preference 1: Presensi Alert
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
                  Icons.notifications_active_rounded,
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
                      'Notifikasi Presensi Lapangan',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Peringatan instan presensi di luar radius atau terlambat',
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
                value: _presenceAlertsEnabled,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.secondary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.surfaceContainerHighest,
                onChanged: (val) {
                  setState(() => _presenceAlertsEnabled = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Preference 2: Persetujuan Masuk Alert
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
                  Icons.fact_check_rounded,
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
                      'Notifikasi Persetujuan Masuk',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pemberitahuan saat ada permohonan koreksi atau izin pegawai',
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
                value: _approvalAlertsEnabled,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.secondary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.surfaceContainerHighest,
                onChanged: (val) {
                  setState(() => _approvalAlertsEnabled = val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. ACTION BUTTONS (SAVE, ROLE SWITCHER, LOGOUT)
  Widget _buildActionButtons(AuthProvider authProv) {
    return Column(
      children: [
        // Primary Save Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _saveProfile,
            icon: const Icon(Icons.save_rounded, size: 20, color: Colors.white),
            label: const Text(
              'Simpan Pengaturan Akun Admin',
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
        const SizedBox(height: 12),

        // Demo Role Switcher
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Demo Cepat Ganti Role Pengguna:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          authProv.switchUserByRole(UserRole.karyawan),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '1. Karyawan',
                        style: TextStyle(fontSize: 11, fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          authProv.switchUserByRole(UserRole.direktur),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '2. Direktur',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          authProv.switchUserByRole(UserRole.staffIT),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '3. Staff IT',
                        style: TextStyle(fontSize: 11, fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Logout Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _showLogoutDialog(authProv),
            icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
            label: const Text(
              'Keluar dari Akun Admin',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
                fontFamily: 'Inter',
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
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
