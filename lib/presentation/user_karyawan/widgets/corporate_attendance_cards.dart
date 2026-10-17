import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../data/models/attendance_model.dart';
import '../../../state/attendance_provider.dart';
import '../../../state/auth_provider.dart';
import '../screens/verifikasi_lokasi_screen.dart';

class CorporateAttendanceCards extends StatelessWidget {
  const CorporateAttendanceCards({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceProv = context.watch<AttendanceProvider>();
    final authProv = context.watch<AuthProvider>();

    // Check completion status for each of the 4 slots
    final isSlot1Done = attendanceProv.isSlotCompleted(AttendanceSlotType.masuk);
    final isSlot2Done =
        attendanceProv.isSlotCompleted(AttendanceSlotType.istirahatKeluar);
    final isSlot3Done =
        attendanceProv.isSlotCompleted(AttendanceSlotType.istirahatMasuk);
    final isSlot4Done =
        attendanceProv.isSlotCompleted(AttendanceSlotType.pulang);

    final slot1Item = attendanceProv.getSlotItem(AttendanceSlotType.masuk);
    final slot2Item =
        attendanceProv.getSlotItem(AttendanceSlotType.istirahatKeluar);
    final slot3Item =
        attendanceProv.getSlotItem(AttendanceSlotType.istirahatMasuk);
    final slot4Item = attendanceProv.getSlotItem(AttendanceSlotType.pulang);

    // Determine which slot is the current active session
    // Matching mockup default: Slot 1 is Completed, Slot 2 is Active CTA
    final slot1Completed = isSlot1Done;
    final slot2Active = slot1Completed && !isSlot2Done;
    final slot3Active = isSlot2Done && !isSlot3Done;
    final slot4Active = isSlot3Done && !isSlot4Done;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Presensi Hari Ini',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                '4 Sesi Absensi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // CARD 1: Absen Masuk
        if (slot1Completed)
          _buildCompletedCard(
            title: 'Absen Masuk',
            badgeText: 'TEPAT WAKTU',
            subtitle:
                'Check-in Pagi · ${slot1Item?.recordedTime != null ? DateTimeHelper.formatHHmm(slot1Item!.recordedTime!) : "08:15"} WIB',
            icon: Icons.login_rounded,
          )
        else
          _buildActiveCard(
            context: context,
            slotType: AttendanceSlotType.masuk,
            category: 'SESI PAGI',
            title: 'Absen Masuk',
            subtitle: 'Jadwal masuk: 08:00 WIB',
            buttonLabel: 'Ambil Absen Masuk',
            icon: Icons.login_rounded,
            authProv: authProv,
            attendanceProv: attendanceProv,
          ),
        const SizedBox(height: 12),

        // CARD 2: Absen Istirahat (Mockup Active CTA)
        if (isSlot2Done)
          _buildCompletedCard(
            title: 'Absen Istirahat',
            badgeText: 'SELESAI',
            subtitle:
                'Sesi Siang · ${DateTimeHelper.formatHHmm(slot2Item!.recordedTime!)} WIB',
            icon: Icons.restaurant_rounded,
          )
        else if (slot2Active || !slot1Completed)
          _buildActiveCard(
            context: context,
            slotType: AttendanceSlotType.istirahatKeluar,
            category: 'SESI SIANG',
            title: 'Absen Istirahat',
            subtitle: 'Jadwal baku: 12:00 – 13:00 WIB',
            buttonLabel: 'Ambil Absen Istirahat',
            icon: Icons.restaurant_rounded,
            authProv: authProv,
            attendanceProv: attendanceProv,
          )
        else
          _buildLockedCard(
            icon: Icons.restaurant_rounded,
            category: 'Sesi Siang · Belum Dimulai',
            title: 'Absen Istirahat',
            subtitle: 'Jadwal baku: 12:00 – 13:00 WIB',
            trailingIcon: Icons.lock_outline_rounded,
          ),
        const SizedBox(height: 12),

        // CARD 3: Absen Selesai Istirahat
        if (isSlot3Done)
          _buildCompletedCard(
            title: 'Absen Selesai Istirahat',
            badgeText: 'SELESAI',
            subtitle:
                'Selesai Istirahat · ${DateTimeHelper.formatHHmm(slot3Item!.recordedTime!)} WIB',
            icon: Icons.coffee_rounded,
          )
        else if (slot3Active)
          _buildActiveCard(
            context: context,
            slotType: AttendanceSlotType.istirahatMasuk,
            category: 'SESI SIANG',
            title: 'Absen Selesai Istirahat',
            subtitle: 'Batas istirahat berakhir: 13:00 WIB',
            buttonLabel: 'Ambil Selesai Istirahat',
            icon: Icons.coffee_rounded,
            authProv: authProv,
            attendanceProv: attendanceProv,
          )
        else
          _buildLockedCard(
            icon: Icons.coffee_rounded,
            category: 'Sesi Siang · Menunggu Istirahat',
            title: 'Absen Selesai Istirahat',
            subtitle: 'Tersedia setelah check-out istirahat',
            trailingIcon: Icons.lock_outline_rounded,
          ),
        const SizedBox(height: 12),

        // CARD 4: Absen Pulang
        if (isSlot4Done)
          _buildCompletedCard(
            title: 'Absen Pulang',
            badgeText: 'SELESAI',
            subtitle:
                'Check-out Sore · ${DateTimeHelper.formatHHmm(slot4Item!.recordedTime!)} WIB',
            icon: Icons.logout_rounded,
          )
        else if (slot4Active)
          _buildActiveCard(
            context: context,
            slotType: AttendanceSlotType.pulang,
            category: 'SESI SORE',
            title: 'Absen Pulang',
            subtitle: 'Batas jam kerja berakhir: 17:00 WIB',
            buttonLabel: 'Ambil Absen Pulang',
            icon: Icons.logout_rounded,
            authProv: authProv,
            attendanceProv: attendanceProv,
          )
        else
          _buildLockedCard(
            icon: Icons.logout_rounded,
            category: 'Sesi Sore · Belum Dimulai',
            title: 'Absen Pulang',
            subtitle: 'Batas jam kerja berakhir: 17:00 WIB',
            trailingIcon: Icons.lock_clock_outlined,
          ),
      ],
    );
  }

  // 1. Completed Card Design (Matches Button 1 in user HTML)
  Widget _buildCompletedCard({
    required String title,
    required String badgeText,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Icon Box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.tertiaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tertiaryContainer,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.tertiaryContainer,
            size: 22,
          ),
        ],
      ),
    );
  }

  // 2. Active Session Card Design (Matches Button 2 in user HTML)
  Widget _buildActiveCard({
    required BuildContext context,
    required AttendanceSlotType slotType,
    required String category,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required IconData icon,
    required AuthProvider authProv,
    required AttendanceProvider attendanceProv,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondaryContainer,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF316BF3).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Top-right "SESI AKTIF" ribbon tag
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'SESI AKTIF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Box
                      Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryFixed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(
                    height: 1,
                    color: AppColors.surfaceContainer,
                  ),
                  const SizedBox(height: 14),

                  // Bottom Action CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VerifikasiLokasiScreen(
                              slotType: slotType,
                              slotTitle: title,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryContainer,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            buttonLabel,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Locked / Upcoming Card Design (Matches Button 3 & 4 in user HTML)
  Widget _buildLockedCard({
    required IconData icon,
    required String category,
    required String title,
    required String subtitle,
    required IconData trailingIcon,
  }) {
    return Opacity(
      opacity: 0.72,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Gray Icon Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.outline,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                trailingIcon,
                color: AppColors.outline,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

