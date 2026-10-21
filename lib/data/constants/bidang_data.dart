import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_config.dart';

class BidangData {
  /// Struktur Resmi Bidang & Seksi Bidang PDAM Tirtafield
  /// Sesuai hierarki database phpMyAdmin (ref_bidang & ref_seksi_bidang)
  static final Map<String, List<String>> _bidangToSeksi = {
    'Dewan Direksi': [
      'Direktur',
    ],
    'Bidang Hubungan Langganan': [
      'Seksi Pembacaan Meter',
      'Seksi Perawatan Meter',
    ],
    'Bidang Teknik': [
      'Seksi Perencanaan',
      'Seksi Distribusi',
      'Seksi Survei & Verifikasi Teknis',
    ],
    'Satuan Pengendalian Kehilangan Air': [
      'Bidang Kehilangan Air',
      'Bidang Analisa Jaringan & GIS',
    ],
    'PUSIMPEL IT & System': [
      'Superadmin Pusimpel',
      'Staff IT & Jaringan',
    ],
  };

  /// Daftar semua nama Bidang (Dewan Direksi di urutan pertama)
  static List<String> get allBidang => _bidangToSeksi.keys.toList();

  /// Bidang Utama Operasional sesuai hierarki
  static List<String> get mainOperationalBidang => [
        'Dewan Direksi',
        'Bidang Hubungan Langganan',
        'Bidang Teknik',
        'Satuan Pengendalian Kehilangan Air',
      ];

  /// Mendapatkan daftar Seksi Bidang berdasarkan nama Bidang
  static List<String> getSeksiForBidang(String? bidang) {
    if (bidang == null || bidang.isEmpty) {
      return _bidangToSeksi['Bidang Hubungan Langganan']!;
    }
    final normalized = normalizeBidang(bidang);
    return _bidangToSeksi[normalized] ?? _bidangToSeksi['Bidang Hubungan Langganan']!;
  }

  /// Normalisasi nama departemen lama agar selalu cocok dengan salah satu Bidang
  static String normalizeBidang(String? dept) {
    if (dept == null || dept.isEmpty) return 'Bidang Hubungan Langganan';
    if (_bidangToSeksi.containsKey(dept)) return dept;

    final lower = dept.toLowerCase();
    if (lower.contains('langganan') ||
        lower.contains('meter') ||
        lower.contains('pelayanan') ||
        lower.contains('hubungan')) {
      return 'Bidang Hubungan Langganan';
    }
    if (lower.contains('teknik') ||
        lower.contains('distribusi') ||
        lower.contains('perencanaan') ||
        lower.contains('lapangan') ||
        lower.contains('ipa') ||
        lower.contains('pengolahan')) {
      return 'Bidang Teknik';
    }
    if (lower.contains('kehilangan') ||
        lower.contains('air') ||
        lower.contains('spka') ||
        lower.contains('gis') ||
        lower.contains('jaringan')) {
      return 'Satuan Pengendalian Kehilangan Air';
    }
    if (lower.contains('pusimpel') ||
        lower.contains('it') ||
        lower.contains('system') ||
        lower.contains('admin')) {
      return 'PUSIMPEL IT & System';
    }
    if (lower.contains('direksi') || lower.contains('direktur')) {
      return 'Dewan Direksi';
    }
    return 'Bidang Hubungan Langganan';
  }

  /// Normalisasi nama seksi bidang lama agar valid di dalam Bidang terpilih
  static String normalizeSeksi(String? bidang, String? seksi) {
    final available = getSeksiForBidang(bidang);
    if (seksi == null || seksi.isEmpty) {
      return available.isNotEmpty ? available.first : 'Seksi Pembacaan Meter';
    }
    if (available.contains(seksi)) {
      return seksi;
    }
    // Cari yang mirip atau kembalikan default pertama
    final lower = seksi.toLowerCase();
    for (final s in available) {
      if (s.toLowerCase().contains(lower) || lower.contains(s.toLowerCase())) {
        return s;
      }
    }
    return available.isNotEmpty ? available.first : 'Seksi Pembacaan Meter';
  }

  /// Memuat data Bidang & Seksi dari phpMyAdmin (Laragon Backend API)
  static Future<void> syncFromDatabase() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/bidang.php');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          final list = body['data'] as List;
          for (final item in list) {
            final nama = item['nama']?.toString();
            final seksiList = item['seksi'];
            if (nama != null && seksiList is List) {
              final List<String> parsedSeksi = [];
              for (final s in seksiList) {
                if (s is Map && s['nama'] != null) {
                  parsedSeksi.add(s['nama'].toString());
                } else if (s is String) {
                  parsedSeksi.add(s);
                }
              }
              if (parsedSeksi.isNotEmpty) {
                _bidangToSeksi[nama] = parsedSeksi;
              }
            }
          }
        }
      }
    } catch (_) {
      // Offline fallback: tetap menggunakan _bidangToSeksi lokal
    }
  }
}
