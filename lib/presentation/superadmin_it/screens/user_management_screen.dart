import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../data/models/user_model.dart';
import '../../../state/auth_provider.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final users = authProv.availableUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengguna & Role'),
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
                        RoleBadge(role: user.role),
                      ],
                    ),
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
            ),
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
    final deptCtrl = TextEditingController();
    UserRole selectedRole = UserRole.karyawan;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
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
                    decoration: const InputDecoration(labelText: 'NIP / ID Karyawan'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deptCtrl,
                    decoration: const InputDecoration(labelText: 'Departemen / Divisi'),
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
                      department: deptCtrl.text.isEmpty ? 'Umum' : deptCtrl.text.trim(),
                      position: selectedRole.displayName,
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
