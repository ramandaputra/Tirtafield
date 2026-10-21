import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/api_attendance_repository.dart';
import 'data/repositories/approval_repository.dart';
import 'presentation/auth/splash_screen.dart';
import 'state/activity_log_provider.dart';
import 'state/approval_provider.dart';
import 'state/attendance_provider.dart';
import 'state/auth_provider.dart';
import 'state/employee_management_provider.dart';
import 'state/realtime_monitoring_provider.dart';
import 'state/system_settings_provider.dart';

class TirtafieldApp extends StatelessWidget {
  const TirtafieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Live MySQL Database repository (with resilient offline mock fallback)
    final attendanceRepo = ApiAttendanceRepository();
    final approvalRepo = ApiApprovalRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(repository: attendanceRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ApprovalProvider(repository: approvalRepo),
        ),
        ChangeNotifierProvider(create: (_) => EmployeeManagementProvider()),
        ChangeNotifierProvider(create: (_) => SystemSettingsProvider()),
        ChangeNotifierProvider(create: (_) => RealtimeMonitoringProvider()),
        ChangeNotifierProvider(create: (_) => ActivityLogProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
