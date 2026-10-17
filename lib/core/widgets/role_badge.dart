import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../constants/app_colors.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    IconData icon;

    switch (role) {
      case UserRole.karyawan:
        bg = AppColors.roleKaryawan.withValues(alpha: 0.12);
        text = AppColors.roleKaryawan;
        icon = Icons.person_outline_rounded;
        break;
      case UserRole.direktur:
        bg = AppColors.roleDirektur.withValues(alpha: 0.12);
        text = AppColors.roleDirektur;
        icon = Icons.admin_panel_settings_outlined;
        break;
      case UserRole.staffIT:
        bg = AppColors.roleStaffIT.withValues(alpha: 0.12);
        text = AppColors.roleStaffIT;
        icon = Icons.terminal_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 4),
          Text(
            role.displayName,
            style: TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
