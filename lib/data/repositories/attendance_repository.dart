import '../../core/utils/date_time_helper.dart';
import '../models/attendance_model.dart';

abstract class AttendanceRepository {
  Future<DailyAttendanceRecord> getTodayAttendance(String userId, String userName);
  Future<DailyAttendanceRecord> recordSlot({
    required String userId,
    required String userName,
    String? userNip,
    required AttendanceSlotType slotType,
    String? location,
    String? notes,
    double? latitude,
    double? longitude,
    String? distanceHq,
  });
  Future<List<DailyAttendanceRecord>> getHistory(String userId);
  Future<List<DailyAttendanceRecord>> getAllTodayRecords();
}

class MockAttendanceRepository implements AttendanceRepository {
  // In-memory storage for prototype and demo
  final Map<String, DailyAttendanceRecord> _recordsByDateAndUser = {};

  String _getKey(String dateKey, String userId) => '${dateKey}_$userId';

  @override
  Future<DailyAttendanceRecord> getTodayAttendance(String userId, String userName) async {
    final todayKey = DateTimeHelper.formatDateKey(DateTime.now());
    final key = _getKey(todayKey, userId);

    if (!_recordsByDateAndUser.containsKey(key)) {
      _recordsByDateAndUser[key] = DailyAttendanceRecord(
        id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        userName: userName,
        dateKey: todayKey,
        slotMasuk: const AttendanceSlotItem(type: AttendanceSlotType.masuk),
        slotIstirahatKeluar:
            const AttendanceSlotItem(type: AttendanceSlotType.istirahatKeluar),
        slotIstirahatMasuk:
            const AttendanceSlotItem(type: AttendanceSlotType.istirahatMasuk),
        slotPulang: const AttendanceSlotItem(type: AttendanceSlotType.pulang),
      );
    }
    return _recordsByDateAndUser[key]!;
  }

  @override
  Future<DailyAttendanceRecord> recordSlot({
    required String userId,
    required String userName,
    String? userNip,
    required AttendanceSlotType slotType,
    String? location,
    String? notes,
    double? latitude,
    double? longitude,
    String? distanceHq,
  }) async {
    final todayKey = DateTimeHelper.formatDateKey(DateTime.now());
    final key = _getKey(todayKey, userId);
    final current = await getTodayAttendance(userId, userName);

    final slotItem = AttendanceSlotItem(
      type: slotType,
      recordedTime: DateTime.now(),
      location: location ?? 'Kantor Pusat PERUMDA Tirta Kepri (GPS Verified)',
      notes: notes,
    );

    DailyAttendanceRecord updated;
    switch (slotType) {
      case AttendanceSlotType.masuk:
        updated = current.copyWith(slotMasuk: slotItem);
        break;
      case AttendanceSlotType.istirahatKeluar:
        updated = current.copyWith(slotIstirahatKeluar: slotItem);
        break;
      case AttendanceSlotType.istirahatMasuk:
        updated = current.copyWith(slotIstirahatMasuk: slotItem);
        break;
      case AttendanceSlotType.pulang:
        updated = current.copyWith(slotPulang: slotItem);
        break;
    }

    _recordsByDateAndUser[key] = updated;
    return updated;
  }

  @override
  Future<List<DailyAttendanceRecord>> getHistory(String userId) async {
    return _recordsByDateAndUser.values
        .where((r) => r.userId == userId)
        .toList();
  }

  @override
  Future<List<DailyAttendanceRecord>> getAllTodayRecords() async {
    final todayKey = DateTimeHelper.formatDateKey(DateTime.now());
    return _recordsByDateAndUser.values
        .where((r) => r.dateKey == todayKey)
        .toList();
  }
}
