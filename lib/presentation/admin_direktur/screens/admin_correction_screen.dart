import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../state/auth_provider.dart';
import '../../../state/employee_management_provider.dart';

class AttendanceCorrectionItem {
  final String id;
  final String employeeName;
  final String nip;
  final String department;
  final DateTime date;
  final String slot; // Masuk / Pulang
  final String originalTime;
  final String correctedTime;
  final String reasonCategory;
  final String note;
  final String correctedBy;
  final DateTime createdAt;

  AttendanceCorrectionItem({
    required this.id,
    required this.employeeName,
    required this.nip,
    required this.department,
    required this.date,
    required this.slot,
    required this.originalTime,
    required this.correctedTime,
    required this.reasonCategory,
    required this.note,
    required this.correctedBy,
    required this.createdAt,
  });
}

class AdminCorrectionScreen extends StatefulWidget {
  final bool showAppBar;
  const AdminCorrectionScreen({super.key, this.showAppBar = true});

  @override
  State<AdminCorrectionScreen> createState() => _AdminCorrectionScreenState();
}

class _AdminCorrectionScreenState extends State<AdminCorrectionScreen> {
  final List<AttendanceCorrectionItem> _history = [
    AttendanceCorrectionItem(
      id: 'COR-001',
      employeeName: 'SYAKYAKIRTI, S.E., M.M., M.H',
      nip: 'P001',
      department: 'Operasional Lapangan',
      date: DateTime.now().subtract(const Duration(days: 1)),
      slot: 'Presensi Masuk',
      originalTime: '08:42 WIB (Terlambat)',
      correctedTime: '07:35 WIB (Tepat Waktu)',
      reasonCategory: 'Kendala Jaringan / Sinyal Provider Lapangan',
      note: 'Staf sudah berada di lokasi IPA Sei Pulai pukul 07:30, BTS seluler down 1 jam.',
      correctedBy: 'Admin Direktur',
      createdAt: DateTime.now().subtract(const Duration(hours: 14)),
    ),
    AttendanceCorrectionItem(
      id: 'COR-002',
      employeeName: 'MUHAMAD THAPRIZAL',
      nip: '020116',
      department: 'Transmisi & Jaringan',
      date: DateTime.now().subtract(const Duration(days: 2)),
      slot: 'Presensi Pulang',
      originalTime: 'Tidak Tercatat',
      correctedTime: '17:15 WIB',
      reasonCategory: 'Baterai Handphone Habis saat Tugas Lapangan',
      note: 'Penanganan pipa bocor darurat hingga sore, baterai HP habis saat pengerjaan selesai.',
      correctedBy: 'Admin Direktur',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final empProv = context.watch<EmployeeManagementProvider>();
    final reviewerName = authProv.currentUser.name;

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [


        // Action Button: Input Koreksi
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_task_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Form Koreksi Presensi',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Perbaiki kendala jam presensi staf lapangan dengan alasan resmi.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => _showCorrectionForm(context, empProv.employees, reviewerName),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('Buat Koreksi', style: TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Riwayat Koreksi Manual
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Riwayat Koreksi Manual (${_history.length})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Tercatat Jejak Audit',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_history.isEmpty)
          _buildEmptyHistory()
        else
          ..._history.map((item) => _buildHistoryCard(item)),
      ],
    );

    if (!widget.showAppBar) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Koreksi Presensi Manual (Terbatas)'),
      ),
      body: content,
    );
  }

  Widget _buildHistoryCard(AttendanceCorrectionItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.slot,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              Text(
                item.id,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            item.employeeName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          Text(
            '${item.nip} • ${item.department}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),

          // Time Diff
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Waktu Asli Sistem', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        item.originalTime,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textSecondary),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Waktu Setelah Koreksi', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        item.correctedTime,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Reason Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Alasan Resmi: ${item.reasonCategory}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Catatan: "${item.note}"',
            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Diverifikasi oleh: ${item.correctedBy}',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Center(
        child: Text(
          'Belum ada riwayat koreksi manual',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  void _showCorrectionForm(
      BuildContext context, List<UserModel> employees, String reviewerName) {
    if (employees.isEmpty) return;
    UserModel selectedEmp = employees.first;
    String selectedSlot = 'Presensi Masuk';
    String newTime = '07:45';
    String selectedReason = 'Kendala Jaringan / Sinyal Provider Lapangan';
    final noteCtrl = TextEditingController();

    final List<String> reasons = [
      'Kendala Jaringan / Sinyal Provider Lapangan',
      'Baterai Handphone Habis saat Tugas Lapangan',
      'Dinas Lapangan Darurat / Luar Jangkauan GPS',
      'Aplikasi Mengalami Error / Freeze saat Presensi',
      'Pemadaman Listrik di Stasiun Pompa / IPA',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Koreksi Presensi Manual', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Employee Dropdown
                    DropdownButtonFormField<UserModel>(
                      value: selectedEmp,
                      decoration: const InputDecoration(labelText: 'Pilih Pegawai Lapangan'),
                      items: employees.map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Text('${e.name} (${e.nip})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedEmp = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Slot
                    DropdownButtonFormField<String>(
                      value: selectedSlot,
                      decoration: const InputDecoration(labelText: 'Slot Presensi'),
                      items: const [
                        DropdownMenuItem(value: 'Presensi Masuk', child: Text('Presensi Masuk')),
                        DropdownMenuItem(value: 'Presensi Istirahat Keluar', child: Text('Presensi Istirahat Keluar')),
                        DropdownMenuItem(value: 'Presensi Istirahat Kembali', child: Text('Presensi Istirahat Kembali')),
                        DropdownMenuItem(value: 'Presensi Pulang', child: Text('Presensi Pulang')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedSlot = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Jam Koreksi
                    TextFormField(
                      initialValue: newTime,
                      decoration: const InputDecoration(
                        labelText: 'Jam Koreksi yang Disetujui (WIB)',
                        hintText: 'HH:mm (Misal 07:45)',
                      ),
                      onChanged: (val) => newTime = val.trim(),
                    ),
                    const SizedBox(height: 10),

                    // Alasan Resmi Terbatas
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Kategori Alasan Resmi (Batas Admin)'),
                      items: reasons.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 11.5)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedReason = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Catatan Wajib
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Catatan & Alasan Verifikator (Wajib)',
                        hintText: 'Tuliskan rincian kronologi kendala lapangan...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                FilledButton(
                  onPressed: () {
                    if (noteCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Catatan verifikator wajib diisi sesuai batas alasan operasional.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _history.insert(
                        0,
                        AttendanceCorrectionItem(
                          id: 'COR-00${_history.length + 1}',
                          employeeName: selectedEmp.name,
                          nip: selectedEmp.nip,
                          department: selectedEmp.department,
                          date: DateTime.now(),
                          slot: selectedSlot,
                          originalTime: 'Terlambat / Tidak Ada',
                          correctedTime: '$newTime WIB',
                          reasonCategory: selectedReason,
                          note: noteCtrl.text.trim(),
                          correctedBy: reviewerName,
                          createdAt: DateTime.now(),
                        ),
                      );
                    });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Koreksi presensi manual berhasil dicatat dalam jejak audit resmi.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: const Text('Simpan Koreksi'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
