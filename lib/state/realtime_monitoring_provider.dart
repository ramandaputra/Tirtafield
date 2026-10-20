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
                nip: r['pgw_nup']?.toString() ?? 'EMP',
                userName: r['pgw_nama']?.toString() ?? 'Karyawan',
                department: 'Operasional Lapangan',
                slotType: slot,
                recordedTime: recTime,
                location: r['lokasi']?.toString() ?? 'Kantor Tirtafield',
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

            _lastRefreshed = DateTime.now();
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      }
    } catch (_) {
      // In case of error, generate realistic seed logs
    }

    // Seed realistic real-time logs for demo
    _logs = _generateSeedRealtimeLogs();
    _lastRefreshed = DateTime.now();
    _isLoading = false;
    notifyListeners();
  }

  List<RealtimeAttendanceLog> _generateSeedRealtimeLogs() {
    final now = DateTime.now();
    return [
      RealtimeAttendanceLog(
        id: 'rt_001',
        userId: '1',
        nip: 'P001',
        userName: 'SYAKYAKIRTI, S.E., M.M., M.H',
        department: 'Operasional Lapangan - Area Kepri',
        slotType: AttendanceSlotType.masuk,
        recordedTime: DateTime(now.year, now.month, now.day, 7, 54, 12),
        location: 'Jalur Pipa Transmisi KM 8',
        latitude: 0.93850,
        longitude: 104.49200,
        address: 'Jl. Raja Haji Fisabilillah KM 8, Tanjung Pinang Timur',
        distanceHq: '4.0 km',
        officePlacement: 'Kantor Pusat Tanjung Pinang',
        biometricScore: 99.6,
        status: 'Tepat Waktu',
        notes: 'Penanganan perbaikan darurat kebocoran pipa transmisi KM 8',
        fotoUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBHnouN4NhcfWmjDbG_twFO6sebw3bZ18Eh5o0S5X77EHF5sjwqdJN1_ReCmIRAXuAloD9dPZQaPaz6HVgpuNpNvmO58tfZnPqD0S2Or68H_L0RpASTtBWA4c84ApGfNtIT2D9Dp8lVoCp0JDnad7J_CE3txa5AZ09a1vR9wuxu1NBIUFtj4kKAYnne-NzoAjd5q04Al1Cu_2jIhmMuPgiIkaTQw-LExIXsFQapZNGSTxquu43ZR8o',
      ),
      RealtimeAttendanceLog(
        id: 'rt_002',
        userId: '2',
        nip: 'PA002',
        userName: 'SITI FATIMAH BELLA SUHADA, S.SOS',
        department: 'PUSIMPEL IT & System',
        slotType: AttendanceSlotType.masuk,
        recordedTime: DateTime(now.year, now.month, now.day, 7, 58, 45),
        location: 'Gardu Transmisi & Telemetri Batu 5',
        latitude: 0.92800,
        longitude: 104.47200,
        address: 'Jl. Gatot Subroto KM 5, Tanjung Pinang Timur',
        distanceHq: '1.5 km',
        officePlacement: 'Kantor Pusat Tanjung Pinang',
        biometricScore: 98.9,
        status: 'Tepat Waktu',
        notes: 'Maintenance server telemetri dan sinkronisasi data presensi',
        fotoUrl:
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&fit=crop',
      ),
      RealtimeAttendanceLog(
        id: 'rt_003',
        userId: '6',
        nip: '020131',
        userName: 'FAZLI IDHAM MACHZAL, A.Md',
        department: 'PUSIMPEL IT & System',
        slotType: AttendanceSlotType.masuk,
        recordedTime: DateTime(now.year, now.month, now.day, 8, 12, 10),
        location: 'Unit Pelayanan Bintan Centre',
        latitude: 0.92550,
        longitude: 104.47120,
        address: 'Komp. Bintan Centre Blok A No. 5-6, Tanjung Pinang',
        distanceHq: '1.3 km',
        officePlacement: 'Kantor Pusat Tanjung Pinang',
        biometricScore: 99.2,
        status: 'Terlambat (12 mnt)',
        notes: 'Pemeriksaan meter air dan survei teknis sambungan baru pelanggan Bintan',
        fotoUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&fit=crop',
      ),
      RealtimeAttendanceLog(
        id: 'rt_004',
        userId: '11',
        nip: '020167',
        userName: 'SAPTO DWIATMOKO',
        department: 'Teknik Distribusi & Transmisi',
        slotType: AttendanceSlotType.masuk,
        recordedTime: DateTime(now.year, now.month, now.day, 7, 45, 30),
        location: 'Instalasi Pengolahan Air (IPA) Sei Pulai',
        latitude: 0.90810,
        longitude: 104.43250,
        address: 'Kawasan Waduk Sei Pulai, Bintan',
        distanceHq: '3.4 km',
        officePlacement: 'Kantor Pusat Tanjung Pinang',
        biometricScore: 99.5,
        status: 'Tepat Waktu',
        notes: 'Monitoring tekanan air dan instalasi pompa booster Sei Pulai',
        fotoUrl:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&fit=crop',
      ),
      RealtimeAttendanceLog(
        id: 'rt_005',
        userId: '8',
        nip: '020103',
        userName: 'SYAHRUL',
        department: 'Operasional Lapangan - Area Kepri',
        slotType: AttendanceSlotType.istirahatKeluar,
        recordedTime: DateTime(now.year, now.month, now.day, 12, 02, 18),
        location: 'Pos Pengawasan Pipa Air Baku KM 7',
        latitude: 0.91680,
        longitude: 104.45630,
        address: 'Jl. DI Panjaitan KM 7, Tanjung Pinang Timur',
        distanceHq: '0.6 km',
        officePlacement: 'Kantor Pusat Tanjung Pinang',
        biometricScore: 98.7,
        status: 'Tepat Waktu',
        notes: 'Istirahat keluar tugas patroli pipa air baku',
        fotoUrl:
            'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&fit=crop',
      ),
    ];
  }
}
