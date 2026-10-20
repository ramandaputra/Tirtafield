<?php
require_once __DIR__ . '/config.php';

$action = $_GET['action'] ?? $_POST['action'] ?? 'list';

if ($action === 'list') {
    $q = trim($_GET['q'] ?? '');
    $roleFilter = trim($_GET['role'] ?? '');
    $deptFilter = trim($_GET['department'] ?? '');

    $sql = "SELECT pgw_id, pgw_nup, pgw_nama, occ_add_desc, pin, pgw_nohp, pgw_alamat, avatar_url, ishapus, office_id, office_name FROM employee WHERE (ishapus = 0 OR ishapus IS NULL)";
    $params = [];

    if (!empty($q)) {
        $sql .= " AND (pgw_nama LIKE :q1 OR pgw_nup LIKE :q2 OR occ_add_desc LIKE :q3)";
        $params['q1'] = "%$q%";
        $params['q2'] = "%$q%";
        $params['q3'] = "%$q%";
    }

    if (!empty($deptFilter)) {
        $sql .= " AND occ_add_desc = :dept";
        $params['dept'] = $deptFilter;
    }

    $sql .= " ORDER BY pgw_id ASC LIMIT 100";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll();

    $employees = [];
    foreach ($rows as $emp) {
        $nikUpper = strtoupper(trim((string)($emp['pgw_nup'] ?? '')));
        $namaUpper = strtoupper($emp['pgw_nama'] ?? '');
        $occUpper = strtoupper($emp['occ_add_desc'] ?? '');

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

        if (!empty($roleFilter) && $role !== $roleFilter) {
            continue;
        }

        if (!empty($emp['office_id'])) {
            $officeId = $emp['office_id'];
            $officeName = !empty($emp['office_name']) ? $emp['office_name'] : 'Kantor Pusat Tirtafield Tanjung Pinang';
        } elseif ($nikUpper === 'P001' || (int)$emp['pgw_id'] === 1 || strpos($namaUpper, 'SYAKYAKIRTI') !== false) {
            $officeId = 'ipa_sei_pulai';
            $officeName = 'Instalasi Pengolahan Air (IPA) Sei Pulai';
        } elseif ($nikUpper === '020131' || (int)$emp['pgw_id'] === 6 || strpos($occUpper, 'BINTAN') !== false) {
            $officeId = 'bintan_center';
            $officeName = 'Unit Pelayanan Bintan Centre';
        } else {
            $officeId = 'hq';
            $officeName = 'Kantor Pusat Tirtafield Tanjung Pinang';
        }

        $empPin = trim((string)($emp['pin'] ?? ''));
        $activePin = !empty($empPin) && strlen($empPin) >= 4 ? $empPin : '123456';

        $employees[] = [
            'id'          => (string)$emp['pgw_id'],
            'nip'         => (string)($emp['pgw_nup'] ?? ''),
            'name'        => (string)$emp['pgw_nama'],
            'email'       => strtolower(str_replace(' ', '.', preg_replace('/[^a-zA-Z0-9 ]/', '', $emp['pgw_nama']))) . '@tirtafield.co.id',
            'pin'         => $activePin,
            'phone'       => (string)($emp['pgw_nohp'] ?? '081234567890'),
            'role'        => $role,
            'department'  => $department,
            'position'    => $position,
            'status'      => 'Karyawan Tetap',
            'office_id'   => $officeId,
            'office_name' => $officeName,
            'avatar_url'  => !empty($emp['avatar_url']) ? $emp['avatar_url'] : null,
        ];
    }

    sendResponse(true, $employees, 'Daftar data pegawai berhasil dimuat.');

} elseif ($action === 'add') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

    $nip        = trim($input['nip'] ?? $input['nik'] ?? '');
    $name       = trim($input['name'] ?? '');
    $department = trim($input['department'] ?? 'Operasional Lapangan');
    $position   = trim($input['position'] ?? 'Staff Lapangan');
    $phone      = trim($input['phone'] ?? '');
    $pin        = trim($input['pin'] ?? '123456');
    $role       = trim($input['role'] ?? 'karyawan');
    $officeId   = trim($input['office_id'] ?? $input['officeId'] ?? 'hq');
    $officeName = trim($input['office_name'] ?? $input['officeName'] ?? 'Kantor Pusat Tirtafield Tanjung Pinang');

    if (empty($nip) || empty($name)) {
        sendResponse(false, null, 'NIP/NIK dan Nama Pegawai wajib diisi.', 400);
    }

    // Cek duplikasi NIP
    $checkStmt = $pdo->prepare("SELECT pgw_id FROM employee WHERE pgw_nup = :nip LIMIT 1");
    $checkStmt->execute(['nip' => $nip]);
    if ($checkStmt->fetch()) {
        sendResponse(false, null, "Pegawai dengan NIP '$nip' sudah terdaftar.", 400);
    }

    $stmt = $pdo->prepare("
        INSERT INTO employee (
            pgw_nup, pgw_nama, occ_add_desc, pgw_nohp, pin, password, office_id, office_name, ishapus
        ) VALUES (
            :nip, :name, :dept, :phone, :pin, :pass, :office_id, :office_name, 0
        )
    ");
    $stmt->execute([
        'nip'         => $nip,
        'name'        => $name,
        'dept'        => $department,
        'phone'       => $phone,
        'pin'         => (int)$pin,
        'pass'        => $pin,
        'office_id'   => $officeId,
        'office_name' => $officeName,
    ]);

    $newId = $pdo->lastInsertId();

    sendResponse(true, [
        'id'          => (string)$newId,
        'nip'         => $nip,
        'name'        => $name,
        'department'  => $department,
        'position'    => $position,
        'role'        => $role,
        'pin'         => $pin,
        'office_id'   => $officeId,
        'office_name' => $officeName,
    ], 'Pegawai baru berhasil ditambahkan.');

} elseif ($action === 'update') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

    $id         = trim($input['id'] ?? '');
    $nip        = trim($input['nip'] ?? $input['nik'] ?? '');
    $name       = trim($input['name'] ?? '');
    $department = trim($input['department'] ?? '');
    $phone      = trim($input['phone'] ?? '');
    $pin        = trim($input['pin'] ?? '');
    $officeId   = trim($input['office_id'] ?? $input['officeId'] ?? '');
    $officeName = trim($input['office_name'] ?? $input['officeName'] ?? '');

    if (empty($id)) {
        sendResponse(false, null, 'ID Pegawai diperlukan.', 400);
    }

    $updateCols = [];
    $params = ['id' => $id];

    if (!empty($nip)) {
        $updateCols[] = "pgw_nup = :nip";
        $params['nip'] = $nip;
    }
    if (!empty($name)) {
        $updateCols[] = "pgw_nama = :name";
        $params['name'] = $name;
    }
    if (!empty($department)) {
        $updateCols[] = "occ_add_desc = :dept";
        $params['dept'] = $department;
    }
    if (!empty($phone)) {
        $updateCols[] = "pgw_nohp = :phone";
        $params['phone'] = $phone;
    }
    if (!empty($pin)) {
        $updateCols[] = "pin = :pin";
        $updateCols[] = "password = :pass";
        $params['pin'] = (int)$pin;
        $params['pass'] = $pin;
    }
    if (!empty($officeId)) {
        $updateCols[] = "office_id = :office_id";
        $params['office_id'] = $officeId;
    }
    if (!empty($officeName)) {
        $updateCols[] = "office_name = :office_name";
        $params['office_name'] = $officeName;
    }

    if (!empty($updateCols)) {
        $sql = "UPDATE employee SET " . implode(', ', $updateCols) . " WHERE pgw_id = :id";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
    }

    sendResponse(true, ['id' => $id], 'Data pegawai berhasil diperbarui.');

} elseif ($action === 'delete') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;
    $id = trim($input['id'] ?? $_GET['id'] ?? '');

    if (empty($id)) {
        sendResponse(false, null, 'ID Pegawai diperlukan.', 400);
    }

    $stmt = $pdo->prepare("UPDATE employee SET ishapus = 1 WHERE pgw_id = :id");
    $stmt->execute(['id' => $id]);

    sendResponse(true, ['id' => $id], 'Pegawai berhasil dinonaktifkan.');
} else {
    sendResponse(false, null, 'Action tidak valid.', 400);
}
