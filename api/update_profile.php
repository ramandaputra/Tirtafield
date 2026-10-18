<?php
require_once __DIR__ . '/config.php';

$input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

$userId = trim($input['id'] ?? $input['pgw_id'] ?? '');
$nik = trim($input['nik'] ?? $input['nip'] ?? '');
$actorRole = trim($input['actor_role'] ?? '');
$isSuperadmin = !empty($input['is_superadmin']) || $actorRole === 'staffIT';

if (empty($userId) && empty($nik)) {
    sendResponse(false, null, 'ID Karyawan atau NIK diperlukan.', 400);
}

// Cari data employee
if (!empty($userId)) {
    $stmt = $pdo->prepare("SELECT * FROM employee WHERE pgw_id = :id LIMIT 1");
    $stmt->execute(['id' => $userId]);
} else {
    $stmt = $pdo->prepare("SELECT * FROM employee WHERE pgw_nup = :nik LIMIT 1");
    $stmt->execute(['nik' => $nik]);
}
$emp = $stmt->fetch();

if (!$emp) {
    sendResponse(false, null, 'Karyawan tidak ditemukan di database.', 404);
}

$updateFields = [];
$params = ['id' => $emp['pgw_id']];

// 1. Foto Profil (Dapat diubah oleh Akun User sendiri maupun Superadmin)
if (isset($input['avatar_url'])) {
    $updateFields[] = "avatar_url = :avatar_url";
    $params['avatar_url'] = trim($input['avatar_url']);
}

// 2. Nama Lengkap dan Divisi Penempatan (HANYA DAPAT DIUBAH OLEH SUPERADMIN)
if ($isSuperadmin) {
    if (isset($input['name']) && !empty(trim($input['name']))) {
        $updateFields[] = "pgw_nama = :pgw_nama";
        $params['pgw_nama'] = trim($input['name']);
    }
    if (isset($input['department'])) {
        $updateFields[] = "occ_add_desc = :occ_add_desc";
        $params['occ_add_desc'] = trim($input['department']);
    }
    if (isset($input['pin']) && !empty(trim($input['pin']))) {
        $updateFields[] = "pin = :pin";
        $params['pin'] = (int)trim($input['pin']);
    }
} else {
    // Jika pengguna bukan superadmin mencoba merubah nama lengkap atau divisi
    $attemptNameChange = isset($input['name']) && trim($input['name']) !== trim((string)$emp['pgw_nama']);
    $attemptDeptChange = isset($input['department']) && trim($input['department']) !== trim((string)$emp['occ_add_desc']);
    
    if ($attemptNameChange || $attemptDeptChange) {
        sendResponse(false, null, 'Nama lengkap dan divisi penempatan hanya dapat diubah oleh Superadmin Pusimpel.', 403);
    }
}

if (!empty($updateFields)) {
    $sql = "UPDATE employee SET " . implode(', ', $updateFields) . " WHERE pgw_id = :id";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
}

// Fetch data terbaru
$stmt = $pdo->prepare("SELECT * FROM employee WHERE pgw_id = :id LIMIT 1");
$stmt->execute(['id' => $emp['pgw_id']]);
$updatedEmp = $stmt->fetch();

sendResponse(true, [
    'id'         => (string)$updatedEmp['pgw_id'],
    'nip'        => (string)($updatedEmp['pgw_nup'] ?? ''),
    'name'       => (string)$updatedEmp['pgw_nama'],
    'department' => (string)($updatedEmp['occ_add_desc'] ?? ''),
    'avatar_url' => (string)($updatedEmp['avatar_url'] ?? ''),
], 'Profil berhasil diperbarui.');
