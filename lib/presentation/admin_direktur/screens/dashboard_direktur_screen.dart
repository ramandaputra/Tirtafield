import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../state/approval_provider.dart';
import '../../../state/auth_provider.dart';
import '../../../state/employee_management_provider.dart';
import '../../../state/realtime_monitoring_provider.dart';
import 'admin_akun_screen.dart';
import 'admin_monitoring_screen.dart';

class DashboardDirekturScreen extends StatefulWidget {
  const DashboardDirekturScreen({super.key});

  @override
  State<DashboardDirekturScreen> createState() =>
      _DashboardDirekturScreenState();
}

class _DashboardDirekturScreenState extends State<DashboardDirekturScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApprovalProvider>().loadAllApprovals();
      context.read<RealtimeMonitoringProvider>().loadRealtimeAttendance();
      context.read<EmployeeManagementProvider>().loadEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final user = authProv.currentUser;
    final approvalProv = context.watch<ApprovalProvider>();
    final pendingCount = approvalProv.pendingApprovals.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _selectedTabIndex == 1
          ? AppBar(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0.5,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.onSurface),
                onPressed: () => setState(() => _selectedTabIndex = 0),
              ),
              title: const Text(
                'Akun & Profil Admin',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            )
          : _buildTopAppBar(context, user),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          // TAB 0: TAMPILAN MONITOR ADMIN (DIREKTUR) DENGAN DAFTAR PERSETUJUAN & RIWAYAT
          const AdminMonitoringScreen(
            showAppBar: false,
          ),

          // TAB 1: AKUN SAYA
          AdminAkunScreen(
            showAppBar: false,
            onBackToHome: () => setState(() => _selectedTabIndex = 0),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(pendingCount),
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
                    color: AppColors.roleDirektur,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
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
                const SizedBox(height: 1),
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
      actions: [
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

  Widget _buildAvatarFallback() {
    return Container(
      color: AppColors.surfaceContainer,
      child: const Icon(
        Icons.person,
        size: 20,
        color: AppColors.roleDirektur,
      ),
    );
  }

  Widget _buildBottomNavigation(int pendingCount) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // TAB 0: DASHBOARD (DENGAN BADGE PERSETUJUAN MENUNGGU)
              _buildNavTab(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                badgeCount: pendingCount,
                isActive: _selectedTabIndex == 0,
                onTap: () => setState(() => _selectedTabIndex = 0),
              ),

              // TAB 1: AKUN SAYA
              _buildNavTab(
                icon: Icons.person_rounded,
                label: 'Akun Saya',
                isActive: _selectedTabIndex == 1,
                onTap: () => setState(() => _selectedTabIndex = 1),
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
    const activeColor = AppColors.roleDirektur;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.08)
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
                color: isActive ? activeColor : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : AppColors.onSurfaceVariant,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
