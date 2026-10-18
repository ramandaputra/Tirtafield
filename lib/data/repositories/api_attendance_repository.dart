import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_config.dart';
import '../../core/utils/date_time_helper.dart';
import '../models/attendance_model.dart';
import 'attendance_repository.dart';

class ApiAttendanceRepository implements AttendanceRepository {
  final MockAttendanceRepository _fallbackMock = MockAttendanceRepository();

  @override
  Future<DailyAttendanceRecord> getTodayAttendance(
    String userId,
    String userName,
  ) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.attendanceUrl}?action=today&user_id=$userId&user_name=${Uri.encodeComponent(userName)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          final dateKey = data['date'] as String? ??
              DateTimeHelper.formatDateKey(DateTime.now());
          final slotsMap = data['slots'] as Map<String, dynamic>? ?? {};

          return DailyAttendanceRecord(
            id: 'rec_${dateKey}_$userId',
            userId: userId,
            userName: userName,
            dateKey: dateKey,
            slotMasuk: _parseSlot(AttendanceSlotType.masuk, slotsMap['masuk']),
            slotIstirahatKeluar: _parseSlot(
              AttendanceSlotType.istirahatKeluar,
              slotsMap['istirahatKeluar'],
            ),
            slotIstirahatMasuk: _parseSlot(
              AttendanceSlotType.istirahatMasuk,
              slotsMap['istirahatMasuk'],
            ),
            slotPulang: _parseSlot(
              AttendanceSlotType.pulang,
              slotsMap['pulang'],
            ),
          );
        }
      }
    } catch (_) {
      // Fallback to in-memory mock if API/network has issues
    }

    return _fallbackMock.getTodayAttendance(userId, userName);
  }

  AttendanceSlotItem _parseSlot(
    AttendanceSlotType type,
    dynamic slotData,
  ) {
    if (slotData == null || slotData is! Map<String, dynamic>) {
      return AttendanceSlotItem(type: type);
    }

    DateTime? recordedTime;
    final timeStr = slotData['recorded_time'] as String?;
    if (timeStr != null && timeStr.isNotEmpty) {
      try {
        recordedTime = DateTime.parse(timeStr);
      } catch (_) {}
    }

    return AttendanceSlotItem(
      type: type,
      recordedTime: recordedTime,
      location: slotData['location'] as String?,
      notes: slotData['notes'] as String?,
    );
  }

  @override
  Future<DailyAttendanceRecord> recordSlot({
    required String userId,
    required String userName,
    required AttendanceSlotType slotType,
    String? location,
    String? notes,
    double? latitude,
    double? longitude,
    String? distanceHq,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.attendanceUrl}?action=record');
      final payload = {
        'user_id': userId,
        'user_name': userName,
        'slot_type': slotType.name,
        'location': location ?? 'Kantor Tirtafield Tanjung Pinang',
        'notes': notes ?? '',
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (distanceHq != null) 'jarak_hq': distanceHq,
      };

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return await getTodayAttendance(userId, userName);
      }
    } catch (_) {
      // Fallback to local mock record
    }

    return _fallbackMock.recordSlot(
      userId: userId,
      userName: userName,
      slotType: slotType,
      location: location,
      notes: notes,
      latitude: latitude,
      longitude: longitude,
      distanceHq: distanceHq,
    );
  }

  @override
  Future<List<DailyAttendanceRecord>> getHistory(String userId) async {
    try {
      final uri =
          Uri.parse('${ApiConfig.attendanceUrl}?action=history&user_id=$userId');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        // Successful response
      }
    } catch (_) {}

    return _fallbackMock.getHistory(userId);
  }

  @override
  Future<List<DailyAttendanceRecord>> getAllTodayRecords() async {
    return _fallbackMock.getAllTodayRecords();
  }
}
