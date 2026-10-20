import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../data/models/user_model.dart';
import '../../../state/auth_provider.dart';
import '../../../state/employee_management_provider.dart';
import '../../../state/system_settings_provider.dart';

class SuperadminEmployeeScreen extends StatefulWidget {
  final bool showAppBar;
  final int initialSubTabIndex;

  const SuperadminEmployeeScreen({
    super.key,
    this.showAppBar = true,
    this.initialSubTabIndex = 0,
  });

  @override
  State<SuperadminEmployeeScreen> createState() => _SuperadminEmployeeScreenState();
}

class _SuperadminEmployeeScreenState extends State<SuperadminEmployeeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  final TextEditingController _roleSearchController = TextEditingController();
  final TextEditingController _employeeSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialSubTabIndex,
    );
  }

  @override
  void dispose() {
    _subTabController.dispose();
    _roleSearchController.dispose();
    _employeeSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empProv = context.watch<EmployeeManagementProvider>();

    final content = Column(
      children: [
        // Top Segmented Sub-Tab Bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _subTabController,
            indicator: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 16),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Peran & Akses',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.badge_outlined, size: 16),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Data Pegawai',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Sub Tab Views
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _buildRoleManagementView(context, empProv),
              _buildEmployeeDataView(context, empProv),
            ],
          ),
        ),
      ],
    );

    if (!widget.showAppBar) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Manajemen Pegawai & Peran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Tambah Pegawai Baru',
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.secondary),
            onPressed: () => _showAddEmployeeModal(context, empProv),
          ),
        ],
      ),
      body: content,
    );
  }

  // ==========================================
  // TAB 1: MANAJEMEN PERAN AKUN & PENGGUNA
  // ==========================================
  Widget _buildRoleManagementView(
      BuildContext context, EmployeeManagementProvider empProv) {
    final employees = empProv.filteredEmployees;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Role Breakdown Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribusi Hak Akses Sistem',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRoleMiniStat(
                            title: 'Staff IT',
                            count: '${empProv.totalStaffIT}',
                            color: AppColors.roleStaffIT,
                            icon: Icons.shield_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildRoleMiniStat(
                            title: 'Direktur',
                            count: '${empProv.totalDirektur}',
                            color: AppColors.roleDirektur,
                            icon: Icons.admin_panel_settings_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildRoleMiniStat(
                            title: 'Karyawan',
                            count: '${empProv.totalKaryawan}',
                            color: AppColors.roleKaryawan,
                            icon: Icons.badge_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search bar with clear button
              TextField(
                controller: _roleSearchController,
                onChanged: (v) {
                  setState(() {});
                  empProv.setSearchQuery(v);
                },
                decoration: InputDecoration(
                  hintText: 'Cari akun nama, NIK, atau divisi...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.onSurfaceVariant),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.secondary),
                  suffixIcon: _roleSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _roleSearchController.clear();
                            setState(() {});
                            empProv.setSearchQuery('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  fillColor: AppColors.surfaceContainerLowest,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Sort Toolbar Row
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildSortButton(context, empProv),
                          const SizedBox(width: 6),
                          _buildSortDirectionToggle(empProv),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterSummaryText(empProv, _roleSearchController),
                ],
              ),
              const SizedBox(height: 10),

              // Role Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Semua Akun (${empProv.totalEmployees})',
                      isSelected: empProv.filterRole == null,
                      onTap: () => empProv.setFilterRole(null),
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      label: 'Staff IT (Superadmin)',
                      isSelected: empProv.filterRole == UserRole.staffIT,
                      color: AppColors.roleStaffIT,
                      onTap: () => empProv.setFilterRole(
                        empProv.filterRole == UserRole.staffIT ? null : UserRole.staffIT,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      label: 'Direktur (Admin)',
                      isSelected: empProv.filterRole == UserRole.direktur,
                      color: AppColors.roleDirektur,
                      onTap: () => empProv.setFilterRole(
                        empProv.filterRole == UserRole.direktur ? null : UserRole.direktur,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      label: 'Karyawan',
                      isSelected: empProv.filterRole == UserRole.karyawan,
                      color: AppColors.roleKaryawan,
                      onTap: () => empProv.setFilterRole(
                        empProv.filterRole == UserRole.karyawan ? null : UserRole.karyawan,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // List of Accounts or Empty State
              if (employees.isEmpty)
                _buildEmptyState(context, empProv, _roleSearchController)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: employees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = employees[index];
                    return _buildUserRoleCard(context, user, empProv);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleMiniStat({
    required String title,
    required String count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserRoleCard(
    BuildContext context,
    UserModel user,
    EmployeeManagementProvider empProv,
  ) {
    final currentSuperadmin = context.watch<AuthProvider>().currentUser;
    final isSelf = user.id == currentSuperadmin.id;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.15),
                child: Text(
                  user.name.isNotEmpty ? user.name[0] : 'U',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getRoleColor(user.role),
                  ),
                ),
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
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Anda',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIK: ${user.nip} • ${user.department}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              RoleBadge(role: user.role),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEAEDFF)),
          const SizedBox(height: 8),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showResetPinModal(context, user, empProv),
                icon: const Icon(Icons.key_rounded, size: 14),
                label: const Text('Reset PIN', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: () => _showChangeRoleModal(context, user, empProv),
                icon: const Icon(Icons.manage_accounts_rounded, size: 14),
                label: const Text('Ubah Role', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: MANAJEMEN DATA PEGAWAI
  // ==========================================
  Widget _buildEmployeeDataView(
      BuildContext context, EmployeeManagementProvider empProv) {
    final employees = empProv.filteredEmployees;
    final settingsProv = context.watch<SystemSettingsProvider>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Direktori Kepegawaian',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Total ${empProv.totalEmployees} Pegawai Terdaftar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEmployeeModal(context, empProv),
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text('Tambah Pegawai'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Bar with clear button
              TextField(
                controller: _employeeSearchController,
                onChanged: (v) {
                  setState(() {});
                  empProv.setSearchQuery(v);
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama pegawai, NIK, divisi, kantor...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.onSurfaceVariant),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.secondary),
                  suffixIcon: _employeeSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _employeeSearchController.clear();
                            setState(() {});
                            empProv.setSearchQuery('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  fillColor: AppColors.surfaceContainerLowest,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Sort & Filter Toolbar
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildSortButton(context, empProv),
                          const SizedBox(width: 6),
                          _buildSortDirectionToggle(empProv),
                          const SizedBox(width: 6),
                          _buildFilterSheetButton(context, empProv, settingsProv),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterSummaryText(empProv, _employeeSearchController),
                ],
              ),
              const SizedBox(height: 10),

              // Primary Office / Cabang Quick Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Semua Cabang',
                      isSelected: empProv.filterOfficeId == null || empProv.filterOfficeId!.isEmpty,
                      onTap: () => empProv.setFilterOffice(null),
                    ),
                    ...settingsProv.geofencing.offices.map((office) {
                      final isSel = empProv.filterOfficeId == office.id;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _buildFilterChip(
                          label: office.name,
                          isSelected: isSel,
                          color: office.isPrimary ? AppColors.primary : AppColors.secondary,
                          onTap: () => empProv.setFilterOffice(isSel ? null : office.id),
                        ),
                      );
                    }),
                    if (empProv.filterDepartment != null && empProv.filterDepartment!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _buildActiveFilterDismissChip(
                        label: 'Divisi: ${empProv.filterDepartment}',
                        onDismiss: () => empProv.setFilterDepartment(null),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Employee Directory Cards or Empty State
              if (employees.isEmpty)
                _buildEmptyState(context, empProv, _employeeSearchController)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: employees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = employees[index];
                    return _buildEmployeeItemCard(context, user, empProv);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeItemCard(
    BuildContext context,
    UserModel user,
    EmployeeManagementProvider empProv,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
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
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                child: ClipOval(
                  child: user.avatarUrl != null
                      ? Image.network(
                          user.avatarUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                user.name.isNotEmpty ? user.name[0] : 'P',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            user.name.isNotEmpty ? user.name[0] : 'P',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIK: ${user.nip} • ${user.position}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.department,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.store_mall_directory_rounded, size: 11, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Penempatan: ${user.officeName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.statusPegawai,
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEAEDFF)),
          const SizedBox(height: 8),

          // Action Buttons: Detail, Edit, Deactivate
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showEmployeeDetailSheet(context, user),
                icon: const Icon(Icons.visibility_outlined, size: 14),
                label: const Text('Detail', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 4),
              OutlinedButton.icon(
                onPressed: () => _showEditEmployeeModal(context, user, empProv),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Ubah Data', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SORT & FILTER UI HELPERS & MODALS
  // ==========================================

  Widget _buildSortButton(
    BuildContext context,
    EmployeeManagementProvider empProv,
  ) {
    final sort = empProv.sortOption;
    final isCustomSort = sort != EmployeeSortOption.nameAsc;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSortBottomSheet(context, empProv),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
          decoration: BoxDecoration(
            color: isCustomSort
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCustomSort
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                sort.icon,
                size: 14,
                color: isCustomSort ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                'Urut: ${sort.shortLabel}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isCustomSort ? FontWeight.w700 : FontWeight.w600,
                  color: isCustomSort ? AppColors.primary : AppColors.onSurface,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isCustomSort ? AppColors.primary : AppColors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortDirectionToggle(EmployeeManagementProvider empProv) {
    final isAsc = empProv.sortOption.isAscending;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => empProv.toggleSortDirection(),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Icon(
            isAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 14,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSheetButton(
    BuildContext context,
    EmployeeManagementProvider empProv,
    SystemSettingsProvider settingsProv,
  ) {
    final filterCount = (empProv.filterOfficeId != null && empProv.filterOfficeId!.isNotEmpty ? 1 : 0) +
        (empProv.filterDepartment != null && empProv.filterDepartment!.isNotEmpty ? 1 : 0) +
        (empProv.filterRole != null ? 1 : 0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showFilterBottomSheet(context, empProv, settingsProv),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
          decoration: BoxDecoration(
            color: filterCount > 0
                ? AppColors.secondary.withValues(alpha: 0.1)
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: filterCount > 0
                  ? AppColors.secondary.withValues(alpha: 0.45)
                  : AppColors.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 14,
                color: filterCount > 0 ? AppColors.secondary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                'Filter',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: filterCount > 0 ? FontWeight.w700 : FontWeight.w600,
                  color: filterCount > 0 ? AppColors.secondary : AppColors.onSurface,
                  fontFamily: 'Inter',
                ),
              ),
              if (filterCount > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$filterCount',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSummaryText(
    EmployeeManagementProvider empProv,
    TextEditingController controller,
  ) {
    if (empProv.hasActiveFilters) {
      return GestureDetector(
        onTap: () {
          controller.clear();
          setState(() {});
          empProv.resetFilters();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restart_alt_rounded, size: 12, color: AppColors.secondary),
              SizedBox(width: 3),
              Text(
                'Reset',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Text(
      '${empProv.filteredEmployees.length} Pegawai',
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
    );
  }

  Widget _buildActiveFilterDismissChip({
    required String label,
    required VoidCallback onDismiss,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(
              Icons.cancel_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    EmployeeManagementProvider empProv,
    TextEditingController controller,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_rounded,
              size: 38,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tidak Ada Pegawai Ditemukan',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Kriteria pencarian, filter cabang, divisi, atau sortir tidak cocok dengan pegawai mana pun.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              controller.clear();
              setState(() {});
              empProv.resetFilters();
            },
            icon: const Icon(Icons.restart_alt_rounded, size: 15),
            label: const Text('Reset Semua Filter & Pencarian'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortBottomSheet(
    BuildContext context,
    EmployeeManagementProvider empProv,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final currentSort = empProv.sortOption;

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                // Sheet Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Urutkan Direktori Pegawai',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Inter',
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pilih kriteria urutan daftar pegawai & akun',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFEAEDFF)),

                // Sort Options List
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: EmployeeSortOption.values.length,
                    itemBuilder: (context, index) {
                      final option = EmployeeSortOption.values[index];
                      final isSelected = option == currentSort;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.35)
                                : Colors.transparent,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              empProv.setSortOption(option);
                              Navigator.pop(ctx);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.15)
                                          : AppColors.surfaceContainer,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      option.icon,
                                      size: 18,
                                      color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                            color: isSelected ? AppColors.primary : AppColors.onSurface,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          option.description,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  isSelected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                        )
                                      : const Icon(
                                          Icons.radio_button_unchecked_rounded,
                                          color: AppColors.outline,
                                          size: 18,
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet(
    BuildContext context,
    EmployeeManagementProvider empProv,
    SystemSettingsProvider settingsProv,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final offices = settingsProv.geofencing.offices;
            final departments = empProv.departmentList;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Grab handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    // Sheet Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Filter Lanjutan Pegawai',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Saring pegawai berdasarkan kantor, divisi & peran',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFEAEDFF)),

                    // Scrollable Filter Sections
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section 1: Kantor Penempatan
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Kantor Penempatan',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                if (empProv.filterOfficeId != null && empProv.filterOfficeId!.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      empProv.setFilterOffice(null);
                                      setModalState(() {});
                                    },
                                    child: const Text(
                                      'Reset',
                                      style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildFilterChip(
                                  label: 'Semua Cabang',
                                  isSelected: empProv.filterOfficeId == null || empProv.filterOfficeId!.isEmpty,
                                  onTap: () {
                                    empProv.setFilterOffice(null);
                                    setModalState(() {});
                                  },
                                ),
                                ...offices.map((office) {
                                  final isSel = empProv.filterOfficeId == office.id;
                                  return _buildFilterChip(
                                    label: office.name,
                                    isSelected: isSel,
                                    color: office.isPrimary ? AppColors.primary : AppColors.secondary,
                                    onTap: () {
                                      empProv.setFilterOffice(isSel ? null : office.id);
                                      setModalState(() {});
                                    },
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Section 2: Divisi & Departemen
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Divisi & Departemen',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                if (empProv.filterDepartment != null && empProv.filterDepartment!.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      empProv.setFilterDepartment(null);
                                      setModalState(() {});
                                    },
                                    child: const Text(
                                      'Reset',
                                      style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildFilterChip(
                                  label: 'Semua Divisi',
                                  isSelected: empProv.filterDepartment == null || empProv.filterDepartment!.isEmpty,
                                  onTap: () {
                                    empProv.setFilterDepartment(null);
                                    setModalState(() {});
                                  },
                                ),
                                ...departments.map((dept) {
                                  final isSel = empProv.filterDepartment == dept;
                                  return _buildFilterChip(
                                    label: dept,
                                    isSelected: isSel,
                                    onTap: () {
                                      empProv.setFilterDepartment(isSel ? null : dept);
                                      setModalState(() {});
                                    },
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Section 3: Peran & Akses Akun
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Peran & Hak Akses',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                if (empProv.filterRole != null)
                                  GestureDetector(
                                    onTap: () {
                                      empProv.setFilterRole(null);
                                      setModalState(() {});
                                    },
                                    child: const Text(
                                      'Reset',
                                      style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildFilterChip(
                                  label: 'Semua Peran',
                                  isSelected: empProv.filterRole == null,
                                  onTap: () {
                                    empProv.setFilterRole(null);
                                    setModalState(() {});
                                  },
                                ),
                                _buildFilterChip(
                                  label: 'Staff IT (Superadmin)',
                                  isSelected: empProv.filterRole == UserRole.staffIT,
                                  color: AppColors.roleStaffIT,
                                  onTap: () {
                                    empProv.setFilterRole(empProv.filterRole == UserRole.staffIT ? null : UserRole.staffIT);
                                    setModalState(() {});
                                  },
                                ),
                                _buildFilterChip(
                                  label: 'Direktur (Admin)',
                                  isSelected: empProv.filterRole == UserRole.direktur,
                                  color: AppColors.roleDirektur,
                                  onTap: () {
                                    empProv.setFilterRole(empProv.filterRole == UserRole.direktur ? null : UserRole.direktur);
                                    setModalState(() {});
                                  },
                                ),
                                _buildFilterChip(
                                  label: 'Karyawan',
                                  isSelected: empProv.filterRole == UserRole.karyawan,
                                  color: AppColors.roleKaryawan,
                                  onTap: () {
                                    empProv.setFilterRole(empProv.filterRole == UserRole.karyawan ? null : UserRole.karyawan);
                                    setModalState(() {});
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFEAEDFF)),

                    // Footer Buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                empProv.resetFilters();
                                setModalState(() {});
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.onSurfaceVariant,
                                side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Reset Filter'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Terapkan (${empProv.filteredEmployees.length} Pegawai)'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // MODALS & DIALOGS
  // ==========================================

  void _showChangeRoleModal(
    BuildContext context,
    UserModel user,
    EmployeeManagementProvider empProv,
  ) {
    UserRole selectedRole = user.role;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ubah Peran & Hak Akses',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tetapkan tingkatan wewenang sistem untuk ${user.name} (${user.nip})',
                    style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  // Option 1: Staff IT (Superadmin)
                  _buildRoleOptionCard(
                    title: 'Staff IT (Superadmin)',
                    subtitle: 'Akses penuh manajemen user, jam kerja, lokasi kantor, dan audit',
                    color: AppColors.roleStaffIT,
                    isSelected: selectedRole == UserRole.staffIT,
                    onTap: () => setModalState(() => selectedRole = UserRole.staffIT),
                  ),
                  const SizedBox(height: 8),

                  // Option 2: Direktur (Admin)
                  _buildRoleOptionCard(
                    title: 'Direktur (Admin)',
                    subtitle: 'Akses dashboard eksekutif kehadiran & persetujuan presensi',
                    color: AppColors.roleDirektur,
                    isSelected: selectedRole == UserRole.direktur,
                    onTap: () => setModalState(() => selectedRole = UserRole.direktur),
                  ),
                  const SizedBox(height: 8),

                  // Option 3: Karyawan (User)
                  _buildRoleOptionCard(
                    title: 'Karyawan (User Lapangan)',
                    subtitle: 'Akses 4 tombol sesi presensi mandiri dan pengajuan persetujuan presensi',
                    color: AppColors.roleKaryawan,
                    isSelected: selectedRole == UserRole.karyawan,
                    onTap: () => setModalState(() => selectedRole = UserRole.karyawan),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      await empProv.updateUserRole(
                        userId: user.id,
                        newRole: selectedRole,
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Peran ${user.name} berhasil diubah menjadi ${selectedRole.displayName}.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Simpan Perubahan Peran'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleOptionCard({
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.outlineVariant.withValues(alpha: 0.35),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? color : AppColors.outline,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPinModal(
    BuildContext context,
    UserModel user,
    EmployeeManagementProvider empProv,
  ) {
    final pinController = TextEditingController(text: '123456');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset PIN Karyawan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset PIN autentikasi presensi untuk pegawai ${user.name} (NIK: ${user.nip}):',
              style: const TextStyle(fontSize: 12.5, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'PIN Baru 6 digit',
                counterText: '',
                fillColor: AppColors.background,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPin = pinController.text.trim();
              if (newPin.length == 6) {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                await empProv.resetPin(user.id, newPin);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('PIN untuk ${user.name} berhasil direset ke: $newPin'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Simpan PIN Baru'),
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeModal(
    BuildContext context,
    EmployeeManagementProvider empProv,
  ) {
    final nipCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final deptCtrl = TextEditingController(text: 'Operasional Lapangan');
    final posCtrl = TextEditingController(text: 'Staff Lapangan');
    final phoneCtrl = TextEditingController();
    UserRole selectedRole = UserRole.karyawan;
    final settingsProv = context.read<SystemSettingsProvider>();
    final offices = settingsProv.geofencing.offices;
    String selectedOfficeId = offices.isNotEmpty ? offices.first.id : 'hq';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tambah Pegawai Baru',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: nipCtrl,
                      decoration: const InputDecoration(
                        labelText: 'NIP / NIK Karyawan',
                        hintText: 'Contoh: P005 / PA005',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap (dengan Gelar)',
                        hintText: 'Contoh: Ahmad Fadilah, S.T.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: deptCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Divisi / Penempatan Unit Kerja',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: posCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Jabatan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Dropdown Kantor Penempatan Cabang
                    DropdownButtonFormField<String>(
                      initialValue: selectedOfficeId,
                      decoration: const InputDecoration(
                        labelText: 'Kantor Penempatan (Cabang)',
                        border: OutlineInputBorder(),
                      ),
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
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedOfficeId = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'No. WhatsApp / HP',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Peran Akun',
                        border: OutlineInputBorder(),
                      ),
                      items: UserRole.values.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r.displayName));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedRole = v);
                      },
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () async {
                        if (nipCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('NIP dan Nama wajib diisi.')),
                          );
                          return;
                        }

                        final chosenOffice = offices.firstWhere(
                          (o) => o.id == selectedOfficeId,
                          orElse: () => offices.first,
                        );

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        await empProv.addEmployee(
                          nip: nipCtrl.text.trim(),
                          name: nameCtrl.text.trim(),
                          department: deptCtrl.text.trim(),
                          position: posCtrl.text.trim(),
                          role: selectedRole,
                          phone: phoneCtrl.text.trim(),
                          officeId: chosenOffice.id,
                          officeName: chosenOffice.name,
                        );
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Pegawai ${nameCtrl.text.trim()} berhasil ditambahkan di ${chosenOffice.name}.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Simpan Pegawai Baru'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditEmployeeModal(
    BuildContext context,
    UserModel user,
    EmployeeManagementProvider empProv,
  ) {
    final nipCtrl = TextEditingController(text: user.nip);
    final nameCtrl = TextEditingController(text: user.name);
    final deptCtrl = TextEditingController(text: user.department);
    final posCtrl = TextEditingController(text: user.position);
    final phoneCtrl = TextEditingController(text: user.phone);
    final settingsProv = context.read<SystemSettingsProvider>();
    final offices = settingsProv.geofencing.offices;
    String selectedOfficeId = user.officeId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ubah Data Pegawai (${user.nip})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: nipCtrl,
                    decoration: const InputDecoration(labelText: 'NIP / NIK', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: deptCtrl,
                    decoration: const InputDecoration(labelText: 'Divisi / Unit Kerja', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: posCtrl,
                    decoration: const InputDecoration(labelText: 'Jabatan', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  // Dropdown Kantor Penempatan Cabang
                  DropdownButtonFormField<String>(
                    initialValue: selectedOfficeId,
                    decoration: const InputDecoration(
                      labelText: 'Kantor Penempatan (Cabang)',
                      border: OutlineInputBorder(),
                    ),
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
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedOfficeId = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'No. Telepon / WhatsApp', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () async {
                      final chosenOffice = offices.firstWhere(
                        (o) => o.id == selectedOfficeId,
                        orElse: () => offices.first,
                      );
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      final updated = user.copyWith(
                        nip: nipCtrl.text.trim(),
                        name: nameCtrl.text.trim(),
                        department: deptCtrl.text.trim(),
                        position: posCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        officeId: chosenOffice.id,
                        officeName: chosenOffice.name,
                      );
                      await empProv.updateEmployeeData(updated);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Data pegawai diperbarui (Penempatan: ${chosenOffice.name}).'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Simpan Perubahan'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEmployeeDetailSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                    backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.name.isNotEmpty ? user.name[0] : 'P',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIK: ${user.nip}',
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        RoleBadge(role: user.role),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEAEDFF)),
              const SizedBox(height: 14),

              _buildDetailRow('Unit Kerja / Divisi', user.department),
              const SizedBox(height: 8),
              _buildDetailRow('Kantor Penempatan', user.officeName),
              const SizedBox(height: 8),
              _buildDetailRow('Jabatan Resmi', user.position),
              const SizedBox(height: 8),
              _buildDetailRow('Status Kepegawaian', user.statusPegawai),
              const SizedBox(height: 8),
              _buildDetailRow('No. WhatsApp / HP', user.phone),
              const SizedBox(height: 8),
              _buildDetailRow('Email Perusahaan', user.email),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Tutup Detail Pegawai'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final activeColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.staffIT:
        return AppColors.roleStaffIT;
      case UserRole.direktur:
        return AppColors.roleDirektur;
      case UserRole.karyawan:
        return AppColors.roleKaryawan;
    }
  }
}
