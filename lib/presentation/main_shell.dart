import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        // Admin Direktur has its own integrated bottom navigation and complete 11-module portal
        return const DashboardDirekturScreen();

      case UserRole.staffIT:
        // Superadmin IT has its own integrated bottom navigation and profile shell
        return const DashboardITScreen();
    }
  }
}
