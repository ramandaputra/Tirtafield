import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/constants/bidang_data.dart';
import '../../../data/models/user_model.dart';
import '../../../state/employee_management_provider.dart';
import '../../../state/system_settings_provider.dart';

class AdminEmployeeOperationalScreen extends StatefulWidget {
  final bool showAppBar;
  const AdminEmployeeOperationalScreen({super.key, this.showAppBar = true});

  @override
  State<AdminEmployeeOperationalScreen> createState() =>
      _AdminEmployeeOperationalScreenState();
}

class _AdminEmployeeOperationalScreenState
    extends State<AdminEmployeeOperationalScreen> {
  String _searchQuery = '';
  String _selectedDepartment = 'all';
  final String _selectedStatus = 'all';
  final TextEditingController _searchController = TextEditingController();

  List<String> get _departments => [
    'all',
    ...BidangData.mainOperationalBidang,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empProv = context.watch<EmployeeManagementProvider>();
    final allEmployees = empProv.employees;

    final filtered = allEmployees.where((emp) {
      final matchesQuery = _searchQuery.isEmpty ||
          emp.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          emp.nip.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          emp.department.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesDept = _selectedDepartment == 'all' ||
          emp.department.toLowerCase().contains(_selectedDepartment.toLowerCase());

      final matchesStatus = _selectedStatus == 'all' ||
          (_selectedStatus == 'active' ? emp.isActive : !emp.isActive);

      return matchesQuery && matchesDept && matchesStatus;
    }).toList();

    final content = RefreshIndicator(
      onRefresh: () => empProv.loadEmployees(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Search & Filter Row
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            decoration: InputDecoration(
              hintText: 'Cari staf operasional (Nama, NIK)...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Chips Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _departments.map((dept) {
                final label = dept == 'all' ? 'Semua Bidang' : dept;
                final isSelected = _selectedDepartment == dept;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(label, isSelected, () {
                    setState(() => _selectedDepartment = dept);
                  }),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Summary and Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Daftar Staf Operasional (${filtered.length})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _showAddEmployeeDialog(context, empProv),
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('Tambah Staf', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (filtered.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final emp = filtered[index];
                return _buildEmployeeCard(context, emp, empProv);
              },
            ),
        ],
      ),
    );

    if (!widget.showAppBar) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manajemen Data Pegawai (Operasional)'),
      ),
      body: content,
    );
  }


  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(
      BuildContext context, UserModel emp, EmployeeManagementProvider empProv) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: ClipOval(
                  child: emp.avatarUrl != null && emp.avatarUrl!.isNotEmpty
                      ? Image.network(
                          emp.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackInitial(emp.name),
                        )
                      : _buildFallbackInitial(emp.name),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            emp.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: emp.isActive
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            emp.isActive ? 'Aktif' : 'Nonaktif',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: emp.isActive
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${emp.nip} • ${emp.position}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.business_center_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${emp.department} • ${emp.officeName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 8),

          // Actions Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Status: ${emp.statusPegawai}',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showEditEmployeeDialog(context, emp, empProv),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: emp.isActive ? 'Nonaktifkan Akun' : 'Aktifkan Akun',
                    icon: Icon(
                      emp.isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                      color: emp.isActive ? AppColors.success : AppColors.textSecondary,
                      size: 28,
                    ),
                    onPressed: () {
                      final updated = emp.copyWith(isActive: !emp.isActive);
                      empProv.updateEmployeeData(updated);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Status akun ${emp.name} diubah menjadi ${!emp.isActive ? "Aktif" : "Nonaktif"}',
                          ),
                          backgroundColor: !emp.isActive ? AppColors.success : AppColors.warning,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackInitial(String name) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'P',
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_off_rounded, size: 40, color: AppColors.textSecondary),
          SizedBox(height: 8),
          Text(
            'Tidak ada data staf operasional',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: 4),
          Text(
            'Coba ubah kata kunci atau filter bidang Anda.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showEditEmployeeDialog(
      BuildContext context, UserModel emp, EmployeeManagementProvider empProv) {
    final nameCtrl = TextEditingController(text: emp.name);
    final phoneCtrl = TextEditingController(text: emp.phone);
    String selectedDept = BidangData.normalizeBidang(emp.department);
    String selectedSeksi = BidangData.normalizeSeksi(selectedDept, emp.position);
    String selectedStatusPegawai = emp.statusPegawai;
    final offices = context.read<SystemSettingsProvider>().geofencing.offices;
    String selectedOffice = offices.any((o) => o.id == emp.officeId)
        ? emp.officeId
        : (offices.isNotEmpty ? offices.first.id : 'hq');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                'Edit Data Operasional (${emp.nip})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Nomor WhatsApp / HP'),
                    ),
                    const SizedBox(height: 12),
                    // Dropdown Bidang
                    DropdownButtonFormField<String>(
                      initialValue: BidangData.allBidang.contains(selectedDept)
                          ? selectedDept
                          : BidangData.allBidang.first,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Bidang'),
                      items: BidangData.allBidang.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(
                            d,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedDept = val;
                            selectedSeksi = BidangData.getSeksiForBidang(val).first;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Dropdown Seksi Bidang (Terintegrasi)
                    DropdownButtonFormField<String>(
                      key: ValueKey('admin_edit_seksi_$selectedDept'),
                      initialValue: BidangData.getSeksiForBidang(selectedDept).contains(selectedSeksi)
                          ? selectedSeksi
                          : BidangData.getSeksiForBidang(selectedDept).first,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Seksi Bidang'),
                      items: BidangData.getSeksiForBidang(selectedDept).map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(
                            s,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedSeksi = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatusPegawai,
                      decoration: const InputDecoration(labelText: 'Status Kerja'),
                      items: const [
                        DropdownMenuItem(value: 'Karyawan Tetap', child: Text('Karyawan Tetap')),
                        DropdownMenuItem(value: 'Karyawan Kontrak', child: Text('Karyawan Kontrak')),
                        DropdownMenuItem(value: 'Staff Lapangan / Outsourcing', child: Text('Staff Lapangan')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedStatusPegawai = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedOffice,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Kantor / Cabang'),
                      items: offices.map((o) {
                        return DropdownMenuItem<String>(
                          value: o.id,
                          child: Text(
                            '${o.name} (${o.officeTypeLabel})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedOffice = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    final chosenOffice = offices.firstWhere(
                      (o) => o.id == selectedOffice,
                      orElse: () => offices.first,
                    );

                    final updated = emp.copyWith(
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      department: selectedDept,
                      position: selectedSeksi,
                      statusPegawai: selectedStatusPegawai,
                      officeId: chosenOffice.id,
                      officeName: chosenOffice.name,
                    );

                    empProv.updateEmployeeData(updated);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data operasional pegawai berhasil diperbarui'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: const Text('Simpan Perubahan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddEmployeeDialog(BuildContext context, EmployeeManagementProvider empProv) {
    final nipCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedDept = BidangData.mainOperationalBidang.first;
    String selectedSeksi = BidangData.getSeksiForBidang(selectedDept).first;
    final offices = context.read<SystemSettingsProvider>().geofencing.offices;
    String selectedOffice = offices.isNotEmpty ? offices.first.id : 'hq';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Tambah Staf Operasional Baru',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nipCtrl,
                      decoration: const InputDecoration(labelText: 'NIK'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'No WhatsApp / Telepon'),
                    ),
                    const SizedBox(height: 12),
                    // Dropdown Bidang
                    DropdownButtonFormField<String>(
                      initialValue: selectedDept,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Bidang'),
                      items: BidangData.allBidang.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(
                            d,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedDept = val;
                            selectedSeksi = BidangData.getSeksiForBidang(val).first;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Dropdown Seksi Bidang (Terintegrasi)
                    DropdownButtonFormField<String>(
                      key: ValueKey('admin_add_seksi_$selectedDept'),
                      initialValue: BidangData.getSeksiForBidang(selectedDept).contains(selectedSeksi)
                          ? selectedSeksi
                          : BidangData.getSeksiForBidang(selectedDept).first,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Seksi Bidang'),
                      items: BidangData.getSeksiForBidang(selectedDept).map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(
                            s,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedSeksi = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedOffice,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Penempatan Kantor Cabang'),
                      items: offices.map((o) {
                        return DropdownMenuItem<String>(
                          value: o.id,
                          child: Text(
                            '${o.name} (${o.officeTypeLabel})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedOffice = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nipCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                      return;
                    }

                    final chosenOffice = offices.firstWhere(
                      (o) => o.id == selectedOffice,
                      orElse: () => offices.first,
                    );

                    empProv.addEmployee(
                      nip: nipCtrl.text.trim(),
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isEmpty ? '081234567890' : phoneCtrl.text.trim(),
                      role: UserRole.karyawan,
                      department: selectedDept,
                      position: selectedSeksi,
                      officeId: chosenOffice.id,
                      officeName: chosenOffice.name,
                      statusPegawai: 'Karyawan Tetap',
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Staf operasional baru berhasil ditambahkan'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: const Text('Tambah Staf'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
