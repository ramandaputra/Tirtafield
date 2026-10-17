import 'package:flutter/material.dart';
import '../../data/models/approval_model.dart';
import '../constants/app_colors.dart';

class ApprovalStatusBadge extends StatelessWidget {
  final ApprovalStatus status;

  const ApprovalStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case ApprovalStatus.pending:
        bg = AppColors.warning.withValues(alpha: 0.12);
        fg = AppColors.warning;
        icon = Icons.access_time_rounded;
        break;
      case ApprovalStatus.approved:
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case ApprovalStatus.rejected:
        bg = AppColors.danger.withValues(alpha: 0.12);
        fg = AppColors.danger;
        icon = Icons.highlight_off_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
