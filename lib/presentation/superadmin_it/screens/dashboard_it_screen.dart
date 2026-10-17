import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../state/auth_provider.dart';
import 'system_settings_screen.dart';
import 'user_management_screen.dart';

class DashboardITScreen extends StatelessWidget {
  const DashboardITScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final user = authProv.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Panel Staff IT (Superadmin)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
            onPressed: () => authProv.logout(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: RoleBadge(role: user.role),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Server & System Status Card
            _buildSystemStatusCard(),
            const SizedBox(height: 20),

            const Text(
              'Konfigurasi & Manajemen Sistem',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _buildMenuCard(
              context: context,
              icon: Icons.manage_accounts_rounded,
              color: AppColors.roleKaryawan,
              title: 'Kelola Pengguna & Hak Akses',
              subtitle: 'Manajemen akun Karyawan, Direktur, dan Staff IT',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context: context,
              icon: Icons.tune_rounded,
              color: AppColors.roleStaffIT,
              title: 'Konfigurasi Jam & 4 Slot Presensi',
              subtitle: 'Atur jadwal Masuk, Istirahat, Pulang, dan Toleransi Telat',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SystemSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context: context,
              icon: Icons.location_on_outlined,
              color: AppColors.breakOut,
              title: 'Pengaturan Geofencing & Lokasi Kantor',
              subtitle: 'Koordinat GPS kantor dan batas radius presensi (50m)',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Konfigurasi Geofencing: Lat -6.2088, Lng 106.8456 (Radius 50m) Aktif'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context: context,
              icon: Icons.security_rounded,
              color: AppColors.roleDirektur,
              title: 'Log Keamanan & Audit Trail',
              subtitle: 'Riwayat aktivitas sistem, perubahan role, dan akses login',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Log Audit: Semua aktivitas sistem tercatat dengan aman.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Sistem Presensi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'ONLINE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatusItem(label: 'GPS Lokasi', status: 'Aktif'),
              _StatusItem(label: 'Approval Engine', status: 'Normal'),
              _StatusItem(label: 'Sync Server', status: 'Tersinkron'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String status;

  const _StatusItem({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          status,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}
