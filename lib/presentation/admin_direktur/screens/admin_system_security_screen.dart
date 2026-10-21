import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../state/auth_provider.dart';
import '../widgets/admin_matrix_modal.dart';

class AdminSystemSecurityScreen extends StatelessWidget {
  final bool showAppBar;
  const AdminSystemSecurityScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final user = authProv.currentUser;

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [


        // Matriks Modal Trigger Button
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppColors.primary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.table_view_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tabel Matriks Hak Akses Lengkap',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Lihat perbandingan hak akses 11 modul Superadmin vs Admin.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => AdminMatrixModal.show(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Buka Tabel', style: TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // MODUL 1: MANAJEMEN PERAN & AKUN PENGGUNA
        _buildSectionHeader('Modul 1: Manajemen Peran & Akun Pengguna', Icons.manage_accounts_rounded),
        const SizedBox(height: 8),
        _buildRestrictedCard(
          title: 'Hierarki Struktur Peran & Otoritas Sistem',
          description:
              'Superadmin mengelola hierarki peran (Superadmin → Admin → Pengguna) dan pemetaan otorisasi.',
          extraContent: Column(
            children: [
              _buildHierarchyRow('1. Superadmin', 'Full Akses Sistem, Master Database & API', const Color(0xFF1D4ED8)),
              const Divider(height: 12, color: AppColors.cardBorder),
              _buildHierarchyRow('2. Admin', 'Kelola Operasional, Plotting Shift, Verifikasi T1', const Color(0xFF15803D)),
              const Divider(height: 12, color: AppColors.cardBorder),
              _buildHierarchyRow('3. Pengguna', 'Presensi Mobile, Koreksi & Presensi Luar Radius', AppColors.textSecondary),
            ],
          ),
          actionText: 'Ajukan Penyesuaian Peran ke Superadmin',
          onAction: () => _showRoleRequestDialog(context, user.name),
        ),
        const SizedBox(height: 20),

        // MODUL 10: LOG AUDIT AKTIVITAS SISTEM
        _buildSectionHeader('Modul 10: Log Audit Aktivitas Sistem', Icons.history_edu_rounded),
        const SizedBox(height: 8),
        _buildRestrictedCard(
          title: 'Audit Trail & Jejak Keamanan Sistem (Immutable)',
          description:
              'Superadmin melacak seluruh jejak perubahan data, manipulasi lokasi, pembatalan absensi, dan riwayat login. Format log terkunci read-only anti-tampering.',
          extraContent: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Status Integritas Jejak Audit:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ),
                    SizedBox(width: 8),
                    Text('SHA-256 Tervalidasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Akses Log Aktivitas Admin:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ),
                    SizedBox(width: 8),
                    Text('Terproteksi (Khusus Superadmin)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // MODUL 11: INTEGRASI API & PENGATURAN SISTEM GLOBAL
        _buildSectionHeader('Modul 11: Integrasi API & Pengaturan Sistem Global', Icons.webhook_rounded),
        const SizedBox(height: 8),
        _buildRestrictedCard(
          title: 'Status Gateway Integrasi Basis Data & Webhook',
          description:
              'Mengatur integrasi basis data HRIS/Payroll, Webhook, backup berkala, dan konfigurasi push notification gateway.',
          extraContent: Column(
            children: [
              _buildIntegrationStatusRow('MySQL Laragon Database (tirtafield)', 'ONLINE (Port 3306)', true),
              const Divider(height: 12, color: AppColors.cardBorder),
              _buildIntegrationStatusRow('Geofencing & Leaflet Map Gateway', 'READY & SECURE', true),
              const Divider(height: 12, color: AppColors.cardBorder),
              _buildIntegrationStatusRow('HRIS & Payroll Export Webhook', 'CONNECTED', true),
              const Divider(height: 12, color: AppColors.cardBorder),
              _buildIntegrationStatusRow('FCM Push Notification Service', 'ACTIVE', true),
            ],
          ),
        ),
      ],
    );

    if (!showAppBar) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sistem, Log Audit & Keamanan Global'),
      ),
      body: content,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildRestrictedCard({
    required String title,
    required String description,
    required Widget extraContent,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_rounded, size: 16, color: Color(0xFFDC2626)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Superadmin Only',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 12),
          extraContent,
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.send_rounded, size: 14),
                label: Text(actionText, style: const TextStyle(fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHierarchyRow(String roleName, String scope, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(roleName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              Text(scope, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntegrationStatusRow(String name, String status, bool isOnline) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(name, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
        ),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              status,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isOnline ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showRoleRequestDialog(BuildContext context, String currentAdminName) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permohonan Peran / Otoritas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajukan tiket permohonan ke Superadmin IT PUSIMPEL dari $currentAdminName:',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tuliskan deskripsi penyesuaian hak akses atau role yang dibutuhkan...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tiket permohonan peran berhasil dikirimkan ke Superadmin IT.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Kirim Tiket'),
          ),
        ],
      ),
    );
  }
}
