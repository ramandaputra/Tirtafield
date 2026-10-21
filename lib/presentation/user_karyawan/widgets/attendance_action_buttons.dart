import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../data/models/attendance_model.dart';
import '../../../state/attendance_provider.dart';
import '../../../state/auth_provider.dart';

class AttendanceActionButtons extends StatelessWidget {
  const AttendanceActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceProv = context.watch<AttendanceProvider>();
    final authProv = context.watch<AuthProvider>();

    final slots = [
      AttendanceSlotType.masuk,
      AttendanceSlotType.istirahatKeluar,
      AttendanceSlotType.istirahatMasuk,
      AttendanceSlotType.pulang,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Aksi Presensi Harian (4x)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${attendanceProv.todayRecord?.completedSlotsCount ?? 0} dari 4 Selesai',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 2x2 Grid or Vertical list for responsiveness and clean touch targets
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[index];
            final item = attendanceProv.getSlotItem(slot);
            final isCompleted = item?.isCompleted ?? false;

            return _buildAttendanceCard(
              context: context,
              slot: slot,
              item: item,
              isCompleted: isCompleted,
              onTap: isCompleted
                  ? () {
                      _showCompletedDetail(context, slot, item!);
                    }
                  : () {
                      _showConfirmDialog(context, slot, authProv, attendanceProv);
                    },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAttendanceCard({
    required BuildContext context,
    required AttendanceSlotType slot,
    required AttendanceSlotItem? item,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: isCompleted
                ? slot.color.withValues(alpha: 0.07)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? slot.color.withValues(alpha: 0.4)
                  : AppColors.cardBorder,
              width: isCompleted ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isCompleted
                    ? slot.color.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Slot Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: slot.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(slot.icon, size: 20, color: slot.color),
                    ),
                    // Badge status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.cardBorder.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isCompleted ? 'SELESAI' : 'KE-${slot.slotNumber}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCompleted
                          ? DateTimeHelper.formatHHmmss(item!.recordedTime!)
                          : slot.description,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isCompleted ? FontWeight.w700 : FontWeight.w400,
                        color: isCompleted ? slot.color : AppColors.textSecondary,
                        fontFamily: isCompleted ? 'monospace' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    AttendanceSlotType slot,
    AuthProvider authProv,
    AttendanceProvider attendanceProv,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: slot.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(slot.icon, color: slot.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konfirmasi ${slot.title}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Karyawan: ${authProv.currentUser.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lokasi: Kantor Pusat PERUMDA Tirta Kepri (Radius: OK)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final success = await attendanceProv.performAttendance(
                          user: authProv.currentUser,
                          slotType: slot,
                        );
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: slot.color,
                              content: Text('Berhasil merekam ${slot.title}!'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: slot.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Kirim Presensi'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompletedDetail(
    BuildContext context,
    AttendanceSlotType slot,
    AttendanceSlotItem item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: slot.color),
            const SizedBox(width: 8),
            Text(slot.title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Waktu Presensi: ${DateTimeHelper.formatHHmmss(item.recordedTime!)} WIB'),
            const SizedBox(height: 6),
            Text('Tanggal: ${DateTimeHelper.formatReadableDate(item.recordedTime!)}'),
            const SizedBox(height: 6),
            Text('Lokasi: ${item.location ?? "-"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
