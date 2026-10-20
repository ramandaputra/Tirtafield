import 'package:flutter/foundation.dart';
import '../data/models/activity_log_model.dart';

class ActivityLogProvider extends ChangeNotifier {
  List<ActivityLogItem> _logs = [];
  bool _isLoading = false;
  String _searchQuery = '';
  ActivityCategory? _selectedCategory;
  ActivityLevel? _selectedLevel;

  List<ActivityLogItem> get logs => List.unmodifiable(_logs);
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  ActivityCategory? get selectedCategory => _selectedCategory;
  ActivityLevel? get selectedLevel => _selectedLevel;

  ActivityLogProvider() {
    _initSeedLogs();
  }

  void _initSeedLogs() {
    final now = DateTime.now();
    _logs = [
      ActivityLogItem(
        id: 'act_001',
        title: 'Penetapan Kantor Pusat sebagai Kantor Utama',
        description: 'Kantor Pusat Tirtafield Tanjung Pinang berhasil ditetapkan sebagai titik acuan kantor utama multi-site geofencing.',
        timestamp: now.subtract(const Duration(minutes: 12)),
        actorName: 'Superadmin Pusimpel',
        actorRole: 'Superadmin IT',
        actorNip: 'P242101',
        category: ActivityCategory.geofencing,
        level: ActivityLevel.success,
        ipAddress: '192.168.1.15',
        deviceInfo: 'Chrome 122.0 (Windows 11)',
        targetEntity: 'Kantor Pusat Tirtafield Tanjung Pinang',
        metadata: {
          'action': 'set_primary_office',
          'office_id': 'hq',
          'radius': '50 meter',
          'coordinates': '0.92031, 104.46069',
        },
      ),
      ActivityLogItem(
        id: 'act_002',
        title: 'Pembaruan Radius Geofencing Aktif',
        description: 'Radius toleransi validasi lokasi untuk seluruh presensi pegawai di Kantor Pusat disetel pada 50 meter.',
        timestamp: now.subtract(const Duration(minutes: 45)),
        actorName: 'Superadmin Pusimpel',
        actorRole: 'Superadmin IT',
        actorNip: 'P242101',
        category: ActivityCategory.geofencing,
        level: ActivityLevel.info,
        ipAddress: '192.168.1.15',
        deviceInfo: 'Chrome 122.0 (Windows 11)',
        targetEntity: 'Radius Geofence Presensi',
        metadata: {
          'previous_radius': '100m',
          'new_radius': '50m',
          'strict_mode': true,
        },
      ),
      ActivityLogItem(
        id: 'act_003',
        title: 'Persetujuan Koreksi Presensi Masuk Disetujui',
        description: 'Menyetujui pengajuan koreksi presensi masuk Budi Santoso dikarenakan perbaikan pipa darurat di sektor barat.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 20)),
        actorName: 'IR. H. ABDUL KHOLIK F, M.M.',
        actorRole: 'Direktur Utama',
        actorNip: 'D001',
        category: ActivityCategory.approval,
        level: ActivityLevel.success,
        ipAddress: '192.168.1.8',
        deviceInfo: 'Tirtafield Mobile (Android 14)',
        targetEntity: 'Permohonan Koreksi #APR-001 (Budi Santoso)',
        metadata: {
          'approval_id': 'apr_001',
          'applicant': 'Budi Santoso',
          'decision': 'APPROVED',
          'slot': '1. Masuk Pagi',
        },
      ),
      ActivityLogItem(
        id: 'act_004',
        title: 'Penambahan Titik Kantor Cabang Baru',
        description: 'Menambahkan titik lokasi kantor cabang baru "Unit Pelayanan Bintan Centre" dengan radius valid 50 meter.',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 10)),
        actorName: 'Superadmin Pusimpel',
        actorRole: 'Superadmin IT',
        actorNip: 'P242101',
        category: ActivityCategory.geofencing,
        level: ActivityLevel.success,
        ipAddress: '192.168.1.15',
        deviceInfo: 'Chrome 122.0 (Windows 11)',
        targetEntity: 'Unit Pelayanan Bintan Centre',
        metadata: {
          'office_id': 'bintan_center',
          'latitude': 0.93245,
          'longitude': 104.47890,
          'radius': '50m',
        },
      ),
      ActivityLogItem(
        id: 'act_005',
        title: 'Peringatan Percobaan Lokasi Palsu (Mock GPS)',
        description: 'Sistem keamanan geofencing memblokir indikasi injeksi koordinat lokasi tiruan (Mock GPS Provider) pada perangkat pegawai.',
        timestamp: now.subtract(const Duration(hours: 3, minutes: 5)),
        actorName: 'Sistem Keamanan Otomatis',
        actorRole: 'Sistem',
        actorNip: 'SYSTEM',
        category: ActivityCategory.securityAuth,
        level: ActivityLevel.warning,
        ipAddress: '10.20.14.88',
        deviceInfo: 'Xiaomi Redmi Note 11 (Android 13)',
        targetEntity: 'Deteksi Integritas GPS Mobile',
        metadata: {
          'reason': 'isFromMockProvider: true',
          'action_taken': 'Presensi diblokir, diminta verifikasi manual',
        },
      ),
      ActivityLogItem(
        id: 'act_006',
        title: 'Pembaruan Jadwal Toleransi Jam Operasional',
        description: 'Toleransi keterlambatan presensi masuk pagi disetel menjadi 15 menit sebelum status tercatat Terlambat.',
        timestamp: now.subtract(const Duration(hours: 4, minutes: 30)),
        actorName: 'Superadmin Pusimpel',
        actorRole: 'Superadmin IT',
        actorNip: 'P242101',
        category: ActivityCategory.operationalSchedule,
        level: ActivityLevel.info,
        ipAddress: '192.168.1.15',
        deviceInfo: 'Chrome 122.0 (Windows 11)',
        targetEntity: 'Slot Presensi Masuk (07:30 - 08:00 WIB)',
        metadata: {
          'start_time': '07:30',
          'end_time': '08:00',
          'tolerance_minutes': 15,
        },
      ),
      ActivityLogItem(
        id: 'act_007',
        title: 'Pembuatan Akun Pegawai Baru',
        description: 'Pendaftaran akun karyawan lapangan baru atas nama Ahmad Fauzi (NIP: P005) pada Unit Pelayanan Sei Pulai.',
        timestamp: now.subtract(const Duration(hours: 6)),
        actorName: 'Superadmin Pusimpel',
        actorRole: 'Superadmin IT',
        actorNip: 'P242101',
        category: ActivityCategory.employeeAccount,
        level: ActivityLevel.success,
        ipAddress: '192.168.1.15',
        deviceInfo: 'Chrome 122.0 (Windows 11)',
        targetEntity: 'Ahmad Fauzi (P005)',
        metadata: {
          'role': 'Karyawan',
          'department': 'Operasional Lapangan',
          'placement': 'Instalasi Pengolahan Air (IPA) Sei Pulai',
        },
      ),
      ActivityLogItem(
        id: 'act_008',
        title: 'Pencadangan Database Presensi Otomatis',
        description: 'Pencadangan rutin tabel presensi dan log audit koordinat GPS berhasil disimpan ke arsip server lokal.',
        timestamp: now.subtract(const Duration(hours: 8, minutes: 15)),
        actorName: 'Cron Job Backup',
        actorRole: 'Sistem',
        actorNip: 'SYSTEM',
        category: ActivityCategory.systemMaintenance,
        level: ActivityLevel.info,
        ipAddress: '127.0.0.1',
        deviceInfo: 'PHP Daemon / MySQL Dump',
        targetEntity: 'Database tirtafield (attendance_logs)',
        metadata: {
          'records_backed_up': 1420,
          'file_size': '4.8 MB',
          'status': 'SUCCESS',
        },
      ),
      ActivityLogItem(
        id: 'act_009',
        title: 'Autentikasi Sesi Login Superadmin IT',
        description: 'Sesi login berhasil diverifikasi melalui kredensial NIP P242101 dari jaringan lokal intranet kantor.',
        timestamp: now.subtract(const Duration(hours: 9, minutes: 40)),
        actorName: 'Superadmin Pusimpel',
        actorRole: 'Superadmin IT',
        actorNip: 'P242101',
        category: ActivityCategory.securityAuth,
        level: ActivityLevel.info,
        ipAddress: '192.168.1.15',
        deviceInfo: 'Chrome 122.0 (Windows 11)',
        targetEntity: 'Autentikasi Dashboard IT',
        metadata: {
          'auth_method': 'NIP & Password',
          'session_token': 'Bearer eyJhbGciOi...',
        },
      ),
      ActivityLogItem(
        id: 'act_010',
        title: 'Persetujuan Presensi Luar Radius Disetujui',
        description: 'Menyetujui izin presensi di luar radius geofence untuk Siti Aminah yang bertugas dinas verifikasi pelanggan.',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        actorName: 'IR. H. ABDUL KHOLIK F, M.M.',
        actorRole: 'Direktur Utama',
        actorNip: 'D001',
        category: ActivityCategory.approval,
        level: ActivityLevel.success,
        ipAddress: '192.168.1.8',
        deviceInfo: 'Tirtafield Mobile (Android 14)',
        targetEntity: 'Permohonan Luar Radius #APR-002 (Siti Aminah)',
        metadata: {
          'approval_id': 'apr_002',
          'type': 'Luar Radius',
          'distance': '8.5 km dari Kantor',
        },
      ),
      ActivityLogItem(
        id: 'act_011',
        title: 'Perubahan Hak Akses Peran Akun',
        description: 'Memperbarui hak akses user Fazli Idham Machzal menjadi Staff IT Administrator.',
        timestamp: now.subtract(const Duration(days: 1, hours: 5)),
        actorName: 'Superadmin Pusimpel',
        actorRole: 'Superadmin IT',
        actorNip: 'P242101',
        category: ActivityCategory.employeeAccount,
        level: ActivityLevel.info,
        ipAddress: '192.168.1.15',
        deviceInfo: 'Chrome 122.0 (Windows 11)',
        targetEntity: 'FAZLI IDHAM MACHZAL, A.Md (020131)',
        metadata: {
          'previous_role': 'Karyawan',
          'new_role': 'Staff IT',
        },
      ),
      ActivityLogItem(
        id: 'act_012',
        title: 'Aktivasi Mode Ketat (Strict Mode) Geofencing',
        description: 'Mengaktifkan aturan wajib: presensi pegawai akan ditolak secara otomatis jika koordinat GPS di luar toleransi radius.',
        timestamp: now.subtract(const Duration(days: 1, hours: 7)),
        actorName: 'Superadmin Pusimpel',
        actorRole: 'Superadmin IT',
        actorNip: 'P242101',
        category: ActivityCategory.geofencing,
        level: ActivityLevel.warning,
        ipAddress: '192.168.1.15',
        deviceInfo: 'Chrome 122.0 (Windows 11)',
        targetEntity: 'Kebijakan Presensi Tirtafield',
        metadata: {
          'strict_mode': true,
          'block_out_of_radius': true,
        },
      ),
      ActivityLogItem(
        id: 'act_013',
        title: 'Sinkronisasi Master Pegawai dengan Database Lokal',
        description: 'Sinkronisasi 163 data pegawai aktif berhasil divalidasi antara tabel pgw_nup dan state aplikasi.',
        timestamp: now.subtract(const Duration(days: 2, hours: 2)),
        actorName: 'Superadmin Pusimpel',
        actorRole: 'Superadmin IT',
        actorNip: 'P242101',
        category: ActivityCategory.systemMaintenance,
        level: ActivityLevel.success,
        ipAddress: '192.168.1.15',
        deviceInfo: 'Chrome 122.0 (Windows 11)',
        targetEntity: 'API Sync /api/employees.php',
        metadata: {
          'total_synced': 163,
          'new_records': 0,
        },
      ),
      ActivityLogItem(
        id: 'act_014',
        title: 'Penolakan Koreksi Presensi Lapangan',
        description: 'Menolak permohonan koreksi jam pulang pegawai Hendra karena tidak menyertakan bukti lampiran foto surat tugas.',
        timestamp: now.subtract(const Duration(days: 2, hours: 6)),
        actorName: 'IR. H. ABDUL KHOLIK F, M.M.',
        actorRole: 'Direktur Utama',
        actorNip: 'D001',
        category: ActivityCategory.approval,
        level: ActivityLevel.critical,
        ipAddress: '192.168.1.8',
        deviceInfo: 'Tirtafield Mobile (Android 14)',
        targetEntity: 'Permohonan Koreksi #APR-009 (Hendra Kusuma)',
        metadata: {
          'approval_id': 'apr_009',
          'reason': 'Bukti lampiran tidak lengkap',
        },
      ),
    ];
  }

  List<ActivityLogItem> get filteredLogs {
    return _logs.where((log) {
      if (_selectedCategory != null && log.category != _selectedCategory) {
        return false;
      }
      if (_selectedLevel != null && log.level != _selectedLevel) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchTitle = log.title.toLowerCase().contains(q);
        final matchDesc = log.description.toLowerCase().contains(q);
        final matchActor = log.actorName.toLowerCase().contains(q);
        final matchNip = log.actorNip.toLowerCase().contains(q);
        final matchTarget = log.targetEntity?.toLowerCase().contains(q) ?? false;
        final matchCategory = log.categoryLabel.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchActor && !matchNip && !matchTarget && !matchCategory) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get totalCount => _logs.length;

  int get todayCount {
    final now = DateTime.now();
    return _logs.where((l) =>
      l.timestamp.year == now.year &&
      l.timestamp.month == now.month &&
      l.timestamp.day == now.day
    ).length;
  }

  int get geofenceCount {
    return _logs.where((l) => l.category == ActivityCategory.geofencing).length;
  }

  int get securityCount {
    return _logs.where((l) => l.category == ActivityCategory.securityAuth).length;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(ActivityCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedLevel(ActivityLevel? level) {
    _selectedLevel = level;
    notifyListeners();
  }

  void logActivity(ActivityLogItem item) {
    _logs.insert(0, item);
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  Future<void> refreshLogs() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    _initSeedLogs();
    _isLoading = false;
    notifyListeners();
  }

  String exportToCsv() {
    final buffer = StringBuffer();
    buffer.writeln('ID,Waktu,Aktor,Role,NIP,Kategori,Tingkat,Judul,Deskripsi,Target,IP Address,Perangkat');
    for (final log in filteredLogs) {
      final line = [
        '"${log.id}"',
        '"${log.formattedDate} ${log.formattedTime}"',
        '"${log.actorName}"',
        '"${log.actorRole}"',
        '"${log.actorNip}"',
        '"${log.categoryLabel}"',
        '"${log.levelLabel}"',
        '"${log.title.replaceAll('"', '""')}"',
        '"${log.description.replaceAll('"', '""')}"',
        '"${(log.targetEntity ?? '-').replaceAll('"', '""')}"',
        '"${log.ipAddress ?? '-'}"',
        '"${log.deviceInfo ?? '-'}"',
      ].join(',');
      buffer.writeln(line);
    }
    return buffer.toString();
  }
}
