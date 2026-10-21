<?php
require_once __DIR__ . '/config.php';

$action = $_GET['action'] ?? $_POST['action'] ?? 'today';
$todayDate = date('Y-m-d');

if ($action === 'today') {
    $userId = $_GET['user_id'] ?? '';
    $userName = $_GET['user_name'] ?? '';

    if (empty($userId)) {
        sendResponse(false, null, 'user_id diperlukan', 400);
    }

    // Ambil semua slot presensi user pada hari ini berdasarkan id atau nik
    $stmt = $pdo->prepare("
        SELECT * FROM presensi 
        WHERE (pgw_id = :uid1 OR nik = :uid2) AND tanggal = :today 
        ORDER BY waktu ASC
    ");
    $stmt->execute([
        'uid1'  => $userId,
        'uid2'  => $userId,
        'today' => $todayDate
    ]);
    $rows = $stmt->fetchAll();

    // Map ke 4 slot
    $slots = [
        'masuk'           => null,
        'istirahatKeluar' => null,
        'istirahatMasuk'  => null,
        'pulang'          => null,
    ];

    foreach ($rows as $r) {
        $st = $r['slot_type'];
        if (array_key_exists($st, $slots)) {
            $slots[$st] = [
                'type'          => $st,
                'recorded_time' => $r['waktu'],
                'location'      => $r['lokasi'],
                'notes'         => $r['catatan'],
                'foto_url'      => $r['foto_url'],
                'jarak_hq'      => $r['jarak_hq'],
                'latitude'      => isset($r['latitude']) ? (float)$r['latitude'] : null,
                'longitude'     => isset($r['longitude']) ? (float)$r['longitude'] : null,
                'biometric'     => (float)$r['biometric_score'],
                'status'        => $r['status'],
                'approval'      => $r['approval_status'],
            ];
        }
    }

    sendResponse(true, [
        'date'      => $todayDate,
        'user_id'   => $userId,
        'user_name' => $userName,
        'slots'     => $slots
    ], 'Data presensi hari ini berhasil dimuat.');

} elseif ($action === 'record') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

    $userId    = $input['user_id'] ?? '';
    $userName  = $input['user_name'] ?? '';
    $userNik   = $input['nik'] ?? $input['user_nip'] ?? $input['user_nup'] ?? '';
    $slotType  = $input['slot_type'] ?? 'masuk';
    $location  = $input['location'] ?? 'Kantor PERUMDA Tirta Kepri Tanjung Pinang';
    $latitude  = isset($input['latitude']) && is_numeric($input['latitude']) ? (float)$input['latitude'] : 0.92031;
    $longitude = isset($input['longitude']) && is_numeric($input['longitude']) ? (float)$input['longitude'] : 104.46069;
    $alamat    = $input['alamat'] ?? 'Tj. Pinang Timur, Kota Tanjung Pinang, Kepulauan Riau 29113';
    $jarakHq   = $input['jarak_hq'] ?? '8.5 km';
    $fotoUrl   = $input['foto_url'] ?? '';
    $biometric = (float)($input['biometric_score'] ?? 99.4);
    $notes     = $input['notes'] ?? '';
    $status    = $input['status'] ?? 'Tepat Waktu';

    if (empty($userId)) {
        sendResponse(false, null, 'user_id tidak boleh kosong', 400);
    }

    // Selalu sinkronkan dengan tabel users agar nik & nama konsisten
    $stmtU = $pdo->prepare("SELECT id, nik, name FROM users WHERE id = :id OR nik = :nik LIMIT 1");
    $stmtU->execute(['id' => $userId, 'nik' => !empty($userNik) ? $userNik : $userId]);
    $uRow = $stmtU->fetch();
    if ($uRow) {
        $userId   = (int)$uRow['id'];
        $userName = $userName ?: $uRow['name'];
        $userNik  = $uRow['nik'];
    } else {
        if (empty($userNik)) {
            $userNik = 'EMP-' . $userId;
        }
    }

    $now = date('Y-m-d H:i:s');

    // Cek apakah slot hari ini sudah pernah diisi
    $checkStmt = $pdo->prepare("
        SELECT id FROM presensi 
        WHERE (pgw_id = :uid1 OR nik = :uid2) AND tanggal = :today AND slot_type = :st 
        LIMIT 1
    ");
    $checkStmt->execute([
        'uid1'  => $userId,
        'uid2'  => $userNik,
        'today' => $todayDate,
        'st'    => $slotType
    ]);
    $existing = $checkStmt->fetch();

    if ($existing) {
        // Update existing record
        $updateStmt = $pdo->prepare("
            UPDATE presensi SET 
                pgw_id = :pgw_id,
                nik = :nik,
                pgw_nama = :pgw_nama,
                waktu = :waktu,
                lokasi = :lokasi,
                latitude = :lat,
                longitude = :lng,
                alamat = :alamat,
                jarak_hq = :jarak,
                foto_url = :foto,
                biometric_score = :bio,
                catatan = :catatan,
                status = :status
            WHERE id = :id
        ");
        $updateStmt->execute([
            'pgw_id'   => is_numeric($userId) ? (int)$userId : 1,
            'nik'      => $userNik,
            'pgw_nama' => $userName ?: 'Karyawan',
            'waktu'    => $now,
            'lokasi'   => $location,
            'lat'      => $latitude,
            'lng'      => $longitude,
            'alamat'   => $alamat,
            'jarak'    => $jarakHq,
            'foto'     => $fotoUrl,
            'bio'      => $biometric,
            'catatan'  => $notes,
            'status'   => $status,
            'id'       => $existing['id']
        ]);
        $recordId = $existing['id'];
    } else {
        // Insert new record (menggunakan kolom nik langsung)
        $insertStmt = $pdo->prepare("
            INSERT INTO presensi (
                pgw_id, nik, pgw_nama, tanggal, slot_type, waktu, lokasi, latitude, longitude, alamat, jarak_hq, foto_url, biometric_score, catatan, status, approval_status
            ) VALUES (
                :pgw_id, :nik, :pgw_nama, :tanggal, :slot_type, :waktu, :lokasi, :lat, :lng, :alamat, :jarak_hq, :foto_url, :biometric_score, :catatan, :status, 'pending'
            )
        ");
        $insertStmt->execute([
            'pgw_id'          => is_numeric($userId) ? (int)$userId : 1,
            'nik'             => $userNik,
            'pgw_nama'        => $userName ?: 'Karyawan',
            'tanggal'         => $todayDate,
            'slot_type'       => $slotType,
            'waktu'           => $now,
            'lokasi'          => $location,
            'lat'             => $latitude,
            'lng'             => $longitude,
            'alamat'          => $alamat,
            'jarak_hq'        => $jarakHq,
            'foto_url'        => $fotoUrl,
            'biometric_score' => $biometric,
            'catatan'         => $notes,
            'status'          => $status
        ]);
        $recordId = $pdo->lastInsertId();
    }

    sendResponse(true, [
        'id'            => $recordId,
        'slot_type'     => $slotType,
        'recorded_time' => $now,
        'location'      => $location
    ], 'Presensi berhasil disimpan ke database.');

} elseif ($action === 'history') {
    $userId = $_GET['user_id'] ?? '';
    $stmt = $pdo->prepare("
        SELECT * FROM presensi 
        WHERE pgw_id = :uid1 OR nik = :uid2 
        ORDER BY tanggal DESC, waktu DESC 
        LIMIT 50
    ");
    $stmt->execute(['uid1' => $userId, 'uid2' => $userId]);
    $history = $stmt->fetchAll();

    sendResponse(true, $history, 'Riwayat presensi berhasil dimuat.');

} elseif ($action === 'all_today') {
    $stmt = $pdo->prepare("
        SELECT 
            p.*, 
            COALESCE(u.name, p.pgw_nama) AS user_name,
            COALESCE(u.department, 'Operasional Lapangan') AS user_department,
            COALESCE(u.position, 'Staf') AS user_position,
            COALESCE(u.nik, p.nik) AS user_nik
        FROM presensi p
        LEFT JOIN users u ON (p.nik = u.nik OR CAST(p.pgw_id AS CHAR) = CAST(u.id AS CHAR))
        WHERE p.tanggal = :today 
        ORDER BY p.waktu DESC
    ");
    $stmt->execute(['today' => $todayDate]);
    $all = $stmt->fetchAll();

    sendResponse(true, $all, 'Seluruh data presensi hari ini berhasil dimuat.');
} else {
    sendResponse(false, null, 'Action tidak valid', 400);
}
