import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_helper.dart';

enum ActivityCategory {
  geofencing,
  operationalSchedule,
  approval,
  employeeAccount,
  securityAuth,
  systemMaintenance,
}

enum ActivityLevel {
  info,
  success,
  warning,
  critical,
}

class ActivityLogItem {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String actorName;
  final String actorRole;
  final String actorNip;
  final ActivityCategory category;
  final ActivityLevel level;
  final String? ipAddress;
  final String? deviceInfo;
  final String? targetEntity;
  final Map<String, dynamic>? metadata;

  const ActivityLogItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.actorName,
    required this.actorRole,
    required this.actorNip,
    required this.category,
    this.level = ActivityLevel.info,
    this.ipAddress,
    this.deviceInfo,
    this.targetEntity,
    this.metadata,
  });

  String get categoryLabel {
    switch (category) {
      case ActivityCategory.geofencing:
        return 'Geofencing & Lokasi';
      case ActivityCategory.operationalSchedule:
        return 'Jam Operasional';
      case ActivityCategory.approval:
        return 'Persetujuan Absen';
      case ActivityCategory.employeeAccount:
        return 'Pegawai & Akun';
      case ActivityCategory.securityAuth:
        return 'Keamanan & Sesi';
      case ActivityCategory.systemMaintenance:
        return 'Pemeliharaan Sistem';
    }
  }

  Color get categoryColor {
    switch (category) {
      case ActivityCategory.geofencing:
        return AppColors.secondary;
      case ActivityCategory.operationalSchedule:
        return AppColors.checkIn;
      case ActivityCategory.approval:
        return const Color(0xFFD97706); // Amber warm
      case ActivityCategory.employeeAccount:
        return AppColors.primary;
      case ActivityCategory.securityAuth:
        return AppColors.roleStaffIT;
      case ActivityCategory.systemMaintenance:
        return const Color(0xFF475569); // Slate
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case ActivityCategory.geofencing:
        return Icons.radar_rounded;
      case ActivityCategory.operationalSchedule:
        return Icons.schedule_rounded;
      case ActivityCategory.approval:
        return Icons.assignment_turned_in_rounded;
      case ActivityCategory.employeeAccount:
        return Icons.manage_accounts_rounded;
      case ActivityCategory.securityAuth:
        return Icons.security_rounded;
      case ActivityCategory.systemMaintenance:
        return Icons.settings_system_daydream_rounded;
    }
  }

  String get levelLabel {
    switch (level) {
      case ActivityLevel.info:
        return 'Informasi';
      case ActivityLevel.success:
        return 'Sukses';
      case ActivityLevel.warning:
        return 'Peringatan';
      case ActivityLevel.critical:
        return 'Kritis';
    }
  }

  Color get levelColor {
    switch (level) {
      case ActivityLevel.info:
        return const Color(0xFF0284C7); // Sky blue
      case ActivityLevel.success:
        return AppColors.success;
      case ActivityLevel.warning:
        return AppColors.warning;
      case ActivityLevel.critical:
        return AppColors.error;
    }
  }

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second WIB';
  }

  String get formattedDate {
    return DateTimeHelper.formatIndonesianDate(timestamp);
  }

  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24 && now.day == timestamp.day) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays == 1 || (diff.inHours < 48 && now.day != timestamp.day)) {
      return 'Kemarin';
    } else {
      return '${diff.inDays} hari lalu';
    }
  }

  String get dateGroupKey {
    final now = DateTime.now();
    if (timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day) {
      return 'Hari Ini';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (timestamp.year == yesterday.year &&
        timestamp.month == yesterday.month &&
        timestamp.day == yesterday.day) {
      return 'Kemarin';
    }

    return formattedDate;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'actorName': actorName,
      'actorRole': actorRole,
      'actorNip': actorNip,
      'category': category.name,
      'level': level.name,
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
      'targetEntity': targetEntity,
      'metadata': metadata,
    };
  }

  factory ActivityLogItem.fromJson(Map<String, dynamic> json) {
    return ActivityLogItem(
      id: json['id'] as String? ?? 'act_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Aktivitas Sistem',
      description: json['description'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      actorName: json['actorName'] as String? ?? 'Sistem',
      actorRole: json['actorRole'] as String? ?? 'Superadmin IT',
      actorNip: json['actorNip'] as String? ?? '-',
      category: ActivityCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ActivityCategory.systemMaintenance,
      ),
      level: ActivityLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => ActivityLevel.info,
      ),
      ipAddress: json['ipAddress'] as String?,
      deviceInfo: json['deviceInfo'] as String?,
      targetEntity: json['targetEntity'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
