import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Header banner korporat untuk Dashboard Admin (Direktur) dan Superadmin (IT)
/// Menampilkan identitas PERUMDA Tirta Kepri dengan integrasi aset logo `assets/images/app.jpg`.
class DashboardHeaderBanner extends StatelessWidget {
  final String companyName;
  final String roleTitle;
  final IconData? roleBadgeIcon;
  final Color roleBadgeColor;
  final String? tagline;
  final VoidCallback? onTap;

  const DashboardHeaderBanner({
    super.key,
    this.companyName = 'Perusahaan Umum Daerah Air Minum Tirta Kepri',
    required this.roleTitle,
    this.roleBadgeIcon,
    this.roleBadgeColor = AppColors.secondary,
    this.tagline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00227A),
                Color(0xFF00144D),
                Color(0xFF070E28),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF001B6B).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // 1. Ambient Background Glow Effects
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF0088FF).withValues(alpha: 0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00E5FF).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Main Content Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Text Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: roleBadgeColor.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: roleBadgeColor.withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (roleBadgeIcon != null) ...[
                                  Icon(
                                    roleBadgeIcon,
                                    size: 11.5,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4.5),
                                ],
                                Flexible(
                                  child: Text(
                                    roleTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: Colors.white,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 7),

                          // Main Headline
                          Text(
                            companyName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                              height: 1.25,
                              fontFamily: 'Inter',
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Slogan / Sub-headline
                          const Text(
                            'Budaya Bersih & Melayani',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7DD3FC),
                              fontFamily: 'Inter',
                            ),
                          ),
                          if (tagline != null && tagline!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            // Status Row with Live indicator
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    tagline!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Logo Graphic Container (assets/images/app.jpg)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: const Color(0xFF0077FF).withValues(alpha: 0.25),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.5),
                        child: Image.asset(
                          'assets/images/app.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFF0A1E4A),
                              child: const Icon(
                                Icons.water_drop_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
