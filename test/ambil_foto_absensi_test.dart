import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tirtafield/data/models/attendance_model.dart';
import 'package:tirtafield/data/repositories/attendance_repository.dart';
import 'package:tirtafield/presentation/user_karyawan/screens/ambil_foto_absensi_screen.dart';
import 'package:tirtafield/state/attendance_provider.dart';
import 'package:tirtafield/state/auth_provider.dart';
import 'package:tirtafield/state/system_settings_provider.dart';

void main() {
  testWidgets(
      'AmbilFotoAbsensiScreen requires taking selfie first, then displays stamped result with timestamp, location, and HQ radius before submission',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final attendanceRepo = MockAttendanceRepository();
    final authProvider = AuthProvider();
    final attendanceProvider = AttendanceProvider(repository: attendanceRepo);
    final settingsProvider = SystemSettingsProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<AttendanceProvider>.value(
            value: attendanceProvider,
          ),
          ChangeNotifierProvider<SystemSettingsProvider>.value(
            value: settingsProvider,
          ),
        ],
        child: const MaterialApp(
          home: AmbilFotoAbsensiScreen(
            slotType: AttendanceSlotType.istirahatKeluar,
            slotTitle: 'Absen Istirahat',
            projectLocation: 'Area Proyek Sudirman Office Tower',
            distanceHq: '8.5 km',
            targetOfficeName: 'Kantor Pusat (HQ)',
            isWithinRadius: true,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // --- PHASE 1: CAMERA SHUTTER ACTIVE (BEFORE CAPTURING SELFIE) ---
    expect(find.text('Ambil Foto Selfie'), findsWidgets);
    expect(find.text('Kamera Depan'), findsOneWidget);
    expect(find.text('Langkah 1 dari 2: Ambil Foto Selfie untuk Memvalidasi Kehadiran'), findsOneWidget);
    // Peringatan atribut perusahaan sebelum foto (single clean banner)
    expect(find.text('Pastikan anda menggunakan atribut perusahaan'), findsOneWidget);
    // Send button must not be visible yet
    expect(find.text('Kirim & Simpan Presensi'), findsNothing);

    // Tap Camera Shutter Button to take the selfie
    final captureButton = find.byKey(const ValueKey('capture_selfie_button'));
    await tester.ensureVisible(captureButton);
    await tester.tap(captureButton);
    await tester.pump(const Duration(milliseconds: 500));

    // --- PHASE 2: CAPTURED RESULT (WATERMARK STAMP ON PHOTO) ---
    expect(find.text('Hasil Foto Selfie'), findsOneWidget);
    expect(find.text('Langkah 2 dari 2: Foto & Stempel Terverifikasi Siap Dikirim'), findsOneWidget);

    // Verify 3 Required Watermark Elements Directly on the Photo Stamp:
    // 1. Official Header & Timestamp with WIB
    expect(find.text('BUKTI PRESENSI RESMI KORPORAT'), findsOneWidget);
    expect(find.textContaining('WIB'), findsWidgets);
    // 2. Lokasi Lapangan
    expect(find.text('Area Proyek Sudirman Office Tower'), findsWidgets);
    // 3. Radius Jarak Lapangan dari Kantor Utama
    expect(find.text('8.5 km dari Kantor Pusat (HQ)'), findsOneWidget);
    expect(find.text('Dalam Radius (Valid)'), findsOneWidget);

    // Verify Bento & Action Buttons
    expect(find.text('Foto & Lokasi Terverifikasi'), findsOneWidget);
    expect(find.text('Siap Kirim'), findsOneWidget);
    expect(find.text('Kirim & Simpan Presensi'), findsOneWidget);
    expect(find.text('Ambil Ulang Foto'), findsOneWidget);
    expect(find.text('Pusat Bantuan'), findsOneWidget);

    // Test retake photo returns to camera mode
    final retakeButton = find.text('Ambil Ulang Foto');
    await tester.ensureVisible(retakeButton);
    await tester.tap(retakeButton);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Langkah 1 dari 2: Ambil Foto Selfie untuk Memvalidasi Kehadiran'), findsOneWidget);
    expect(find.text('Pastikan anda menggunakan atribut perusahaan'), findsOneWidget);

    // Take the photo again to finalize
    await tester.ensureVisible(captureButton);
    await tester.tap(captureButton);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Kirim & Simpan Presensi'), findsOneWidget);

    // Submit Attendance
    final submitFinder = find.text('Kirim & Simpan Presensi');
    await tester.ensureVisible(submitFinder);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(submitFinder);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Success Dialog appears
    expect(find.text('Presensi Berhasil Terkirim!'), findsOneWidget);
    expect(find.text('Kembali ke Beranda'), findsOneWidget);
  });
}
