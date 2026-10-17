import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

enum AttendanceSlotType {
  masuk(1, AppStrings.absenMasuk, AppStrings.descAbsenMasuk, AppColors.checkIn, Icons.login_rounded),
  istirahatKeluar(2, AppStrings.absenIstirahatKeluar, AppStrings.descAbsenIstirahatKeluar, AppColors.breakOut, Icons.free_breakfast_outlined),
  istirahatMasuk(3, AppStrings.absenIstirahatMasuk, AppStrings.descAbsenIstirahatMasuk, AppColors.breakIn, Icons.work_outline_rounded),
  pulang(4, AppStrings.absenPulang, AppStrings.descAbsenPulang, AppColors.checkOut, Icons.logout_rounded);

  final int slotNumber;
  final String title;
  final String description;
  final Color color;
  final IconData icon;

  const AttendanceSlotType(
    this.slotNumber,
    this.title,
    this.description,
    this.color,
    this.icon,
  );
}

class AttendanceSlotItem {
  final AttendanceSlotType type;
  final DateTime? recordedTime;
  final String? location;
  final String? notes;

  const AttendanceSlotItem({
    required this.type,
    this.recordedTime,
    this.location,
    this.notes,
  });

  bool get isCompleted => recordedTime != null;

  AttendanceSlotItem copyWith({
    AttendanceSlotType? type,
    DateTime? recordedTime,
    String? location,
    String? notes,
  }) {
    return AttendanceSlotItem(
      type: type ?? this.type,
      recordedTime: recordedTime ?? this.recordedTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }
}

class DailyAttendanceRecord {
  final String id;
  final String userId;
  final String userName;
  final String dateKey; // YYYY-MM-DD
  final AttendanceSlotItem slotMasuk;
  final AttendanceSlotItem slotIstirahatKeluar;
  final AttendanceSlotItem slotIstirahatMasuk;
  final AttendanceSlotItem slotPulang;
  final String status; // 'Hadir', 'Terlambat', 'Izin', 'Alpha'

  const DailyAttendanceRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.dateKey,
    required this.slotMasuk,
    required this.slotIstirahatKeluar,
    required this.slotIstirahatMasuk,
    required this.slotPulang,
    this.status = 'Hadir',
  });

  List<AttendanceSlotItem> get allSlots => [
        slotMasuk,
        slotIstirahatKeluar,
        slotIstirahatMasuk,
        slotPulang,
      ];

  int get completedSlotsCount =>
      allSlots.where((slot) => slot.isCompleted).length;

  DailyAttendanceRecord copyWith({
    String? id,
    String? userId,
    String? userName,
    String? dateKey,
    AttendanceSlotItem? slotMasuk,
    AttendanceSlotItem? slotIstirahatKeluar,
    AttendanceSlotItem? slotIstirahatMasuk,
    AttendanceSlotItem? slotPulang,
    String? status,
  }) {
    return DailyAttendanceRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      dateKey: dateKey ?? this.dateKey,
      slotMasuk: slotMasuk ?? this.slotMasuk,
      slotIstirahatKeluar: slotIstirahatKeluar ?? this.slotIstirahatKeluar,
      slotIstirahatMasuk: slotIstirahatMasuk ?? this.slotIstirahatMasuk,
      slotPulang: slotPulang ?? this.slotPulang,
      status: status ?? this.status,
    );
  }

  factory DailyAttendanceRecord.empty({
    required String id,
    required String userId,
    required String userName,
    required String dateKey,
  }) {
    return DailyAttendanceRecord(
      id: id,
      userId: userId,
      userName: userName,
      dateKey: dateKey,
      slotMasuk: const AttendanceSlotItem(type: AttendanceSlotType.masuk),
      slotIstirahatKeluar:
          const AttendanceSlotItem(type: AttendanceSlotType.istirahatKeluar),
      slotIstirahatMasuk:
          const AttendanceSlotItem(type: AttendanceSlotType.istirahatMasuk),
      slotPulang: const AttendanceSlotItem(type: AttendanceSlotType.pulang),
    );
  }
}
