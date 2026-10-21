<?php
require_once __DIR__ . '/config.php';

try {
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
            'seksi' => array_map(function($s) {
                return [
                    'id'   => (int)$s['id'],
                    'nama' => $s['nama'],
                    'kode' => $s['kode'],
                ];
            }, $seksiList),
        ];
    }

    sendResponse(true, $result, 'Daftar bidang dan seksi bidang berhasil dimuat.');

} catch (Exception $e) {
    sendResponse(false, null, 'Gagal memuat data bidang: ' . $e->getMessage(), 500);
}
