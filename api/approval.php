<?php
require_once __DIR__ . '/config.php';

$action = $_GET['action'] ?? $_POST['action'] ?? 'list';

if ($action === 'list') {
    $userId = trim($_GET['user_id'] ?? '');
    $role   = trim($_GET['role'] ?? 'karyawan');

    $sql = "
        SELECT 
            p.*, 
            u.name AS resolved_user_name,
            u.department AS resolved_department,
            u.position AS resolved_position,
            u.role AS resolved_role,
            o.nama_kantor AS resolved_office_name
        FROM presensi p
        LEFT JOIN users u ON (p.nik = u.nik OR CAST(p.pgw_id AS CHAR) = CAST(u.id AS CHAR))
        LEFT JOIN offices o ON u.office_id = o.id
        WHERE (p.approval_status IS NOT NULL AND p.approval_status != '')
    ";
    $params = [];

    if ($role === 'karyawan' && !empty($userId)) {
        $sql .= " AND (p.pgw_id = :uid1 OR p.nik = :uid2 OR u.id = :uid3 OR u.nik = :uid4)";
        $params['uid1'] = $userId;
        $params['uid2'] = $userId;
        $params['uid3'] = $userId;
        $params['uid4'] = $userId;
    }

    $sql .= " ORDER BY p.waktu DESC, p.id DESC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll();

    $approvals = [];
    foreach ($rows as $r) {
        $statusVal = strtolower(trim($r['approval_status'] ?? 'pending'));
        if (!in_array($statusVal, ['pending', 'approved', 'rejected', 'escalated'])) {
            $statusVal = 'pending';
        }

        $typeVal = !empty($r['tipe_pengajuan']) ? $r['tipe_pengajuan'] : '';
        if (empty($typeVal)) {
            $typeVal = ($r['slot_type'] === 'koreksi_absen') ? 'koreksiAbsen' : 'luarRadius';
        }

        $titleVal = ($typeVal === 'koreksiAbsen') 
            ? 'Koreksi Jam Presensi (' . ucfirst($r['slot_type'] ?? 'Masuk') . ')'
            : 'Presensi Lapangan / Luar Radius';

        $reasonVal = !empty($r['catatan']) ? $r['catatan'] : 'Presensi tercatat di lokasi ' . ($r['lokasi'] ?? 'penugasan lapangan');

        $recTime = !empty($r['waktu']) ? $r['waktu'] : ($r['tanggal'] . ' 08:00:00');
        $formattedTime = date('H:i', strtotime($recTime)) . ' WIB';

        $distance = !empty($r['jarak_hq']) ? $r['jarak_hq'] : 'Di luar radius geofence';

        $officeName = !empty($r['resolved_office_name']) 
            ? $r['resolved_office_name'] 
            : 'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang';

        $userName = !empty($r['resolved_user_name']) ? $r['resolved_user_name'] : $r['pgw_nama'];
        $userDept = !empty($r['resolved_department']) ? $r['resolved_department'] : 'Operasional Lapangan';

        $approvals[] = [
            'id'               => (string)$r['id'],
            'user_id'          => (string)$r['pgw_id'],
            'user_nip'         => (string)($r['nik'] ?? $r['pgw_nup']),
            'user_name'        => $userName,
            'user_department'  => $userDept,
            'type'             => $typeVal,
            'title'            => $titleVal,
            'reason'           => $reasonVal,
            'start_date'       => $recTime,
            'end_date'         => $recTime,
            'status'           => $statusVal,
            'submitted_at'     => !empty($r['created_at']) ? $r['created_at'] : $recTime,
            'location_name'    => (string)($r['lokasi'] ?? 'Lokasi Presensi'),
            'latitude'         => isset($r['latitude']) ? (float)$r['latitude'] : 0.92031,
            'longitude'        => isset($r['longitude']) ? (float)$r['longitude'] : 104.46069,
            'distance_hq'      => $distance,
            'office_placement' => $officeName,
            'foto_url'         => !empty($r['foto_url']) ? $r['foto_url'] : null,
            'is_late'          => stripos((string)($r['status'] ?? ''), 'terlambat') !== false,
            'attendance_time'  => $formattedTime,
            'reviewed_by'      => $r['reviewed_by'] ?? null,
            'reviewed_at'      => $r['reviewed_at'] ?? null,
            'review_notes'     => $r['review_notes'] ?? null,
        ];
    }

    sendResponse(true, $approvals, 'Daftar pengajuan presensi berhasil dimuat dari tabel presensi.');

} elseif ($action === 'submit') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

    $pgwId    = trim($input['user_id'] ?? '1');
    $pgwNup   = trim($input['nik'] ?? $input['user_nip'] ?? $input['nip'] ?? '');
    $pgwNama  = trim($input['user_name'] ?? $input['name'] ?? '');
    $tipe     = trim($input['type'] ?? 'koreksiAbsen');
    $alasan   = trim($input['reason'] ?? $input['catatan'] ?? '');
    $tglMulai = trim($input['start_date'] ?? date('Y-m-d H:i:s'));
    $lokasi   = trim($input['location_name'] ?? $input['location'] ?? 'Lokasi Lapangan');
    $lat      = isset($input['latitude']) && is_numeric($input['latitude']) ? (float)$input['latitude'] : 0.92031;
    $lng      = isset($input['longitude']) && is_numeric($input['longitude']) ? (float)$input['longitude'] : 104.46069;
    $jarakHq  = trim($input['distance_hq'] ?? '3.5 km');
    $fotoUrl  = trim($input['foto_url'] ?? $input['attachment_url'] ?? '');
    $slotType = ($tipe === 'koreksiAbsen') ? 'koreksi_absen' : 'masuk';

    // Cari info user dari tabel users jika nama/nip kosong
    if (empty($pgwNama) || empty($pgwNup)) {
        $stmtU = $pdo->prepare("SELECT id, nik, name FROM users WHERE id = :uid1 OR nik = :uid2 LIMIT 1");
        $stmtU->execute(['uid1' => $pgwId, 'uid2' => $pgwNup ?: $pgwId]);
        $uRow = $stmtU->fetch();
        if ($uRow) {
            $pgwNama = $pgwNama ?: $uRow['name'];
            $pgwNup  = $uRow['nik'];
            $pgwId   = $uRow['id'];
        }
    }

    $tanggal = date('Y-m-d', strtotime($tglMulai));
    $waktu   = date('Y-m-d H:i:s', strtotime($tglMulai));

    $stmt = $pdo->prepare("
        INSERT INTO presensi (
            pgw_id, nik, pgw_nama, tanggal, slot_type, waktu, lokasi, 
            latitude, longitude, alamat, jarak_hq, foto_url, biometric_score, 
            catatan, status, approval_status, tipe_pengajuan
        ) VALUES (
            :pgw_id, :nik, :pgw_nama, :tanggal, :slot_type, :waktu, :lokasi,
            :lat, :lng, :alamat, :jarak_hq, :foto_url, 99.4,
            :catatan, 'Tepat Waktu', 'pending', :tipe_pengajuan
        )
    ");
    $stmt->execute([
        'pgw_id'         => is_numeric($pgwId) ? (int)$pgwId : 1,
        'nik'            => $pgwNup ?: 'EMP',
        'pgw_nama'       => $pgwNama ?: 'Karyawan Lapangan',
        'tanggal'        => $tanggal,
        'slot_type'      => $slotType,
        'waktu'          => $waktu,
        'lokasi'         => $lokasi,
        'lat'            => $lat,
        'lng'            => $lng,
        'alamat'         => $lokasi,
        'jarak_hq'       => $jarakHq,
        'foto_url'       => $fotoUrl,
        'catatan'        => $alasan ?: 'Pengajuan presensi lapangan / koreksi absen',
        'tipe_pengajuan' => $tipe,
    ]);

    $newId = $pdo->lastInsertId();

    sendResponse(true, [
        'id'          => (string)$newId,
        'status'      => 'pending',
        'slot_type'   => $slotType,
        'waktu'       => $waktu,
    ], 'Pengajuan presensi berhasil disimpan ke tabel presensi.');

} elseif ($action === 'review') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

    $id       = (int)($input['approval_id'] ?? $input['id'] ?? 0);
    $status   = trim($input['status'] ?? 'approved'); // approved / rejected
    $reviewer = trim($input['reviewer_name'] ?? 'Direktur Utama');
    $notes    = trim($input['notes'] ?? $input['review_notes'] ?? '');

    if ($id <= 0) {
        sendResponse(false, null, 'ID pengajuan presensi tidak valid.', 400);
    }

    $now = date('Y-m-d H:i:s');
    $stmt = $pdo->prepare("
        UPDATE presensi SET 
            approval_status = :status,
            reviewed_by = :reviewer,
            reviewed_at = :reviewed_at,
            review_notes = :notes
        WHERE id = :id
    ");
    $stmt->execute([
        'status'      => $status,
        'reviewer'    => $reviewer,
        'reviewed_at' => $now,
        'notes'       => $notes,
        'id'          => $id
    ]);

    sendResponse(true, ['id' => (string)$id, 'status' => $status], 'Status pengajuan presensi berhasil diperbarui di tabel presensi.');
} else {
    sendResponse(false, null, 'Action tidak valid.', 400);
}
