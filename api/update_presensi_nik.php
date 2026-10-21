<?php
require_once __DIR__ . '/config.php';

try {
    // 1. Check if column 'nik' already exists
    $check = $pdo->query("SHOW COLUMNS FROM presensi LIKE 'nik'");
    if ($check->rowCount() == 0) {
        // Rename pgw_nup to nik
        $pdo->exec("ALTER TABLE presensi CHANGE COLUMN pgw_nup nik VARCHAR(45) NOT NULL");
        echo "Kolom pgw_nup berhasil diubah menjadi nik di tabel presensi.\n";
    } else {
        echo "Kolom nik sudah ada di tabel presensi.\n";
    }

    // 2. Add pgw_nup as alias/virtual column or regular column for backward compatibility
    $checkNup = $pdo->query("SHOW COLUMNS FROM presensi LIKE 'pgw_nup'");
    if ($checkNup->rowCount() == 0) {
        $pdo->exec("ALTER TABLE presensi ADD COLUMN pgw_nup VARCHAR(45) GENERATED ALWAYS AS (nik) VIRTUAL");
        echo "Kolom virtual pgw_nup berhasil ditambahkan untuk kompatibilitas.\n";
    }

    // 3. Update existing records in presensi where nik is 'PA003' or similar to match users table
    $stmtUsers = $pdo->query("SELECT id, nik, name FROM users");
    $users = $stmtUsers->fetchAll();
    echo "Users saat ini: " . json_encode($users) . "\n";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
