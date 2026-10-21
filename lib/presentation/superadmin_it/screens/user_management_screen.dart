import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../data/constants/bidang_data.dart';
import '../../../data/models/user_model.dart';
import '../../../state/auth_provider.dart';
import '../../../state/system_settings_provider.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final users = authProv.availableUsers;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Kelola Pengguna & Peran Akun'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Tambah User', style: TextStyle(color: Colors.white)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = users[index];
          final isCurrentUser = user.id == authProv.currentUser.id;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.15),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0] : 'U',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getRoleColor(user.role),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Aktif',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${user.nip} • ${user.department}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            RoleBadge(role: user.role),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.secondary.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.business_rounded, size: 11, color: AppColors.secondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.officeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_note_rounded, color: AppColors.secondary),
                        tooltip: 'Edit Data Pengguna (Superadmin)',
                        onPressed: () => _showEditUserDialog(context, user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.switch_account_outlined, color: AppColors.primary),
                        tooltip: 'Masuk Sebagai User Ini',
                        onPressed: () {
                          context.read<AuthProvider>().setCurrentUser(user);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Beralih login ke: ${user.name} (${user.role.displayName})'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    String selectedBidang = BidangData.normalizeBidang(user.department);
    String selectedSeksi = BidangData.normalizeSeksi(selectedBidang, user.position);
    final deptCtrl = TextEditingController(text: selectedBidang);
    final posCtrl = TextEditingController(text: selectedSeksi);
    UserRole selectedRole = user.role;
    final settingsProv = context.read<SystemSettingsProvider>();
    final offices = settingsProv.geofencing.offices;
    String selectedOfficeId = offices.any((o) => o.id == user.officeId)
        ? user.officeId
        : (offices.isNotEmpty ? offices.first.id : 'hq');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final currentOffice = offices.firstWhere(
            (o) => o.id == selectedOfficeId,
            orElse: () => offices.first,
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded, color: AppColors.secondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit Pengguna (Superadmin)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'NIK: ${user.nip}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person_rounded),
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
                      prefixIcon: Icon(Icons.business_rounded),
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
                        setState(() {
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
                    key: ValueKey('edit_user_seksi_$selectedBidang'),
                    initialValue: BidangData.getSeksiForBidang(selectedBidang).contains(selectedSeksi)
                        ? selectedSeksi
                        : BidangData.getSeksiForBidang(selectedBidang).first,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Seksi Bidang',
                      prefixIcon: Icon(Icons.badge_rounded),
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
                        setState(() {
                          selectedSeksi = val;
                          posCtrl.text = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Dropdown Kantor Penempatan Cabang
                  DropdownButtonFormField<String>(
                    initialValue: selectedOfficeId,
                    decoration: const InputDecoration(
                      labelText: 'Kantor Penempatan',
                      prefixIcon: Icon(Icons.store_mall_directory_rounded),
                    ),
                    items: offices.map((office) {
                      return DropdownMenuItem<String>(
                        value: office.id,
                        child: Text(
                          '${office.name} (${office.officeTypeLabel})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedOfficeId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role Akses',
                      prefixIcon: Icon(Icons.security_rounded),
                    ),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedRole = val);
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
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    await context.read<AuthProvider>().updateUserInfoBySuperadmin(
                          targetUserId: user.id,
                          newName: nameCtrl.text.trim(),
                          newDepartment: deptCtrl.text.trim(),
                          newPosition: posCtrl.text.trim(),
                          newRole: selectedRole,
                          newOfficeId: currentOffice.id,
                          newOfficeName: currentOffice.name,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Data ${nameCtrl.text.trim()} berhasil diperbarui oleh Superadmin.'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Simpan Perubahan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.karyawan:
        return AppColors.roleKaryawan;
      case UserRole.direktur:
        return AppColors.roleDirektur;
      case UserRole.staffIT:
        return AppColors.roleStaffIT;
    }
  }

  void _showAddUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final nipCtrl = TextEditingController();
    String selectedBidang = BidangData.mainOperationalBidang.first;
    String selectedSeksi = BidangData.getSeksiForBidang(selectedBidang).first;
    final deptCtrl = TextEditingController(text: selectedBidang);
    final posCtrl = TextEditingController(text: selectedSeksi);
    UserRole selectedRole = UserRole.karyawan;
    final settingsProv = context.read<SystemSettingsProvider>();
    final offices = settingsProv.geofencing.offices;
    String selectedOfficeId = offices.isNotEmpty ? offices.first.id : 'hq';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final currentOffice = offices.firstWhere(
            (o) => o.id == selectedOfficeId,
            orElse: () => offices.first,
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Tambah Pengguna Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nipCtrl,
                    decoration: const InputDecoration(labelText: 'NIK'),
                  ),
                  const SizedBox(height: 12),
                  // Dropdown Bidang
                  DropdownButtonFormField<String>(
                    initialValue: selectedBidang,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Bidang',
                      prefixIcon: Icon(Icons.business_rounded),
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
                        setState(() {
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
                    key: ValueKey('add_user_seksi_$selectedBidang'),
                    initialValue: BidangData.getSeksiForBidang(selectedBidang).contains(selectedSeksi)
                        ? selectedSeksi
                        : BidangData.getSeksiForBidang(selectedBidang).first,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Seksi Bidang',
                      prefixIcon: Icon(Icons.badge_rounded),
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
                        setState(() {
                          selectedSeksi = val;
                          posCtrl.text = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedOfficeId,
                    decoration: const InputDecoration(labelText: 'Kantor Penempatan'),
                    items: offices.map((office) {
                      return DropdownMenuItem<String>(
                        value: office.id,
                        child: Text(
                          '${office.name} (${office.officeTypeLabel})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedOfficeId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Pilih Role'),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedRole = val);
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
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && nipCtrl.text.isNotEmpty) {
                    final newUser = UserModel(
                      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                      nip: nipCtrl.text.trim(),
                      name: nameCtrl.text.trim(),
                      email: '${nameCtrl.text.trim().toLowerCase().replaceAll(' ', '.')}@tirtafield.co.id',
                      role: selectedRole,
                      department: deptCtrl.text.isEmpty ? 'Bidang Hubungan Langganan' : deptCtrl.text.trim(),
                      position: posCtrl.text.isEmpty ? 'Seksi Pembacaan Meter' : posCtrl.text.trim(),
                      officeId: currentOffice.id,
                      officeName: currentOffice.name,
                    );
                    context.read<AuthProvider>().addUser(newUser);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }
}
