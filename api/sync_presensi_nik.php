<?php
require_once __DIR__ . '/config.php';

// Sinkronkan data presensi dengan tabel users berdasarkan pgw_id / user_id atau pgw_nama
$stmt = $pdo->query("SELECT id, nik, name FROM users");
$users = $stmt->fetchAll();

foreach ($users as $u) {
    $stmtUp = $pdo->prepare("
        UPDATE presensi 
        SET nik = :nik, pgw_nama = :name 
        WHERE pgw_id = :uid OR pgw_nama = :name2
    ");
    $stmtUp->execute([
        'nik'   => $u['nik'],
        'name'  => $u['name'],
        'uid'   => $u['id'],
        'name2' => $u['name'],
    ]);
}

$stmtCheck = $pdo->query("SELECT id, pgw_id, nik, pgw_nup, pgw_nama FROM presensi");
echo json_encode($stmtCheck->fetchAll(PDO::FETCH_ASSOC), JSON_PRETTY_PRINT);
