<?php
require_once __DIR__ . '/config.php';

$action = $_GET['action'] ?? $_POST['action'] ?? 'list';

if ($action === 'list') {
    $q = trim($_GET['q'] ?? '');
    $roleFilter = trim($_GET['role'] ?? '');
    $deptFilter = trim($_GET['department'] ?? '');

    $sql = "
        SELECT u.*, o.nama_kantor AS resolved_office_name 
        FROM users u 
        LEFT JOIN offices o ON u.office_id = o.id 
        WHERE u.is_active = 1
    ";
    $params = [];

    if (!empty($q)) {
        $sql .= " AND (u.name LIKE :q1 OR u.nik LIKE :q2 OR u.department LIKE :q3 OR u.position LIKE :q4)";
        $params['q1'] = "%$q%";
        $params['q2'] = "%$q%";
        $params['q3'] = "%$q%";
        $params['q4'] = "%$q%";
    }

    if (!empty($deptFilter)) {
        $sql .= " AND u.department = :dept";
        $params['dept'] = $deptFilter;
    }

    if (!empty($roleFilter)) {
        $sql .= " AND u.role = :role";
        $params['role'] = $roleFilter;
    }

    $sql .= " ORDER BY u.id ASC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll();

    $employees = [];
    foreach ($rows as $u) {
        $officeId = !empty($u['office_id']) ? $u['office_id'] : 'hq';
        $officeName = !empty($u['resolved_office_name']) 
            ? $u['resolved_office_name'] 
            : (!empty($u['office_name']) ? $u['office_name'] : 'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang');

        $empPin = trim((string)($u['pin'] ?? ''));
        $activePin = !empty($empPin) && strlen($empPin) >= 4 ? $empPin : '123456';

        $employees[] = [
            'id'          => (string)$u['id'],
            'nip'         => (string)$u['nik'],
            'name'        => (string)$u['name'],
            'email'       => !empty($u['email']) 
                ? $u['email'] 
                : strtolower(str_replace(' ', '.', preg_replace('/[^a-zA-Z0-9 ]/', '', $u['name']))) . '@tirtafield.co.id',
            'pin'         => $activePin,
            'phone'       => (string)($u['phone'] ?? '081234567890'),
            'role'        => (string)$u['role'],
            'department'  => (string)$u['department'],
            'position'    => (string)$u['position'],
            'status'      => (string)($u['status_pegawai'] ?? 'Karyawan Tetap'),
            'office_id'   => $officeId,
            'office_name' => $officeName,
            'avatar_url'  => !empty($u['avatar_url']) ? $u['avatar_url'] : null,
        ];
    }

    sendResponse(true, $employees, 'Daftar data pegawai berhasil dimuat.');

} elseif ($action === 'add') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

    $nip        = trim($input['nip'] ?? $input['nik'] ?? '');
    $name       = trim($input['name'] ?? '');
    $department = trim($input['department'] ?? 'Bidang Hubungan Langganan');
    $position   = trim($input['position'] ?? 'Seksi Pembacaan Meter');
    $phone      = trim($input['phone'] ?? '081234567890');
    $pin        = trim($input['pin'] ?? '123456');
    $role       = trim($input['role'] ?? 'karyawan');
    $officeId   = trim($input['office_id'] ?? $input['officeId'] ?? 'hq');
    $officeName = trim($input['office_name'] ?? $input['officeName'] ?? '');

    if (empty($nip) || empty($name)) {
        sendResponse(false, null, 'NIP/NIK dan Nama Pegawai wajib diisi.', 400);
    }

    // Resolve nama kantor dari tabel offices jika belum disediakan
    if (empty($officeName) || $officeName === 'Kantor Pusat PERUMDA Tirta Kepri Tanjung Pinang') {
        $stmtOff = $pdo->prepare("SELECT nama_kantor FROM offices WHERE id = :id LIMIT 1");
        $stmtOff->execute(['id' => $officeId]);
        $offRow = $stmtOff->fetch();
        if ($offRow && !empty($offRow['nama_kantor'])) {
            $officeName = $offRow['nama_kantor'];
        } else {
            $officeName = 'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang';
        }
    }

    // Cek duplikasi NIP di tabel users
    $checkStmt = $pdo->prepare("SELECT id FROM users WHERE nik = :nip LIMIT 1");
    $checkStmt->execute(['nip' => $nip]);
    if ($checkStmt->fetch()) {
        sendResponse(false, null, "Pegawai dengan NIP '$nip' sudah terdaftar.", 400);
    }

    $email = strtolower(str_replace(' ', '.', preg_replace('/[^a-zA-Z0-9 ]/', '', $name))) . '@tirtafield.co.id';

    $stmt = $pdo->prepare("
        INSERT INTO users (
            nik, name, email, department, position, phone, pin, password, role, office_id, office_name, status_pegawai, is_active
        ) VALUES (
            :nip, :name, :email, :dept, :seksi, :phone, :pin, :pass, :role, :office_id, :office_name, 'Karyawan Tetap', 1
        )
    ");
    $stmt->execute([
        'nip'         => $nip,
        'name'        => $name,
        'email'       => $email,
        'dept'        => $department,
        'seksi'       => $position,
        'phone'       => $phone,
        'pin'         => $pin,
        'pass'        => $pin,
        'role'        => $role,
        'office_id'   => $officeId,
        'office_name' => $officeName,
    ]);

    $newId = $pdo->lastInsertId();

    sendResponse(true, [
        'id'          => (string)$newId,
        'nip'         => $nip,
        'name'        => $name,
        'email'       => $email,
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
    $position   = trim($input['position'] ?? $input['seksi_bidang'] ?? '');
    $phone      = trim($input['phone'] ?? '');
    $pin        = trim($input['pin'] ?? '');
    $role       = trim($input['role'] ?? '');
    $officeId   = trim($input['office_id'] ?? $input['officeId'] ?? '');
    $officeName = trim($input['office_name'] ?? $input['officeName'] ?? '');

    if (empty($id)) {
        sendResponse(false, null, 'ID Pegawai diperlukan.', 400);
    }

    // Jika officeId diubah dan officeName kosong, lookup dari offices
    if (!empty($officeId) && empty($officeName)) {
        $stmtOff = $pdo->prepare("SELECT nama_kantor FROM offices WHERE id = :id LIMIT 1");
        $stmtOff->execute(['id' => $officeId]);
        $offRow = $stmtOff->fetch();
        if ($offRow) {
            $officeName = $offRow['nama_kantor'];
        }
    }

    $updateCols = [];
    $params = ['id' => $id];

    if (!empty($nip)) {
        $updateCols[] = "nik = :nip";
        $params['nip'] = $nip;
    }
    if (!empty($name)) {
        $updateCols[] = "name = :name";
        $params['name'] = $name;
    }
    if (!empty($department)) {
        $updateCols[] = "department = :dept";
        $params['dept'] = $department;
    }
    if (!empty($position)) {
        $updateCols[] = "position = :pos";
        $params['pos'] = $position;
    }
    if (!empty($phone)) {
        $updateCols[] = "phone = :phone";
        $params['phone'] = $phone;
    }
    if (!empty($pin)) {
        $updateCols[] = "pin = :pin, password = :pass";
        $params['pin'] = $pin;
        $params['pass'] = $pin;
    }
    if (!empty($role)) {
        $updateCols[] = "role = :role";
        $params['role'] = $role;
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
        $sql = "UPDATE users SET " . implode(', ', $updateCols) . " WHERE id = :id";
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

    $stmt = $pdo->prepare("UPDATE users SET is_active = 0 WHERE id = :id");
    $stmt->execute(['id' => $id]);

    sendResponse(true, ['id' => $id], 'Pegawai berhasil dinonaktifkan.');

} elseif ($action === 'offices') {
    $stmt = $pdo->query("SELECT id, nama_kantor AS name, alamat AS address, latitude, longitude, radius, is_primary FROM offices WHERE is_active = 1 ORDER BY is_primary DESC, nama_kantor ASC");
    $offices = $stmt->fetchAll();
    sendResponse(true, $offices, 'Daftar lokasi kantor penempatan.');

} elseif ($action === 'bidang_list') {
    $stmt = $pdo->query("SELECT id, nama, kode, urutan FROM ref_bidang ORDER BY urutan ASC");
    $bidangList = $stmt->fetchAll();

    $result = [];
    foreach ($bidangList as $b) {
        $stmtSeksi = $pdo->prepare("SELECT id, nama, kode, urutan FROM ref_seksi_bidang WHERE bidang_id = :bidang_id ORDER BY urutan ASC");
        $stmtSeksi->execute(['bidang_id' => $b['id']]);
        $seksiList = $stmtSeksi->fetchAll();

        $result[] = [
            'id'    => (int)$b['id'],
            'nama'  => $b['nama'],
            'kode'  => $b['kode'],
            'seksi' => array_column($seksiList, 'nama'),
        ];
    }
    sendResponse(true, $result, 'Daftar bidang dan seksi bidang.');
} else {
    sendResponse(false, null, 'Action tidak valid.', 400);
}
