<?php
require_once __DIR__ . '/config.php';

try {
    // 1. Buat Tabel offices
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `offices` (
            `id` VARCHAR(50) NOT NULL PRIMARY KEY,
            `nama_kantor` VARCHAR(150) NOT NULL,
            `alamat` VARCHAR(255) NOT NULL,
            `latitude` DECIMAL(11, 8) NOT NULL,
            `longitude` DECIMAL(11, 8) NOT NULL,
            `radius` INT NOT NULL DEFAULT 100,
            `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
            `is_active` TINYINT(1) NOT NULL DEFAULT 1,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");

    // Seed data kantor jika kosong
    $countOffices = $pdo->query("SELECT COUNT(*) FROM offices")->fetchColumn();
    if ($countOffices == 0) {
        $insertOffice = $pdo->prepare("
            INSERT INTO offices (id, nama_kantor, alamat, latitude, longitude, radius, is_primary, is_active)
            VALUES (:id, :nama, :alamat, :lat, :lng, :radius, :is_primary, 1)
        ");

        $initialOffices = [
            [
                'id' => 'hq',
                'nama' => 'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang',
                'alamat' => 'Jl. M.T Haryono, Km.3, Tanjungpinang, Kepulauan Riau',
                'lat' => 0.92031000,
                'lng' => 104.46069000,
                'radius' => 200,
                'is_primary' => 1
            ],
            [
                'id' => 'bintan_center',
                'nama' => 'Unit Pelayanan Bintan Centre',
                'alamat' => 'Komp. Bintan Centre Blok A No. 5-6, Tanjung Pinang',
                'lat' => 0.92550000,
                'lng' => 104.47120000,
                'radius' => 60,
                'is_primary' => 0
            ],
            [
                'id' => 'ipa_sei_pulai',
                'nama' => 'Instalasi Pengolahan Air (IPA) Sei Pulai',
                'alamat' => 'Kawasan Waduk Sei Pulai, Bintan',
                'lat' => 0.90810000,
                'lng' => 104.43250000,
                'radius' => 100,
                'is_primary' => 0
            ],
            [
                'id' => 'ipa_sei_gesek',
                'nama' => 'IPA SEI GESEK',
                'alamat' => 'Kawasan Waduk Gesek, Bintan',
                'lat' => 0.97378400,
                'lng' => 104.55858000,
                'radius' => 100,
                'is_primary' => 0
            ]
        ];

        foreach ($initialOffices as $o) {
            $insertOffice->execute($o);
        }
        echo "Tabel 'offices' berhasil dibuat & di-seed dengan " . count($initialOffices) . " kantor.\n";
    } else {
        echo "Tabel 'offices' sudah ada (" . $countOffices . " kantor).\n";
    }

    // 2. Buat Tabel users
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `users` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `nik` VARCHAR(50) NOT NULL UNIQUE,
            `name` VARCHAR(150) NOT NULL,
            `email` VARCHAR(150) NULL,
            `pin` VARCHAR(20) NOT NULL DEFAULT '123456',
            `password` VARCHAR(255) NOT NULL DEFAULT '123456',
            `role` ENUM('karyawan', 'direktur', 'staffIT') NOT NULL DEFAULT 'karyawan',
            `department` VARCHAR(100) NOT NULL DEFAULT 'Bidang Hubungan Langganan',
            `position` VARCHAR(100) NOT NULL DEFAULT 'Seksi Pembacaan Meter',
            `phone` VARCHAR(30) NULL DEFAULT '081234567890',
            `office_id` VARCHAR(50) NOT NULL DEFAULT 'hq',
            `office_name` VARCHAR(150) NOT NULL DEFAULT 'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang',
            `avatar_url` TEXT NULL,
            `status_pegawai` VARCHAR(50) NOT NULL DEFAULT 'Karyawan Tetap',
            `is_active` TINYINT(1) NOT NULL DEFAULT 1,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX `idx_users_nik` (`nik`),
            INDEX `idx_users_role` (`role`),
            INDEX `idx_users_office` (`office_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");

    // Kosongkan users lama jika ada dan buat persis sesuai permintaan:
    // Pusimpel sebagai superadmin, IR. H. ABDUL KHOLIK F, M.M. sebagai admin
    $pdo->exec("TRUNCATE TABLE `users`");

    $insertUser = $pdo->prepare("
        INSERT INTO users (nik, name, email, pin, password, role, department, position, phone, office_id, office_name, is_active)
        VALUES (:nik, :name, :email, :pin, :pass, :role, :dept, :pos, :phone, :office_id, :office_name, 1)
    ");

    // User 1: Superadmin Pusimpel
    $insertUser->execute([
        'nik'         => 'P242101',
        'name'        => 'Pusimpel',
        'email'       => 'pusimpel@tirtakepri.co.id',
        'pin'         => '123456',
        'pass'        => '123456',
        'role'        => 'staffIT',
        'dept'        => 'PUSIMPEL IT & System',
        'pos'         => 'Superadmin Pusimpel',
        'phone'       => '081234567890',
        'office_id'   => 'hq',
        'office_name' => 'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang',
    ]);

    // User 2: Admin IR. H. ABDUL KHOLIK F, M.M.
    $insertUser->execute([
        'nik'         => 'D001',
        'name'        => 'IR. H. ABDUL KHOLIK F, M.M.',
        'email'       => 'abdul.kholik@tirtakepri.co.id',
        'pin'         => '123456',
        'pass'        => '123456',
        'role'        => 'direktur',
        'dept'        => 'Dewan Direksi',
        'pos'         => 'Direktur',
        'phone'       => '081234567890',
        'office_id'   => 'hq',
        'office_name' => 'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang',
    ]);

    echo "Tabel 'users' berhasil dibuat dan di-seed dengan Superadmin (Pusimpel) dan Admin (IR. H. ABDUL KHOLIK F, M.M.).\n";

} catch (\Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
