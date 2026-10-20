import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../state/auth_provider.dart';

class CorporateHeroClock extends StatefulWidget {
  final String? department;
  final String? shift;

  const CorporateHeroClock({
    super.key,
    this.department,
    this.shift,
  });

  @override
  State<CorporateHeroClock> createState() => _CorporateHeroClockState();
}

class _CorporateHeroClockState extends State<CorporateHeroClock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getTimeGreeting(int hour) {
    if (hour >= 4 && hour < 11) {
      return 'Selamat Pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  String _formatDisplayName(String fullName) {
    if (fullName.isEmpty) return 'Karyawan';
    // Ambil sebelum koma jika ada gelar akademik (S.E., M.M., dll)
    String clean = fullName.split(',').first.trim();
    // Hilangkan prefix gelar depan (Ir., H., Dr., dll)
    clean = clean
        .replaceAll(
          RegExp(r'^(IR\.|H\.|DR\.|DRS\.|PROF\.)\s*', caseSensitive: false),
          '',
        )
        .trim();
    clean = clean
        .replaceAll(
          RegExp(r'^(H\.|HJ\.)\s*', caseSensitive: false),
          '',
        )
        .trim();

    // Format Title Case jika nama ditulis UPPERCASE
    if (clean == clean.toUpperCase()) {
      clean = clean.split(' ').map((word) {
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final user = authProv.currentUser;

    final hours = _now.hour.toString().padLeft(2, '0');
    final minutes = _now.minute.toString().padLeft(2, '0');
    final seconds = _now.second.toString().padLeft(2, '0');
    final timeStr = '$hours:$minutes:$seconds';

    final greeting = _getTimeGreeting(_now.hour);
    final displayName = _formatDisplayName(user.name);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle ambient light blob
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryContainer.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Greeting centered (tanpa icon pagi, siang, malam & tanpa status sedang bekerja)
                  Text(
                    '$greeting, $displayName',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Jam digital centrify
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: -0.5,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'WIB',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Tanggal di bawah jam (centrify)
                  Text(
                    DateTimeHelper.formatIndonesianDate(_now),
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (user.officeName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.apartment_rounded,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Penempatan: ${user.officeName}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                                fontFamily: 'Inter',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
