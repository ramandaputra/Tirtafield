# Tirtafield Presensi Mobile (Flutter / Dart)

Aplikasi mobile absensi karyawan berbasis Flutter dengan arsitektur bersih (*Clean & Modular Architecture*), mendukung sistem **Approval Berjenjang** dan **3 Tingkatan Role**.

---

## 👥 Pembagian 3 Role & Hak Akses

| Role | Kategori | Fitur & Wewenang Utama |
| :--- | :--- | :--- |
| **Karyawan** | `User` | • Tampilan jam digital real-time berformat `HH:MM:SS`<br>• **4x Tombol Presensi** (Masuk, Istirahat Keluar, Istirahat Masuk, Pulang)<br>• Mengajukan permohonan (*Cuti, Sakit, Lembur, Izin, Koreksi Absen*)<br>• Memantau status approval pengajuan (Pending / Approved / Rejected) |
| **Direktur** | `Admin` | • Dashboard metrik & analitik kehadiran seluruh karyawan<br>• **Fitur Approval**: Review permohonan cuti/izin/lembur karyawan<br>• Memberikan persetujuan (*Approve*) atau penolakan (*Reject*) beserta catatan direksi |
| **Staff IT** | `Superadmin` | • Manajemen pengguna & penetapan role (Karyawan, Direktur, Staff IT)<br>• Konfigurasi jadwal jam kerja & aturan 4 slot presensi<br>• Konfigurasi batas toleransi keterlambatan & geofencing radius kantor (GPS)<br>• Monitoring kesehatan sistem & audit log |

---

## ⏰ Tampilan Karyawan (Jam Real-Time & 4x Tombol Absen)

Sesuai permintaan kebutuhan:
1. **Jam Real-Time**: Widget `DigitalClockWidget` dengan format detik aktif `HH:MM:SS` (contoh: `08:30:15`) yang tersinkronisasi per detik.
2. **4x Tombol Presensi Terstruktur**:
   - 🟢 **Slot 1: Absen Masuk** *(Mulai jam kerja harian)*
   - 🟠 **Slot 2: Istirahat Keluar** *(Mulai jam istirahat siang)*
   - 🟣 **Slot 3: Istirahat Masuk** *(Selesai istirahat & kembali bekerja)*
   - 🔴 **Slot 4: Absen Pulang** *(Mengakhiri jam kerja)*
   - Setiap kartu/tombol menampilkan status dinamis: indikator slot, waktu presensi saat selesai, verifikasi lokasi kantor, serta modal dialog konfirmasi sebelum submit.

---

## 📁 Struktur Direktori Proyek

```text
tirtafield/
├── pubspec.yaml                       # Konfigurasi dependensi (provider, intl, dll.)
├── analysis_options.yaml              # Linting dan pedoman kode standar
├── README.md                          # Dokumentasi sistem & panduan
└── lib/
    ├── main.dart                      # Entry point aplikasi Flutter
    ├── app.dart                       # MultiProvider & inisialisasi MaterialApp
    ├── core/                          # Fondasi umum aplikasi
    │   ├── constants/
    │   │   ├── app_colors.dart        # Palet warna modern (navy, cyan, status badges)
    │   │   └── app_strings.dart       # Konstanta teks & label
    │   ├── theme/
    │   │   └── app_theme.dart         # Material 3 Theme kustom
    │   ├── utils/
    │   │   └── date_time_helper.dart  # Formatter tanggal & waktu HH:mm:ss
    │   └── widgets/
    │       ├── digital_clock.dart     # Widget jam real-time HH:MM:SS
    │       ├── role_badge.dart        # Badge identitas 3 role
    │       └── status_badge.dart      # Badge status approval
    ├── data/                          # Data layer & model
    │   ├── models/
    │   │   ├── user_model.dart        # Model pengguna & enum UserRole (3 role)
    │   │   ├── attendance_model.dart  # Model 4 slot presensi harian
    │   │   └── approval_model.dart    # Model permohonan approval & status
    │   ├── mock/
    │   │   └── mock_data.dart         # Data awal prototype (Karyawan, Direktur, IT)
    │   └── repositories/
    │       ├── attendance_repository.dart # Abstraksi & implementasi presensi
    │       └── approval_repository.dart   # Abstraksi & implementasi approval
    ├── state/                         # State Management (ChangeNotifier)
    │   ├── auth_provider.dart         # Status sesi & switch role demo
    │   ├── attendance_provider.dart   # State logika presensi 4 tombol
    │   └── approval_provider.dart     # State permohonan & review approval
    └── presentation/                  # Tampilan UI per Role
        ├── main_shell.dart            # Navigasi utama + demo switch role
        ├── user_karyawan/             # Tampilan Karyawan (User)
        │   ├── screens/
        │   │   ├── home_karyawan_screen.dart     # Jam HH:MM:SS + 4x tombol absen
        │   │   ├── request_approval_screen.dart  # Formulir pengajuan cuti/izin/lembur
        │   │   └── my_approval_status_screen.dart# Riwayat & status approval
        │   └── widgets/
        │       └── attendance_action_buttons.dart # Komponen 4 tombol presensi
        ├── admin_direktur/            # Tampilan Direktur (Admin)
        │   └── screens/
        │       ├── dashboard_direktur_screen.dart # Ringkasan hadir & pending approval
        │       └── approval_management_screen.dart# Panel Approve/Reject & filter status
        └── superadmin_it/             # Tampilan Staff IT (Superadmin)
            └── screens/
                ├── dashboard_it_screen.dart      # Panel kontrol server & parameter
                ├── user_management_screen.dart   # Tambah user & assign role
                └── system_settings_screen.dart   # Konfigurasi waktu 4 slot presensi
```

---

## 🚀 Cara Menjalankan & Menguji Aplikasi

1. **Jalankan Aplikasi:**
   ```bash
   flutter pub get
   flutter run
   ```

2. **Demo Role Switcher:**
   Di bagian bawah layar (*bottom bar*), terdapat kontrol **Demo Switch Role**:
   - Tekan **1. Karyawan** untuk melihat tampilan presensi dengan jam `HH:MM:SS` dan 4 tombol absen.
   - Tekan **2. Direktur** untuk melihat dashboard approval manajerial dan menyetujui pengajuan.
   - Tekan **3. Staff IT** untuk mengonfigurasi jam kerja 4 slot dan kelola akun karyawan.

3. **Penyelarasan Tampilan Utama:**
   Ketika Anda mengirimkan desain/mockup tampilan utama yang diinginkan nanti, kita dapat langsung menyematkannya pada `lib/presentation/user_karyawan/screens/home_karyawan_screen.dart` dan `attendance_action_buttons.dart` dengan mudah karena arsitekturnya sudah siap dan terisolasi dengan rapi.
"# Tirtafield" 
