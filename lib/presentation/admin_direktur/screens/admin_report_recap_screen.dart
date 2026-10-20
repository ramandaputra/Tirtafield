import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class RecapRowItem {
  final String nip;
  final String name;
  final String department;
  final int workDays;
  final int presentDays;
  final int lateDays;
  final int totalLateMinutes;
  final double overtimeHours;
  final int cutHours;

  const RecapRowItem({
    required this.nip,
    required this.name,
    required this.department,
    required this.workDays,
    required this.presentDays,
    required this.lateDays,
    required this.totalLateMinutes,
    required this.overtimeHours,
    required this.cutHours,
  });

  double get attendancePercentage => (presentDays / workDays) * 100;
}

class AdminReportRecapScreen extends StatefulWidget {
  final bool showAppBar;
  const AdminReportRecapScreen({super.key, this.showAppBar = true});

  @override
  State<AdminReportRecapScreen> createState() => _AdminReportRecapScreenState();
}

class _AdminReportRecapScreenState extends State<AdminReportRecapScreen> {
  String _selectedPeriod = 'Oktober 2026 (Bulan Ini)';
  String _selectedBranch = 'all';

  final List<String> _periods = [
    'Oktober 2026 (Bulan Ini)',
    'September 2026',
    'Agustus 2026',
    'Triwulan III (Jul - Sep 2026)',
  ];

  final List<RecapRowItem> _recapData = [
    const RecapRowItem(
      nip: 'P001',
      name: 'SYAKYAKIRTI, S.E., M.M., M.H',
      department: 'Operasional Lapangan',
      workDays: 22,
      presentDays: 22,
      lateDays: 1,
      totalLateMinutes: 12,
      overtimeHours: 6.5,
      cutHours: 0,
    ),
    const RecapRowItem(
      nip: 'K202602',
      name: 'H. SUWARDI, S.AG',
      department: 'Distribusi Air',
      workDays: 22,
      presentDays: 21,
      lateDays: 0,
      totalLateMinutes: 0,
      overtimeHours: 4.0,
      cutHours: 0,
    ),
    const RecapRowItem(
      nip: '020131',
      name: 'FAZLI IDHAM MACHZAL, A.Md',
      department: 'Unit Bintan Centre',
      workDays: 22,
      presentDays: 22,
      lateDays: 2,
      totalLateMinutes: 24,
      overtimeHours: 8.0,
      cutHours: 0,
    ),
    const RecapRowItem(
      nip: '020116',
      name: 'MUHAMAD THAPRIZAL',
      department: 'Transmisi & Jaringan',
      workDays: 22,
      presentDays: 20,
      lateDays: 3,
      totalLateMinutes: 45,
      overtimeHours: 12.5,
      cutHours: 2,
    ),
    const RecapRowItem(
      nip: '020103',
      name: 'SYAHRUL',
      department: 'Operasional Lapangan',
      workDays: 22,
      presentDays: 21,
      lateDays: 1,
      totalLateMinutes: 15,
      overtimeHours: 3.0,
      cutHours: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [


        // Filter Bar (Period & Branch)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Parameter Laporan Rekapitulasi',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPeriod,
                      decoration: const InputDecoration(
                        labelText: 'Periode Waktu',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: _periods.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 11.5)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPeriod = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedBranch,
                      decoration: const InputDecoration(
                        labelText: 'Cabang / Unit',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Semua Cabang', style: TextStyle(fontSize: 11.5))),
                        DropdownMenuItem(value: 'hq', child: Text('Kantor Pusat (HQ)', style: TextStyle(fontSize: 11.5))),
                        DropdownMenuItem(value: 'ipa_sei_pulai', child: Text('IPA Sei Pulai', style: TextStyle(fontSize: 11.5))),
                        DropdownMenuItem(value: 'bintan_center', child: Text('Bintan Centre', style: TextStyle(fontSize: 11.5))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBranch = val);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Export Buttons Bar
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _simulateExport('Excel (.xlsx)'),
                icon: const Icon(Icons.table_chart_rounded, size: 16),
                label: const Text('Ekspor Excel', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _simulateExport('PDF Resmi Cabang'),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: const Text('Unduh PDF', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Header Table
        Text(
          'Pratinjau Data Rekapitulasi (${_recapData.length} Pegawai)',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),

        // Table Rows
        ..._recapData.map((row) => _buildRecapItemCard(row)),
      ],
    );

    if (!widget.showAppBar) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ekspor & Rekapitulasi Presensi'),
      ),
      body: content,
    );
  }

  Widget _buildRecapItemCard(RecapRowItem row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${row.nip} • ${row.department}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: row.attendancePercentage >= 95
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${row.attendancePercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: row.attendancePercentage >= 95
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4 Mini Metrics
          Row(
            children: [
              _buildMiniMetric('Kehadiran', '${row.presentDays}/${row.workDays} Hari', AppColors.primary),
              _buildMiniMetric('Terlambat', '${row.lateDays}x (${row.totalLateMinutes}m)', row.lateDays > 0 ? AppColors.warning : AppColors.textSecondary),
              _buildMiniMetric('Lembur', '${row.overtimeHours} Jam', const Color(0xFF7C3AED)),
              _buildMiniMetric('Potongan', '${row.cutHours} Jam', row.cutHours > 0 ? AppColors.error : AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(6),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateExport(String format) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Menyiapkan file $format...'),
            const SizedBox(height: 4),
            const Text(
              'Menghitung total jam kerja, potongan keterlambatan, & lembur payroll.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Laporan Rekapitulasi Presensi Cabang ($format) berhasil diunduh ke perangkat.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }
}
