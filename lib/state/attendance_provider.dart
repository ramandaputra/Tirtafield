import 'package:flutter/material.dart';
import '../data/models/attendance_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/attendance_repository.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _repository;
  DailyAttendanceRecord? _todayRecord;
  List<DailyAttendanceRecord> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  AttendanceProvider({required AttendanceRepository repository})
      : _repository = repository;

  DailyAttendanceRecord? get todayRecord => _todayRecord;
  List<DailyAttendanceRecord> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadTodayAttendance(UserModel user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _todayRecord = await _repository.getTodayAttendance(user.id, user.name);
    } catch (e) {
      _errorMessage = 'Gagal memuat data presensi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> performAttendance({
    required UserModel user,
    required AttendanceSlotType slotType,
    String? location,
    String? notes,
    double? latitude,
    double? longitude,
    String? distanceHq,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _todayRecord = await _repository.recordSlot(
        userId: user.id,
        userName: user.name,
        userNip: user.nip,
        slotType: slotType,
        location: location,
        notes: notes,
        latitude: latitude,
        longitude: longitude,
        distanceHq: distanceHq,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Gagal melakukan presensi: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory(String userId) async {
    try {
      _history = await _repository.getHistory(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memuat riwayat: $e';
      notifyListeners();
    }
  }

  bool isSlotCompleted(AttendanceSlotType slotType) {
    if (_todayRecord == null) return false;
    switch (slotType) {
      case AttendanceSlotType.masuk:
        return _todayRecord!.slotMasuk.isCompleted;
      case AttendanceSlotType.istirahatKeluar:
        return _todayRecord!.slotIstirahatKeluar.isCompleted;
      case AttendanceSlotType.istirahatMasuk:
        return _todayRecord!.slotIstirahatMasuk.isCompleted;
      case AttendanceSlotType.pulang:
        return _todayRecord!.slotPulang.isCompleted;
    }
  }

  AttendanceSlotItem? getSlotItem(AttendanceSlotType slotType) {
    if (_todayRecord == null) return null;
    switch (slotType) {
      case AttendanceSlotType.masuk:
        return _todayRecord!.slotMasuk;
      case AttendanceSlotType.istirahatKeluar:
        return _todayRecord!.slotIstirahatKeluar;
      case AttendanceSlotType.istirahatMasuk:
        return _todayRecord!.slotIstirahatMasuk;
      case AttendanceSlotType.pulang:
        return _todayRecord!.slotPulang;
    }
  }
}
