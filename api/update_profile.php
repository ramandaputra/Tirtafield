<?php
require_once __DIR__ . '/config.php';

$input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

$userId = trim($input['id'] ?? '');
$nik = trim($input['nik'] ?? $input['nip'] ?? '');
$actorRole = trim($input['actor_role'] ?? '');
$isSuperadmin = !empty($input['is_superadmin']) || $actorRole === 'staffIT';

if (empty($userId) && empty($nik)) {
    sendResponse(false, null, 'ID Karyawan atau NIK diperlukan.', 400);
}

// Cari data user di tabel `users`
if (!empty($userId)) {
    $stmt = $pdo->prepare("SELECT * FROM users WHERE id = :id LIMIT 1");
    $stmt->execute(['id' => $userId]);
} else {
    $stmt = $pdo->prepare("SELECT * FROM users WHERE nik = :nik LIMIT 1");
    $stmt->execute(['nik' => $nik]);
}
$user = $stmt->fetch();

if (!$user) {
    sendResponse(false, null, 'Pengguna tidak ditemukan di database.', 404);
}

$updateFields = [];
$params = ['id' => $user['id']];

// 1. Foto Profil
if (isset($input['avatar_url'])) {
    $updateFields[] = "avatar_url = :avatar_url";
    $params['avatar_url'] = trim($input['avatar_url']);
}

// 2. PIN
if (isset($input['pin']) && !empty(trim($input['pin']))) {
    $newPin = trim($input['pin']);
    $updateFields[] = "pin = :pin, password = :pass";
    $params['pin'] = $newPin;
    $params['pass'] = $newPin;
}

// 3. Nomor Telepon
if (isset($input['phone'])) {
    $updateFields[] = "phone = :phone";
    $params['phone'] = trim($input['phone']);
}

// 4. Nama Lengkap, Divisi, Kantor Penempatan
if ($isSuperadmin) {
    if (isset($input['name']) && !empty(trim($input['name']))) {
        $updateFields[] = "name = :name";
        $params['name'] = trim($input['name']);
    }
    if (isset($input['department'])) {
        $updateFields[] = "department = :department";
        $params['department'] = trim($input['department']);
    }
    if (isset($input['position'])) {
        $updateFields[] = "position = :position";
        $params['position'] = trim($input['position']);
    }
    if (!empty($input['office_id'])) {
        $updateFields[] = "office_id = :office_id";
        $params['office_id'] = trim($input['office_id']);

        // Resolve office name
        $stmtOff = $pdo->prepare("SELECT nama_kantor FROM offices WHERE id = :oid LIMIT 1");
        $stmtOff->execute(['oid' => trim($input['office_id'])]);
        $off = $stmtOff->fetch();
        if ($off) {
            $updateFields[] = "office_name = :office_name";
            $params['office_name'] = $off['nama_kantor'];
        }
    } elseif (!empty($input['office_name'])) {
        $updateFields[] = "office_name = :office_name";
        $params['office_name'] = trim($input['office_name']);
    }
} else {
    // Non-superadmin edit restriction
    $attemptNameChange = isset($input['name']) && trim($input['name']) !== trim((string)$user['name']);
    $attemptDeptChange = isset($input['department']) && trim($input['department']) !== trim((string)$user['department']);
    
    if ($attemptNameChange || $attemptDeptChange) {
        sendResponse(false, null, 'Nama lengkap dan bidang penugasan hanya dapat diubah oleh Superadmin.', 403);
    }
}

if (!empty($updateFields)) {
    $sql = "UPDATE users SET " . implode(', ', $updateFields) . " WHERE id = :id";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
}

// Fetch data terbaru
$stmt = $pdo->prepare("
    SELECT u.*, o.nama_kantor AS resolved_office_name 
    FROM users u 
    LEFT JOIN offices o ON u.office_id = o.id 
    WHERE u.id = :id LIMIT 1
");
$stmt->execute(['id' => $user['id']]);
$updatedUser = $stmt->fetch();

$finalOfficeName = !empty($updatedUser['resolved_office_name']) 
    ? $updatedUser['resolved_office_name'] 
    : (!empty($updatedUser['office_name']) ? $updatedUser['office_name'] : 'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang');

sendResponse(true, [
    'id'          => (string)$updatedUser['id'],
    'nip'         => (string)$updatedUser['nik'],
    'name'        => (string)$updatedUser['name'],
    'department'  => (string)$updatedUser['department'],
    'position'    => (string)$updatedUser['position'],
    'office_id'   => (string)$updatedUser['office_id'],
    'office_name' => $finalOfficeName,
    'avatar_url'  => (string)($updatedUser['avatar_url'] ?? ''),
], 'Profil berhasil diperbarui.');
