import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../state/attendance_provider.dart';
import '../../../state/auth_provider.dart';
import '../widgets/corporate_attendance_cards.dart';
import '../widgets/corporate_hero_clock.dart';
import 'akun_karyawan_screen.dart';

class HomeKaryawanScreen extends StatefulWidget {
  const HomeKaryawanScreen({super.key});

  @override
  State<HomeKaryawanScreen> createState() => _HomeKaryawanScreenState();
}

class _HomeKaryawanScreenState extends State<HomeKaryawanScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      context.read<AttendanceProvider>().loadTodayAttendance(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final user = authProv.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _selectedTabIndex == 0
          ? _buildTopAppBar(context, user)
          : _buildAkunAppBar(),
      body: _selectedTabIndex == 0
          ? _buildBerandaContent(context, user)
          : AkunKaryawanScreen(
              onBackToHome: () => setState(() => _selectedTabIndex = 0),
            ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // TOP APP BAR BERANDA: Matching <header class="bg-surface sticky top-0 ...">
  PreferredSizeWidget _buildTopAppBar(BuildContext context, UserModel user) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      titleSpacing: 16,
      title: Row(
        children: [
          // User Avatar with Online Status Dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surfaceContainerHigh,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: user.avatarUrl != null
                      ? Image.network(
                          user.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                        )
                      : _buildAvatarFallback(),
                ),
              ),
              // Online Indicator Ring Dot
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceContainerLowest,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Corporate Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TIRTAFIELD',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: -0.2,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${user.name} · ${user.nip}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Notification button with red indicator dot
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Stack(
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tidak ada notifikasi baru hari ini.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.onSurfaceVariant,
                  size: 24,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // TOP APP BAR FOR AKUN TAB (Matching: Akun & Profil Header)
  PreferredSizeWidget _buildAkunAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.onSurface,
        ),
        onPressed: () {
          setState(() => _selectedTabIndex = 0);
        },
      ),
      title: const Text(
        'Akun & Profil',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          fontFamily: 'Inter',
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tidak ada notifikasi sistem baru.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // BERANDA CONTENT (Hero Clock + 4 Sesi Presensi)
  Widget _buildBerandaContent(BuildContext context, UserModel user) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<AttendanceProvider>().loadTodayAttendance(user);
      },
      child: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO DIGITAL CLOCK CARD
            CorporateHeroClock(),
            SizedBox(height: 16),

            // 2. 4 DEDICATED ATTENDANCE ACTIONS
            CorporateAttendanceCards(),
          ],
        ),
      ),
    );
  }

  // BOTTOM NAVIGATION: Only Beranda and Akun (as requested)
  Widget _buildBottomNavigation() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppColors.surfaceContainer, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Tab 1: Beranda
            _buildNavTab(
              icon: Icons.home_rounded,
              label: 'Beranda',
              isActive: _selectedTabIndex == 0,
              onTap: () {
                setState(() => _selectedTabIndex = 0);
              },
            ),
            // Tab 2: Akun
            _buildNavTab(
              icon: Icons.person_rounded,
              label: 'Akun',
              isActive: _selectedTabIndex == 1,
              onTap: () {
                setState(() => _selectedTabIndex = 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.secondary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color:
                    isActive ? AppColors.secondary : AppColors.onSurfaceVariant,
                fontFamily: 'Inter',
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: AppColors.surfaceContainer,
      child: const Icon(
        Icons.person,
        size: 20,
        color: AppColors.primary,
      ),
    );
  }
}
