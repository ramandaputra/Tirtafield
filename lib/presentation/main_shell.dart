import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../data/models/user_model.dart';
import '../state/auth_provider.dart';
import 'admin_direktur/screens/dashboard_direktur_screen.dart';
import 'superadmin_it/screens/dashboard_it_screen.dart';
import 'user_karyawan/screens/home_karyawan_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final currentRole = authProv.currentRole;

    switch (currentRole) {
      case UserRole.karyawan:
        // Karyawan home screen has its own bottom navigation bar matching the HTML mockup exactly
        return const HomeKaryawanScreen();

      case UserRole.direktur:
        return Scaffold(
          body: const DashboardDirekturScreen(),
          bottomNavigationBar: _buildAdminBottomSwitcher(context, authProv),
        );

      case UserRole.staffIT:
        return Scaffold(
          body: const DashboardITScreen(),
          bottomNavigationBar: _buildAdminBottomSwitcher(context, authProv),
        );
    }
  }

  Widget _buildAdminBottomSwitcher(BuildContext context, AuthProvider authProv) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Panel ${authProv.currentRole.displayName}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                authProv.switchUserByRole(UserRole.karyawan);
              },
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Ke Tampilan Karyawan'),
            ),
          ],
        ),
      ),
    );
  }
}
