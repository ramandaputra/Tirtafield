<?php
require_once __DIR__ . '/config.php';

$action = $_GET['action'] ?? $_POST['action'] ?? 'list';

if ($action === 'list') {
    $userId = $_GET['user_id'] ?? '';
    $role   = $_GET['role'] ?? 'karyawan';

    if ($role === 'direktur' || $role === 'staffIT' || empty($userId)) {
        // Direktur & IT melihat semua request approval
        $stmt = $pdo->query("SELECT * FROM approval ORDER BY created_at DESC");
        $rows = $stmt->fetchAll();
    } else {
        // Karyawan hanya melihat request miliknya
        $stmt = $pdo->prepare("SELECT * FROM approval WHERE pgw_id = :uid ORDER BY created_at DESC");
        $stmt->execute(['uid' => $userId]);
        $rows = $stmt->fetchAll();
    }

    sendResponse(true, $rows, 'Daftar approval berhasil dimuat.');

} elseif ($action === 'submit') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

    $pgwId    = (int)($input['user_id'] ?? 1);
    $pgwNama  = $input['user_name'] ?? 'Karyawan';
    $tipe     = $input['type'] ?? 'koreksi_absen';
    $alasan   = $input['reason'] ?? '';
    $tglMulai = $input['start_date'] ?? date('Y-m-d');
    $tglSelesai = $input['end_date'] ?? $tglMulai;
    $lampiran = $input['attachment_url'] ?? '';

    if (empty($alasan)) {
        sendResponse(false, null, 'Alasan permohonan wajib diisi.', 400);
    }

    $stmt = $pdo->prepare("
        INSERT INTO approval (
            pgw_id, pgw_nama, tipe, alasan, tanggal_mulai, tanggal_selesai, lampiran_url, status
        ) VALUES (
            :pgw_id, :pgw_nama, :tipe, :alasan, :tgl_mulai, :tgl_selesai, :lampiran, 'pending'
        )
    ");
    $stmt->execute([
        'pgw_id'      => $pgwId,
        'pgw_nama'    => $pgwNama,
        'tipe'        => $tipe,
        'alasan'      => $alasan,
        'tgl_mulai'   => $tglMulai,
        'tgl_selesai' => $tglSelesai,
        'lampiran'    => $lampiran
    ]);

    $id = $pdo->lastInsertId();
    sendResponse(true, ['id' => $id], 'Permohonan approval berhasil diajukan.');

} elseif ($action === 'review') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

    $id       = (int)($input['approval_id'] ?? 0);
    $status   = $input['status'] ?? 'approved'; // approved / rejected
    $reviewer = $input['reviewer_name'] ?? 'Direktur Utama';
    $notes    = $input['notes'] ?? '';

    if ($id <= 0) {
        sendResponse(false, null, 'approval_id tidak valid.', 400);
    }

    $now = date('Y-m-d H:i:s');
    $stmt = $pdo->prepare("
        UPDATE approval SET 
            status = :status,
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

    sendResponse(true, ['id' => $id, 'status' => $status], 'Status approval berhasil diperbarui.');
} else {
    sendResponse(false, null, 'Action tidak valid.', 400);
}
