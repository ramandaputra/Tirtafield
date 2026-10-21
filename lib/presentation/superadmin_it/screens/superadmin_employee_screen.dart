import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../data/constants/bidang_data.dart';
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
    BidangData.syncFromDatabase();
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
                      'Role',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRoleMiniStat(
                            title: 'Superadmin',
                            count: '${empProv.totalStaffIT}',
                            color: AppColors.roleStaffIT,
                            icon: Icons.shield_rounded,
                            isSelected: empProv.filterRole == UserRole.staffIT,
                            onTap: () => empProv.setFilterRole(
                              empProv.filterRole == UserRole.staffIT ? null : UserRole.staffIT,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildRoleMiniStat(
                            title: 'Admin',
                            count: '${empProv.totalDirektur}',
                            color: AppColors.roleDirektur,
                            icon: Icons.admin_panel_settings_rounded,
                            isSelected: empProv.filterRole == UserRole.direktur,
                            onTap: () => empProv.setFilterRole(
                              empProv.filterRole == UserRole.direktur ? null : UserRole.direktur,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildRoleMiniStat(
                            title: 'Pengguna',
                            count: '${empProv.totalKaryawan}',
                            color: AppColors.roleKaryawan,
                            icon: Icons.badge_rounded,
                            isSelected: empProv.filterRole == UserRole.karyawan,
                            onTap: () => empProv.setFilterRole(
                              empProv.filterRole == UserRole.karyawan ? null : UserRole.karyawan,
                            ),
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
                  hintText: 'Cari akun nama, NIK, atau bidang...',
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSortButton(context, empProv),
                  Text(
                    '${empProv.filteredEmployees.length} Akun',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Role Filter Dropdown (Semua Akun, Superadmin, Admin, Pengguna)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserRole?>(
                    value: empProv.filterRole,
                    isExpanded: true,
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: AppColors.surfaceContainerLowest,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    items: [
                      DropdownMenuItem<UserRole?>(
                        value: null,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.groups_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Semua Akun',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${empProv.totalEmployees} Akun',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem<UserRole?>(
                        value: UserRole.staffIT,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shield_rounded,
                              size: 16,
                              color: AppColors.roleStaffIT,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Superadmin',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.roleStaffIT.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${empProv.totalStaffIT}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.roleStaffIT,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem<UserRole?>(
                        value: UserRole.direktur,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.admin_panel_settings_rounded,
                              size: 16,
                              color: AppColors.roleDirektur,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.roleDirektur.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${empProv.totalDirektur}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.roleDirektur,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem<UserRole?>(
                        value: UserRole.karyawan,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.badge_rounded,
                              size: 16,
                              color: AppColors.roleKaryawan,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Pengguna',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.roleKaryawan.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${empProv.totalKaryawan}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.roleKaryawan,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (role) {
                      empProv.setFilterRole(role);
                    },
                  ),
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
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.16) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : color.withValues(alpha: 0.2),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }
    return card;
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

          // Actions Row: Reset PIN & Ubah Role (Lebar Seimbang & Konsisten)
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showResetPinModal(context, user, empProv),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD97706).withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.key_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Reset PIN',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showChangeRoleModal(context, user, empProv),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.manage_accounts_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Ubah Role',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
              // Header Direktori Kepegawaian
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Direktori Kepegawaian',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total ${empProv.totalEmployees} Pegawai Terdaftar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
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
                  hintText: 'Cari nama pegawai, NIK, bidang, kantor...',
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

              // Sort Toolbar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSortButton(context, empProv),
                  Text(
                    '${empProv.filteredEmployees.length} Pegawai',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Office Sort & Filter Dropdown
              Builder(
                builder: (context) {
                  final officeDropdownValue = settingsProv.geofencing.offices
                          .any((o) => o.id == empProv.filterOfficeId)
                      ? empProv.filterOfficeId
                      : null;

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: officeDropdownValue,
                        isExpanded: true,
                        icon: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        dropdownColor: AppColors.surfaceContainerLowest,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.corporate_fare_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Semua Kantor',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${empProv.totalEmployees} Pegawai',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...settingsProv.geofencing.offices.map((office) {
                            final empCount = empProv.employees
                                .where((u) => u.officeId == office.id)
                                .length;
                            final color = office.isPrimary
                                ? AppColors.primary
                                : AppColors.secondary;
                            return DropdownMenuItem<String?>(
                              value: office.id,
                              child: Row(
                                children: [
                                  Icon(
                                    office.isPrimary
                                        ? Icons.star_rounded
                                        : Icons.store_mall_directory_rounded,
                                    size: 16,
                                    color: color,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      office.name,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface,
                                        fontFamily: 'Inter',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$empCount Pegawai',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) => empProv.setFilterOffice(val),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Tombol Tambah Pegawai (Dipindahkan ke bawah sort dropdown)
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEmployeeModal(context, empProv),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text(
                    'Tambah Pegawai Baru',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                ),
              ),
              if (empProv.filterDepartment != null &&
                  empProv.filterDepartment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildActiveFilterDismissChip(
                    label: 'Bidang: ${empProv.filterDepartment}',
                    onDismiss: () => empProv.setFilterDepartment(null),
                  ),
                ),
              ],
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
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEAEDFF)),
          const SizedBox(height: 8),

          // Actions Row: Detail & Ubah Data (Lebar Seimbang & Konsisten, Solid Color + Tulisan Putih)
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showEmployeeDetailSheet(context, user),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Detail',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showEditEmployeeModal(context, user, empProv),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Ubah Data',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
            'Kriteria pencarian, filter cabang, bidang, atau sortir tidak cocok dengan pegawai mana pun.',
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

                  // Option 1: Superadmin
                  _buildRoleOptionCard(
                    title: 'Superadmin',
                    subtitle: 'Akses penuh manajemen user, jam kerja, lokasi kantor, dan audit sistem',
                    color: AppColors.roleStaffIT,
                    isSelected: selectedRole == UserRole.staffIT,
                    onTap: () => setModalState(() => selectedRole = UserRole.staffIT),
                  ),
                  const SizedBox(height: 8),

                  // Option 2: Admin
                  _buildRoleOptionCard(
                    title: 'Admin',
                    subtitle: 'Akses dashboard eksekutif kehadiran & persetujuan presensi',
                    color: AppColors.roleDirektur,
                    isSelected: selectedRole == UserRole.direktur,
                    onTap: () => setModalState(() => selectedRole = UserRole.direktur),
                  ),
                  const SizedBox(height: 8),

                  // Option 3: Pengguna
                  _buildRoleOptionCard(
                    title: 'Pengguna',
                    subtitle: 'Akses sesi presensi mandiri dan pengajuan persetujuan presensi',
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
    String selectedBidang = BidangData.mainOperationalBidang.first;
    String selectedSeksi = BidangData.getSeksiForBidang(selectedBidang).first;
    final deptCtrl = TextEditingController(text: selectedBidang);
    final posCtrl = TextEditingController(text: selectedSeksi);
    final phoneCtrl = TextEditingController();
    UserRole selectedRole = UserRole.karyawan;
    final settingsProv = context.read<SystemSettingsProvider>();
    final offices = settingsProv.geofencing.offices;
    String selectedOfficeId = offices.isNotEmpty ? offices.first.id : 'hq';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;
          final screenHeight = MediaQuery.of(ctx).size.height;

          return Center(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.88,
                maxWidth: 520,
              ),
              margin: EdgeInsets.only(bottom: keyboardHeight),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header with Grab Handle & Close Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.outlineVariant.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.person_add_rounded,
                                      size: 18,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Tambah Pegawai Baru',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // 2. Scrollable Form Body
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: nipCtrl,
                              decoration: const InputDecoration(
                                labelText: 'NIK',
                                hintText: 'Contoh: 2171012345678901',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nama Lengkap (dengan Gelar)',
                                hintText: 'Contoh: Ahmad Fadilah, S.T.',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Dropdown Bidang
                            DropdownButtonFormField<String>(
                              initialValue: selectedBidang,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Bidang',
                                prefixIcon: Icon(Icons.business_rounded, size: 20),
                                border: OutlineInputBorder(),
                              ),
                              items: BidangData.allBidang.map((b) {
                                return DropdownMenuItem<String>(
                                  value: b,
                                  child: Text(
                                    b,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    selectedBidang = val;
                                    deptCtrl.text = val;
                                    final listSeksi = BidangData.getSeksiForBidang(val);
                                    selectedSeksi = listSeksi.first;
                                    posCtrl.text = selectedSeksi;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            // Dropdown Seksi Bidang (Terintegrasi)
                            DropdownButtonFormField<String>(
                              key: ValueKey('add_seksi_$selectedBidang'),
                              initialValue: BidangData.getSeksiForBidang(selectedBidang).contains(selectedSeksi)
                                  ? selectedSeksi
                                  : BidangData.getSeksiForBidang(selectedBidang).first,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Seksi Bidang',
                                prefixIcon: Icon(Icons.assignment_ind_rounded, size: 20),
                                border: OutlineInputBorder(),
                              ),
                              items: BidangData.getSeksiForBidang(selectedBidang).map((s) {
                                return DropdownMenuItem<String>(
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
                                  setModalState(() {
                                    selectedSeksi = val;
                                    posCtrl.text = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            // Dropdown Kantor Penempatan Cabang
                            DropdownButtonFormField<String>(
                              initialValue: offices.any((o) => o.id == selectedOfficeId)
                                  ? selectedOfficeId
                                  : (offices.isNotEmpty ? offices.first.id : null),
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Kantor Penempatan',
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
                            const SizedBox(height: 12),
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
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Peran Akun',
                                border: OutlineInputBorder(),
                              ),
                              items: UserRole.values.map((r) {
                                return DropdownMenuItem(
                                  value: r,
                                  child: Text(r.displayName),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) setModalState(() => selectedRole = v);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Sticky Footer with Submit Button
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.outlineVariant.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nipCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('NIK dan Nama wajib diisi.')),
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
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text(
                          'Simpan Pegawai Baru',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
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
    String selectedBidang = BidangData.normalizeBidang(user.department);
    String selectedSeksi = BidangData.normalizeSeksi(selectedBidang, user.position);
    final deptCtrl = TextEditingController(text: selectedBidang);
    final posCtrl = TextEditingController(text: selectedSeksi);
    final phoneCtrl = TextEditingController(text: user.phone);
    final settingsProv = context.read<SystemSettingsProvider>();
    final offices = settingsProv.geofencing.offices;
    String selectedOfficeId = user.officeId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;
          final screenHeight = MediaQuery.of(ctx).size.height;

          return Center(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.88,
                maxWidth: 520,
              ),
              margin: EdgeInsets.only(bottom: keyboardHeight),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header with Grab Handle & Close Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.outlineVariant.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.edit_note_rounded,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Ubah Data Pegawai',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'NIK: ${user.nip} • ${user.name}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // 2. Scrollable Form Body
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: nipCtrl,
                              decoration: const InputDecoration(
                                labelText: 'NIK',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nama Lengkap',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Dropdown Bidang
                            DropdownButtonFormField<String>(
                              initialValue: BidangData.allBidang.contains(selectedBidang)
                                  ? selectedBidang
                                  : BidangData.allBidang.first,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Bidang',
                                prefixIcon: Icon(Icons.business_rounded, size: 20),
                                border: OutlineInputBorder(),
                              ),
                              items: BidangData.allBidang.map((b) {
                                return DropdownMenuItem<String>(
                                  value: b,
                                  child: Text(
                                    b,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() {
                                    selectedBidang = val;
                                    deptCtrl.text = val;
                                    final listSeksi = BidangData.getSeksiForBidang(val);
                                    selectedSeksi = listSeksi.first;
                                    posCtrl.text = selectedSeksi;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            // Dropdown Seksi Bidang (Terintegrasi)
                            DropdownButtonFormField<String>(
                              key: ValueKey('edit_seksi_$selectedBidang'),
                              initialValue: BidangData.getSeksiForBidang(selectedBidang).contains(selectedSeksi)
                                  ? selectedSeksi
                                  : BidangData.getSeksiForBidang(selectedBidang).first,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Seksi Bidang',
                                prefixIcon: Icon(Icons.assignment_ind_rounded, size: 20),
                                border: OutlineInputBorder(),
                              ),
                              items: BidangData.getSeksiForBidang(selectedBidang).map((s) {
                                return DropdownMenuItem<String>(
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
                                  setSheetState(() {
                                    selectedSeksi = val;
                                    posCtrl.text = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            // Dropdown Kantor Penempatan Cabang
                            DropdownButtonFormField<String>(
                              initialValue: offices.any((o) => o.id == selectedOfficeId)
                                  ? selectedOfficeId
                                  : (offices.isNotEmpty ? offices.first.id : null),
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Kantor Penempatan',
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
                            const SizedBox(height: 12),
                            TextField(
                              controller: phoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'No. Telepon / WhatsApp',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Sticky Footer with Save Button
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.outlineVariant.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      child: ElevatedButton(
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
                              content: Text(
                                'Data pegawai diperbarui (Penempatan: ${chosenOffice.name}).',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
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

              _buildDetailRow('Bidang', user.department),
              const SizedBox(height: 8),
              _buildDetailRow('Kantor Penempatan', user.officeName),
              const SizedBox(height: 8),
              _buildDetailRow('Seksi Bidang', user.position),
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
