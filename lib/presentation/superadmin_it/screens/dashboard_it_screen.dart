import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../state/activity_log_provider.dart';
import '../../../state/approval_provider.dart';
import '../../../state/auth_provider.dart';
import '../../../state/employee_management_provider.dart';
import '../../../state/realtime_monitoring_provider.dart';
import '../../../state/system_settings_provider.dart';
import 'superadmin_activity_log_screen.dart';
import 'superadmin_employee_screen.dart';
import 'superadmin_monitoring_screen.dart';
import 'superadmin_operational_screen.dart';
import 'superadmin_profile_screen.dart';

class DashboardITScreen extends StatefulWidget {
  const DashboardITScreen({super.key});

  @override
  State<DashboardITScreen> createState() => _DashboardITScreenState();
}

class _DashboardITScreenState extends State<DashboardITScreen> {
  int _selectedTabIndex = 0;
  int _operationalSubTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RealtimeMonitoringProvider>().loadRealtimeAttendance();
      context.read<EmployeeManagementProvider>().loadEmployees();
      context.read<ApprovalProvider>().loadAllApprovals();
      context.read<SystemSettingsProvider>().loadSettings();
      context.read<ActivityLogProvider>().refreshLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final user = authProv.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _selectedTabIndex == 3
          ? AppBar(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0.5,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
                onPressed: () => setState(() => _selectedTabIndex = 0),
              ),
              title: const Text(
                'Akun & Profil Superadmin',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            )
          : _buildTopAppBar(context, user),
      body: _buildCurrentTabBody(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildTopAppBar(BuildContext context, UserModel user) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      titleSpacing: 16,
      title: Row(
        children: [
          // Avatar with Online dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.roleStaffIT,
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
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.success,
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.roleStaffIT,
                      size: 15,
                    ),
                  ],
                ),
                Text(
                  '${user.nip} • ${user.position}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.onSurfaceVariant,
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

  Widget _buildAvatarFallback() {
    return Container(
      color: AppColors.surfaceContainer,
      child: const Icon(
        Icons.person,
        size: 20,
        color: AppColors.roleStaffIT,
      ),
    );
  }

  Widget _buildCurrentTabBody() {
    switch (_selectedTabIndex) {
      case 0:
        // Prioritas 1: Monitoring Presensi Realtime & Persetujuan
        return _buildHomeMonitoringPortal();
      case 1:
        // Prioritas 2: Pengaturan Jam Operasional & Lokasi Kantor
        return SuperadminOperationalScreen(
          key: ValueKey('op_subtab_$_operationalSubTabIndex'),
          showAppBar: false,
          initialSubTabIndex: _operationalSubTabIndex,
        );
      case 2:
        // Prioritas 3: Manajemen Peran Akun & Data Pegawai
        return const SuperadminEmployeeScreen(showAppBar: false);
      case 3:
        // Prioritas 4: Akun & Profil Superadmin
        return SuperadminProfileScreen(
          onBackToHome: () => setState(() => _selectedTabIndex = 0),
        );
      default:
        return _buildHomeMonitoringPortal();
    }
  }

  // PORTAL UTAMA: BERANDA DENGAN LIVE METRICS & REALTIME ATTENDANCE FEED
  Widget _buildHomeMonitoringPortal() {
    final empProv = context.watch<EmployeeManagementProvider>();
    final approvalProv = context.watch<ApprovalProvider>();
    final settingsProv = context.watch<SystemSettingsProvider>();
    final logProv = context.watch<ActivityLogProvider>();
    final pendingCount = approvalProv.pendingApprovals.length;
    final officeCount = settingsProv.geofencing.offices.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. WELCOME BANNER & LIVE SYSTEM PULSE
              _buildSuperadminHeroBanner(
                totalEmp: empProv.totalEmployees,
                pendingApprovals: pendingCount,
                officeCount: officeCount,
              ),
              const SizedBox(height: 14),

              // 2. QUICK SHORTCUTS TO CORE MODULES
              const Text(
                'Menu Kontrol Superadmin',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              _buildCoreFeatureGrid(
                pendingCount: pendingCount,
                logCount: logProv.totalCount,
              ),
              const SizedBox(height: 16),

              // 3. MONITORING PRESENSI REALTIME FEED
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Persetujuan & Riwayat Presensi Lapangan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.read<RealtimeMonitoringProvider>().loadRealtimeAttendance();
                        context.read<ApprovalProvider>().loadAllApprovals();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.sync_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Data persetujuan berhasil diperbarui.'),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.secondary,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sync_rounded, size: 14, color: AppColors.secondary),
                            SizedBox(width: 4),
                            Text(
                              'Segarkan',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Feed list inside container
              const SuperadminMonitoringScreen(showAppBar: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuperadminHeroBanner({
    required int totalEmp,
    required int pendingApprovals,
    required int officeCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
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
                  'Pusat Kontrol Superadmin IT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.roleStaffIT.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.roleStaffIT.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, size: 12, color: AppColors.roleStaffIT),
                    SizedBox(width: 4),
                    Text(
                      'Pusimpel Tier 1',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.roleStaffIT,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Sistem Presensi & Kepegawaian Tirta Kepri aktif terhubung ke database lokal.',
            style: TextStyle(fontSize: 11.5, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),

          // Bento Mini Stats
          Row(
            children: [
              Expanded(
                child: _buildBannerStat(
                  label: 'Total Pegawai',
                  value: '$totalEmp',
                  subtext: 'Terdaftar DB',
                  color: AppColors.primary,
                  icon: Icons.people_alt_rounded,
                  onTap: () => setState(() => _selectedTabIndex = 2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBannerStat(
                  label: 'Persetujuan',
                  value: '$pendingApprovals',
                  subtext: pendingApprovals > 0 ? 'Perlu Approval' : 'Semua Beres',
                  color: pendingApprovals > 0 ? AppColors.breakOut : AppColors.success,
                  icon: Icons.assignment_turned_in_rounded,
                  onTap: () => setState(() => _selectedTabIndex = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBannerStat(
                  label: 'Lokasi Kantor',
                  value: '$officeCount Titik',
                  subtext: 'Acuan Penempatan',
                  color: AppColors.secondary,
                  icon: Icons.apartment_rounded,
                  onTap: () => setState(() {
                    _operationalSubTabIndex = 1;
                    _selectedTabIndex = 1;
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStat({
    required String label,
    required String value,
    required String subtext,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Icon(icon, size: 14, color: color),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtext,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AppColors.onSurfaceVariant,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // GRID SHORTCUT MENU KE FITUR SUPERADMIN
  Widget _buildCoreFeatureGrid({
    required int pendingCount,
    required int logCount,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMenuBentoCard(
                icon: Icons.manage_accounts_rounded,
                color: AppColors.roleStaffIT,
                title: 'Peran & Akun',
                subtitle: 'Hak akses 3 role',
                onTap: () => setState(() => _selectedTabIndex = 2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMenuBentoCard(
                icon: Icons.badge_outlined,
                color: AppColors.primary,
                title: 'Data Pegawai',
                subtitle: 'Direktori NIK & Divisi',
                onTap: () => setState(() => _selectedTabIndex = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMenuBentoCard(
                icon: Icons.schedule_rounded,
                color: AppColors.checkIn,
                title: 'Jam Operasional',
                subtitle: '4 absensi & toleransi',
                onTap: () => setState(() {
                  _operationalSubTabIndex = 0;
                  _selectedTabIndex = 1;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMenuBentoCard(
                icon: Icons.apartment_rounded,
                color: AppColors.secondary,
                title: 'Lokasi Kantor',
                subtitle: 'Titik acuan penempatan',
                onTap: () => setState(() {
                  _operationalSubTabIndex = 1;
                  _selectedTabIndex = 1;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildMenuWideCard(
          icon: Icons.receipt_long_rounded,
          color: AppColors.roleStaffIT,
          title: 'Log Aktivitas Sistem',
          subtitle: 'Audit trail, penempatan kantor, perubahan jam kerja & absensi',
          badgeText: '$logCount Entri',
          badgeColor: AppColors.roleStaffIT,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SuperadminActivityLogScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuBentoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.outline.withValues(alpha: 0.6),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.onSurfaceVariant,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuWideCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int pendingCount = 0,
    String? badgeText,
    Color? badgeColor,
  }) {
    final effectiveBadgeColor = badgeColor ?? (pendingCount > 0 ? AppColors.breakOut : AppColors.secondary);
    final hasBadge = (badgeText != null && badgeText.isNotEmpty) || pendingCount > 0;
    final displayedBadgeText = badgeText ?? '$pendingCount Baru';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pendingCount > 0
              ? AppColors.breakOut.withValues(alpha: 0.4)
              : AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: pendingCount > 0
                ? AppColors.breakOut.withValues(alpha: 0.06)
                : const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          if (hasBadge) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: effectiveBadgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                displayedBadgeText,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: effectiveBadgeColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.onSurfaceVariant,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: AppColors.outline, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // BOTTOM NAVIGATION BAR (Exact reference from User Navigation Bar)
  Widget _buildBottomNavigation() {
    final approvalProv = context.watch<ApprovalProvider>();
    final pendingCount = approvalProv.pendingApprovals.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavTab(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                badgeCount: pendingCount,
                isActive: _selectedTabIndex == 0,
                onTap: () => setState(() => _selectedTabIndex = 0),
              ),
              _buildNavTab(
                icon: Icons.tune_rounded,
                label: 'Operasional',
                isActive: _selectedTabIndex == 1,
                onTap: () => setState(() => _selectedTabIndex = 1),
              ),
              _buildNavTab(
                icon: Icons.people_alt_rounded,
                label: 'Pegawai',
                isActive: _selectedTabIndex == 2,
                onTap: () => setState(() => _selectedTabIndex = 2),
              ),
              _buildNavTab(
                icon: Icons.person_rounded,
                label: 'Akun',
                isActive: _selectedTabIndex == 3,
                onTap: () => setState(() => _selectedTabIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab({
    required IconData icon,
    required String label,
    int? badgeCount,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.roleStaffIT.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badgeCount != null && badgeCount > 0,
              label: Text('$badgeCount'),
              backgroundColor: AppColors.warning,
              textColor: Colors.white,
              child: Icon(
                icon,
                size: 20,
                color: isActive ? AppColors.roleStaffIT : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.roleStaffIT : AppColors.onSurfaceVariant,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
