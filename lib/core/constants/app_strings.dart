class AppStrings {
  static const String appName = 'Tirtafield Presensi';
  static const String appTagline = 'Sistem Presensi & Persetujuan Karyawan';

  // Roles
  static const String roleKaryawan = 'Karyawan';
  static const String roleDirektur = 'Direktur';
  static const String roleStaffIT = 'Staff IT';

  // 4 Tombol Presensi
  static const String absenMasuk = 'Presensi Masuk';
  static const String absenIstirahatKeluar = 'Istirahat Keluar';
  static const String absenIstirahatMasuk = 'Istirahat Masuk';
  static const String absenPulang = 'Presensi Pulang';

  // Subtitles / Helper for 4 Buttons
  static const String descAbsenMasuk = 'Mulai jam kerja';
  static const String descAbsenIstirahatKeluar = 'Mulai istirahat';
  static const String descAbsenIstirahatMasuk = 'Selesai istirahat';
  static const String descAbsenPulang = 'Akhiri jam kerja';

  // Approval Status
  static const String statusPending = 'Menunggu';
  static const String statusApproved = 'Disetujui';
  static const String statusRejected = 'Ditolak';

  // Approval Types (Hanya terkait absensi)
  static const String typeKoreksi = 'Koreksi Presensi';
  static const String typeLuarRadius = 'Presensi Luar Radius';
}
