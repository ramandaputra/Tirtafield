import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class FeatureMatrixItem {
  final int number;
  final String title;
  final String superadminAccess;
  final String adminAccess;
  final String description;
  final IconData icon;
  final bool isAdminAllowed;
  final bool isAdminWarning;

  const FeatureMatrixItem({
    required this.number,
    required this.title,
    required this.superadminAccess,
    required this.adminAccess,
    required this.description,
    required this.icon,
    this.isAdminAllowed = true,
    this.isAdminWarning = false,
  });
}

class AdminMatrixModal extends StatelessWidget {
  const AdminMatrixModal({super.key});

  static const List<FeatureMatrixItem> matrixItems = [
    FeatureMatrixItem(
      number: 1,
      title: 'Manajemen Peran & Akun Pengguna',
      superadminAccess: '✅ Full Akses',
      adminAccess: '❌ Tidak Ada',
      description: 'Superadmin mengelola akun Admin, hak akses peran (roles), dan struktur organisasi tertinggi.',
      icon: Icons.manage_accounts_rounded,
      isAdminAllowed: false,
    ),
    FeatureMatrixItem(
      number: 2,
      title: 'Manajemen Data Pegawai',
      superadminAccess: '✅ Kelola Penuh',
      adminAccess: '✅ Kelola Operasional',
      description: 'Admin mengelola data profil, penempatan divisi, status kerja, dan aktivasi akun staf.',
      icon: Icons.people_alt_rounded,
      isAdminAllowed: true,
    ),
    FeatureMatrixItem(
      number: 3,
      title: 'Pengaturan Shift Kerja & Jam Operasional',
      superadminAccess: '✅ Buat & Hapus Shift',
      adminAccess: '✅ Plotting Jadwal Pegawai',
      description: 'Superadmin menentukan jam shift dan toleransi keterlambatan; Admin mengatur jadwal shift harian/mingguan staf.',
      icon: Icons.calendar_month_rounded,
      isAdminAllowed: true,
    ),
    FeatureMatrixItem(
      number: 4,
      title: 'Manajemen Geofencing & Titik Lokasi Kantor',
      superadminAccess: '✅ Full Akses',
      adminAccess: '❌ Hanya Melihat',
      description: 'Superadmin menentukan koordinat GPS kantor, radius toleransi meter, dan integrasi WiFi/Beacon.',
      icon: Icons.share_location_rounded,
      isAdminAllowed: false,
    ),
    FeatureMatrixItem(
      number: 5,
      title: 'Dashboard Presensi Real-Time',
      superadminAccess: '✅ Seluruh Organisasi',
      adminAccess: '✅ Sesuai Divisi / Cabang',
      description: 'Memantau absensi masuk, pulang, keterlambatan, dan status kehadiran langsung di peta atau daftar.',
      icon: Icons.fmd_good_rounded,
      isAdminAllowed: true,
    ),
    FeatureMatrixItem(
      number: 6,
      title: 'Persetujuan Absensi (Koreksi & Luar Radius)',
      superadminAccess: '✅ Tingkat Lanjutan',
      adminAccess: '✅ Tingkat Pertama',
      description: 'Admin menjadi verifikator operasional langsung; Superadmin menangani eskalasi atau kasus lintas divisi.',
      icon: Icons.fact_check_rounded,
      isAdminAllowed: true,
    ),
    FeatureMatrixItem(
      number: 7,
      title: 'Koreksi Presensi Manual',
      superadminAccess: '✅ Bebas Koreksi',
      adminAccess: '⚠️ Terbatas',
      description: 'Admin memperbaiki absensi jika sistem terkendala (dengan batas alasan); Superadmin memiliki wewenang penuh tanpa limitasi.',
      icon: Icons.edit_calendar_rounded,
      isAdminAllowed: true,
      isAdminWarning: true,
    ),
    FeatureMatrixItem(
      number: 8,
      title: 'Manajemen Perangkat (Device Lock / Reset ID)',
      superadminAccess: '✅ Reset Mandiri & Kuota',
      adminAccess: '⚠️ Reset dengan Konfirmasi',
      description: 'Mengikat akun ke 1 IMEI/Device ID agar terhindar dari titip absen, serta mengatur batas reset saat ganti ponsel.',
      icon: Icons.phonelink_lock_rounded,
      isAdminAllowed: true,
      isAdminWarning: true,
    ),
    FeatureMatrixItem(
      number: 9,
      title: 'Ekspor & Unduh Laporan Rekapitulasi',
      superadminAccess: '✅ Rekap Global & Finansial',
      adminAccess: '✅ Rekap Operasional Cabang',
      description: 'Format Excel/PDF mencakup jam kerja, keterlambatan, potongan jam, dan lembur untuk kebutuhan payroll.',
      icon: Icons.file_download_rounded,
      isAdminAllowed: true,
    ),
    FeatureMatrixItem(
      number: 10,
      title: 'Log Audit Aktivitas Sistem',
      superadminAccess: '✅ Full Akses (Read-Only)',
      adminAccess: '❌ Tidak Ada',
      description: 'Superadmin melacak seluruh jejak perubahan data, manipulasi lokasi, pembatalan absensi, dan riwayat login.',
      icon: Icons.history_edu_rounded,
      isAdminAllowed: false,
    ),
    FeatureMatrixItem(
      number: 11,
      title: 'Integrasi API & Pengaturan Sistem Global',
      superadminAccess: '✅ Full Akses',
      adminAccess: '❌ Tidak Ada',
      description: 'Mengatur integrasi basis data HRIS/Payroll, Webhook, backup berkala, dan konfigurasi push notification.',
      icon: Icons.webhook_rounded,
      isAdminAllowed: false,
    ),
  ];

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdminMatrixModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
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
                        'Matriks Hak Akses Sistem',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Perbandingan Otoritas Superadmin vs Admin Operasional',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Content List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: matrixItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = matrixItems[index];
                return _buildMatrixCard(item);
              },
            ),
          ),

          // Footer Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Saya Mengerti Batasan Hak Akses',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixCard(FeatureMatrixItem item) {
    Color adminBadgeBg;
    Color adminBadgeText;

    if (!item.isAdminAllowed) {
      adminBadgeBg = const Color(0xFFFEE2E2);
      adminBadgeText = const Color(0xFFDC2626);
    } else if (item.isAdminWarning) {
      adminBadgeBg = const Color(0xFFFEF3C7);
      adminBadgeText = const Color(0xFFD97706);
    } else {
      adminBadgeBg = const Color(0xFFDCFCE7);
      adminBadgeText = const Color(0xFF16A34A);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isAdminAllowed ? AppColors.cardBorder : const Color(0xFFFEE2E2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${item.number}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Superadmin pill
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Superadmin',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                        ),
                        child: Text(
                          item.superadminAccess,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Admin pill
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Operasional',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: adminBadgeBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: adminBadgeText.withValues(alpha: 0.3), width: 0.8),
                        ),
                        child: Text(
                          item.adminAccess,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: adminBadgeText,
                          ),
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
    );
  }
}
