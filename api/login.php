<?php
require_once __DIR__ . '/config.php';

$input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

$nik = trim($input['nik'] ?? $input['nip'] ?? '');
$pin = trim($input['pin'] ?? $input['password'] ?? '');

if (empty($nik)) {
    sendResponse(false, null, 'NIP / NIK tidak boleh kosong.', 400);
}

// Cari employee berdasarkan pgw_nup, noktp, atau pgw_id
$stmt = $pdo->prepare("
    SELECT * FROM employee 
    WHERE pgw_nup = :nik1 OR noktp = :nik2 OR CAST(pgw_id AS CHAR) = :nik3 
    LIMIT 1
");
$stmt->execute([
    'nik1' => $nik,
    'nik2' => $nik,
    'nik3' => $nik,
]);
$emp = $stmt->fetch();

if (!$emp) {
    sendResponse(false, null, "Karyawan dengan NIP/NIK '$nik' tidak ditemukan di database.", 404);
}

// Verifikasi PIN / Password:
// Jika kolom pin di database ada isinya, bandingkan. Jika null/kosong, izinkan jika default demo PIN '123456' atau cocokkan password
$dbPin = trim((string)($emp['pin'] ?? ''));
$dbPass = trim((string)($emp['password'] ?? ''));

$pinMatches = false;
if (!empty($pin)) {
    if (!empty($dbPin) && $pin === $dbPin) {
        $pinMatches = true;
    } elseif (!empty($dbPass) && ($pin === $dbPass || md5($pin) === $dbPass)) {
        $pinMatches = true;
    } elseif ($pin === '123456') { // Fallback demo PIN untuk semua karyawan di db
        $pinMatches = true;
    }
} else {
    // Jika login tidak memerlukan PIN khusus
    $pinMatches = true;
}

if (!$pinMatches) {
    sendResponse(false, null, 'PIN yang Anda masukkan salah. (Default PIN demo: 123456)', 401);
}

// Tentukan role berdasarkan data karyawan
$namaUpper = strtoupper($emp['pgw_nama'] ?? '');
$occUpper = strtoupper($emp['occ_add_desc'] ?? '');
$nikUpper = strtoupper(trim((string)($emp['pgw_nup'] ?? '')));

$role = 'karyawan';
$position = 'Staff Lapangan';
$department = $emp['occ_add_desc'] ?: 'Operasional Lapangan';

if ($nikUpper === 'D001' || strpos($namaUpper, 'DIREKTUR') !== false || strpos($occUpper, 'DIREKTUR') !== false || (int)$emp['pgw_id'] === 4) {
    $role = 'direktur';
    $position = 'Direktur Utama';
    $department = 'Dewan Direksi';
} elseif ($nikUpper === 'P242101' || strpos($namaUpper, 'PUSIMPEL') !== false || strpos($namaUpper, 'SUPERADMIN') !== false || strpos($namaUpper, 'IT') !== false || strpos($occUpper, 'IT') !== false || (int)$emp['pgw_id'] === 6) {
    $role = 'staffIT';
    $position = ($nikUpper === 'P242101' || strpos($namaUpper, 'SUPERADMIN') !== false) ? 'Superadmin Pusimpel' : 'Staff IT';
    $department = 'PUSIMPEL IT & System';
}

$userData = [
    'id'         => (string)$emp['pgw_id'],
    'nip'        => (string)($emp['pgw_nup'] ?? ''), // Nomor Induk Karyawan diambil dari kolom pgw_nup
    'name'       => (string)$emp['pgw_nama'],
    'email'      => strtolower(str_replace(' ', '.', preg_replace('/[^a-zA-Z0-9 ]/', '', $emp['pgw_nama']))) . '@tirtafield.co.id',
    'pin'        => $dbPin ?: '123456',
    'role'       => $role,
    'department' => $department,
    'position'   => $position,
    'avatar_url' => !empty($emp['avatar_url']) ? $emp['avatar_url'] : 'https://lh3.googleusercontent.com/aida-public/AB6AXuBHnouN4NhcfWmjDbG_twFO6sebw3bZ18Eh5o0S5X77EHF5sjwqdJN1_ReCmIRAXuAloD9dPZQaPaz6HVgpuNpNvmO58tfZnPqD0S2Or68H_L0RpASTtBWA4c84ApGfNtIT2D9Dp8lVoCp0JDnad7J_CE3txa5AZ09a1vR9wuxu1NBIUFtj4kKAYnne-NzoAjd5q04Al1Cu_2jIhmMuPgiIkaTQw-LExIXsFQapZNGSTxquu43ZR8o'
];

sendResponse(true, $userData, 'Login berhasil.');
