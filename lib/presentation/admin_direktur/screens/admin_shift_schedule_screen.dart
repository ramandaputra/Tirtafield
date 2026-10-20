import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ShiftAssignment {
  final String employeeId;
  final String employeeName;
  final String nip;
  final String department;
  final Map<int, String> weeklyShifts; // dayIndex (0: Sen, 1: Sel, ... 6: Min) -> shiftCode

  ShiftAssignment({
    required this.employeeId,
    required this.employeeName,
    required this.nip,
    required this.department,
    required this.weeklyShifts,
  });
}

class AdminShiftScheduleScreen extends StatefulWidget {
  final bool showAppBar;
  const AdminShiftScheduleScreen({super.key, this.showAppBar = true});

  @override
  State<AdminShiftScheduleScreen> createState() =>
      _AdminShiftScheduleScreenState();
}

class _AdminShiftScheduleScreenState extends State<AdminShiftScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  // Master shifts created by Superadmin
  final List<Map<String, dynamic>> _masterShifts = const [
    {
      'code': 'NORM',
      'name': 'Shift Reguler Normal',
      'in': '08:00 WIB',
      'out': '17:00 WIB',
      'tolerance': '15 Menit',
      'color': Color(0xFF1E40AF),
      'bg': Color(0xFFEFF6FF),
    },
    {
      'code': 'PAGI',
      'name': 'Shift Pagi Operasional (IPA/Pompa)',
      'in': '07:30 WIB',
      'out': '15:30 WIB',
      'tolerance': '15 Menit',
      'color': Color(0xFF15803D),
      'bg': Color(0xFFDCFCE7),
    },
    {
      'code': 'SIANG',
      'name': 'Shift Siang Transmisi & Jaringan',
      'in': '14:30 WIB',
      'out': '22:30 WIB',
      'tolerance': '15 Menit',
      'color': Color(0xFFB45309),
      'bg': Color(0xFFFEF3C7),
    },
    {
      'code': 'MALAM',
      'name': 'Shift Malam Standby Siaga',
      'in': '22:00 WIB',
      'out': '06:00 WIB',
      'tolerance': '15 Menit',
      'color': Color(0xFF6B21A8),
      'bg': Color(0xFFF3E8FF),
    },
    {
      'code': 'OFF',
      'name': 'Libur / Hari Bebas Tugas',
      'in': '-',
      'out': '-',
      'tolerance': '-',
      'color': Color(0xFF64748B),
      'bg': Color(0xFFF1F5F9),
    },
  ];

  // In-memory schedules for demo plotting
  late List<ShiftAssignment> _assignments;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _assignments = [
      ShiftAssignment(
        employeeId: '1',
        employeeName: 'SYAKYAKIRTI, S.E., M.M., M.H',
        nip: 'P001',
        department: 'Operasional Lapangan',
        weeklyShifts: {0: 'PAGI', 1: 'PAGI', 2: 'PAGI', 3: 'PAGI', 4: 'PAGI', 5: 'OFF', 6: 'OFF'},
      ),
      ShiftAssignment(
        employeeId: '5',
        employeeName: 'H. SUWARDI, S.AG',
        nip: 'K202602',
        department: 'Distribusi Air',
        weeklyShifts: {0: 'SIANG', 1: 'SIANG', 2: 'SIANG', 3: 'SIANG', 4: 'SIANG', 5: 'OFF', 6: 'OFF'},
      ),
      ShiftAssignment(
        employeeId: '6',
        employeeName: 'FAZLI IDHAM MACHZAL, A.Md',
        nip: '020131',
        department: 'Unit Pelayanan Bintan Centre',
        weeklyShifts: {0: 'NORM', 1: 'NORM', 2: 'NORM', 3: 'NORM', 4: 'NORM', 5: 'OFF', 6: 'OFF'},
      ),
      ShiftAssignment(
        employeeId: '7',
        employeeName: 'MUHAMAD THAPRIZAL',
        nip: '020116',
        department: 'Transmisi & Jaringan',
        weeklyShifts: {0: 'MALAM', 1: 'MALAM', 2: 'MALAM', 3: 'MALAM', 4: 'MALAM', 5: 'OFF', 6: 'OFF'},
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Tab Selector
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(
                icon: Icon(Icons.calendar_month_rounded, size: 18),
                text: 'Plotting Jadwal Staf',
              ),
              Tab(
                icon: Icon(Icons.schedule_rounded, size: 18),
                text: 'Master Shift (Read-Only)',
              ),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPlottingTab(),
              _buildMasterShiftsTab(),
            ],
          ),
        ),
      ],
    );

    if (!widget.showAppBar) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan Shift & Jadwal Pegawai'),
      ),
      body: content,
    );
  }

  // TAB 1: PLOTTING JADWAL HARIAN/MINGGUAN OLEH ADMIN
  Widget _buildPlottingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [


        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Jadwal Shift Pekan Ini',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jadwal plotting shift mingguan staf berhasil disimpan.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text('Simpan Jadwal', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Employee Shift Cards
        ..._assignments.map((assignment) => _buildAssignmentCard(assignment)),
      ],
    );
  }

  Widget _buildAssignmentCard(ShiftAssignment assignment) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.employeeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${assignment.nip} • ${assignment.department}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                tooltip: 'Ubah Jadwal Pekan',
                onPressed: () => _showBulkEditDialog(assignment),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day Grid
          Row(
            children: List.generate(7, (idx) {
              final code = assignment.weeklyShifts[idx] ?? 'OFF';
              final shiftData = _masterShifts.firstWhere(
                (s) => s['code'] == code,
                orElse: () => _masterShifts.last,
              );

              return Expanded(
                child: InkWell(
                  onTap: () => _showChangeShiftSheet(assignment, idx),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: EdgeInsets.only(right: idx < 6 ? 4 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: shiftData['bg'],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: (shiftData['color'] as Color).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _days[idx].substring(0, 3),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: shiftData['color'],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          code,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: shiftData['color'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // TAB 2: MASTER SHIFT KERJA (READ-ONLY OLEH ADMIN)
  Widget _buildMasterShiftsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [


        const Text(
          'Daftar Master Shift Kerja Tirtafield',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),

        ..._masterShifts.map((shift) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: shift['bg'],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: (shift['color'] as Color).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    shift['code'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: shift['color'],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shift['name'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Jam Kerja: ${shift['in']} - ${shift['out']}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Text(
                        'Toleransi Keterlambatan: ${shift['tolerance']}',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textSecondary),
                      SizedBox(width: 3),
                      Text('Master', style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showChangeShiftSheet(ShiftAssignment assignment, int dayIndex) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ubah Shift: ${_days[dayIndex]}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                'Pegawai: ${assignment.employeeName}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ..._masterShifts.map((s) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: s['bg'],
                    child: Text(
                      s['code'],
                      style: TextStyle(color: s['color'], fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(s['name'], style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  subtitle: Text('${s['in']} - ${s['out']}', style: const TextStyle(fontSize: 11)),
                  onTap: () {
                    setState(() {
                      assignment.weeklyShifts[dayIndex] = s['code'];
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Shift ${_days[dayIndex]} diubah ke ${s['name']}'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showBulkEditDialog(ShiftAssignment assignment) {
    String selectedShift = 'PAGI';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Setel Pola Shift: ${assignment.employeeName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Terapkan shift yang sama untuk seluruh hari kerja (Senin - Jumat):',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedShift,
                    decoration: const InputDecoration(labelText: 'Pilih Shift Kerja'),
                    items: _masterShifts.where((s) => s['code'] != 'OFF').map((s) {
                      return DropdownMenuItem(
                        value: s['code'] as String,
                        child: Text('${s['name']} (${s['in']})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedShift = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      for (int i = 0; i < 5; i++) {
                        assignment.weeklyShifts[i] = selectedShift;
                      }
                      assignment.weeklyShifts[5] = 'OFF';
                      assignment.weeklyShifts[6] = 'OFF';
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
