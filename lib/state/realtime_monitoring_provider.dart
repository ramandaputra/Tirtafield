import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import '../data/models/attendance_model.dart';

class RealtimeAttendanceLog {
  final String id;
  final String userId;
  final String nip;
  final String userName;
  final String department;
  final AttendanceSlotType slotType;
  final DateTime recordedTime;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? distanceHq;
  final String? officePlacement;
  final String? fotoUrl;
  final double biometricScore;
  final String status; // Tepat Waktu / Terlambat
  final String notes;

  const RealtimeAttendanceLog({
    required this.id,
    required this.userId,
    required this.nip,
    required this.userName,
    required this.department,
    required this.slotType,
    required this.recordedTime,
    required this.location,
    this.latitude,
    this.longitude,
    this.address,
    this.distanceHq,
    this.officePlacement = 'Kantor Pusat Tanjung Pinang',
    this.fotoUrl,
    this.biometricScore = 99.4,
    this.status = 'Tepat Waktu',
    this.notes = '',
  });

  bool get isLate => status.toLowerCase().contains('terlambat');

  String get distancePlacementOffice {
    final dist = distanceHq ?? '4.2 km';
    final office = officePlacement ?? 'Kantor Pusat Tanjung Pinang';
    if (dist.toLowerCase().contains('kantor') || dist.toLowerCase().contains('dari')) {
      return dist;
    }
    return '$dist dari kantor penempatan ($office)';
  }
}

class RealtimeMonitoringProvider extends ChangeNotifier {
  List<RealtimeAttendanceLog> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;
  AttendanceSlotType? _filterSlot;
  String _searchQuery = '';
  DateTime _lastRefreshed = DateTime.now();

  RealtimeMonitoringProvider() {
    loadRealtimeAttendance();
  }

  List<RealtimeAttendanceLog> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AttendanceSlotType? get filterSlot => _filterSlot;
  String get searchQuery => _searchQuery;
  DateTime get lastRefreshed => _lastRefreshed;

  List<RealtimeAttendanceLog> get filteredLogs {
    return _logs.where((item) {
      final matchesQuery = _searchQuery.isEmpty ||
          item.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.nip.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.department.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesSlot = _filterSlot == null || item.slotType == _filterSlot;

      return matchesQuery && matchesSlot;
    }).toList();
  }

  // Summary Metrics
  int get countHadirTotal => _logs.map((e) => e.userId).toSet().length;
  int get countTepatWaktu => _logs.where((e) => !e.isLate && e.slotType == AttendanceSlotType.masuk).length;
  int get countTerlambat => _logs.where((e) => e.isLate && e.slotType == AttendanceSlotType.masuk).length;
  int get countIstirahat => _logs.where((e) => e.slotType == AttendanceSlotType.istirahatKeluar).length;
  int get countPulang => _logs.where((e) => e.slotType == AttendanceSlotType.pulang).length;

  void setFilterSlot(AttendanceSlotType? slot) {
    _filterSlot = slot;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadRealtimeAttendance() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.attendanceUrl}?action=all_today');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> list = body['data'];
          if (list.isNotEmpty) {
            _logs = list.map((r) {
              AttendanceSlotType slot = AttendanceSlotType.masuk;
              final st = (r['slot_type'] ?? '').toString();
              if (st == 'istirahatKeluar') slot = AttendanceSlotType.istirahatKeluar;
              if (st == 'istirahatMasuk') slot = AttendanceSlotType.istirahatMasuk;
              if (st == 'pulang') slot = AttendanceSlotType.pulang;

              DateTime recTime = DateTime.now();
              if (r['waktu'] != null) {
                recTime = DateTime.tryParse(r['waktu'].toString()) ?? DateTime.now();
              }

              return RealtimeAttendanceLog(
                id: r['id'].toString(),
                userId: r['pgw_id'].toString(),
                nip: r['nik']?.toString() ?? r['pgw_nup']?.toString() ?? 'EMP',
                userName: r['user_name']?.toString() ?? r['pgw_nama']?.toString() ?? 'Karyawan',
                department: r['user_department']?.toString() ?? 'Operasional Lapangan',
                slotType: slot,
                recordedTime: recTime,
                location: r['lokasi']?.toString() ?? 'Kantor PERUMDA Tirta Kepri',
                latitude: r['latitude'] != null ? (r['latitude'] as num).toDouble() : null,
                longitude: r['longitude'] != null ? (r['longitude'] as num).toDouble() : null,
                address: r['alamat']?.toString(),
                distanceHq: r['jarak_hq']?.toString() ?? '12 m dari HQ',
                fotoUrl: r['foto_url']?.toString(),
                biometricScore: r['biometric_score'] != null ? (r['biometric_score'] as num).toDouble() : 99.4,
                status: r['status']?.toString() ?? 'Tepat Waktu',
                notes: r['catatan']?.toString() ?? '',
              );
            }).toList();
          } else {
            _logs = [];
          }

          _lastRefreshed = DateTime.now();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
    } catch (_) {
      // Error handling
    }

    // Default kosong karena belum ada yang melakukan presensi
    _logs = [];
    _lastRefreshed = DateTime.now();
    _isLoading = false;
    notifyListeners();
  }

}
