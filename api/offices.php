<?php
require_once __DIR__ . '/config.php';

$action = $_GET['action'] ?? $_POST['action'] ?? 'list';

if ($action === 'list') {
    try {
        $stmt = $pdo->query("SELECT * FROM offices WHERE is_active = 1 ORDER BY is_primary DESC, nama_kantor ASC");
        $rows = $stmt->fetchAll();

        $offices = [];
        foreach ($rows as $r) {
            $offices[] = [
                'id'          => $r['id'],
                'name'        => $r['nama_kantor'],
                'nama_kantor' => $r['nama_kantor'],
                'address'     => $r['alamat'],
                'alamat'      => $r['alamat'],
                'latitude'    => (float)$r['latitude'],
                'longitude'   => (float)$r['longitude'],
                'radius'      => (int)$r['radius'],
                'is_primary'  => (bool)$r['is_primary'],
            ];
        }

        sendResponse(true, $offices, 'Daftar lokasi kantor berhasil dimuat.');
    } catch (\Exception $e) {
        sendResponse(false, null, 'Gagal memuat data kantor: ' . $e->getMessage(), 500);
    }
} elseif ($action === 'add') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;
    $id = trim($input['id'] ?? 'office_' . time());
    $name = trim($input['name'] ?? $input['nama_kantor'] ?? '');
    $address = trim($input['address'] ?? $input['alamat'] ?? '');
    $lat = (float)($input['latitude'] ?? 0);
    $lng = (float)($input['longitude'] ?? 0);
    $radius = (int)($input['radius'] ?? 100);
    $isPrimary = !empty($input['is_primary']) ? 1 : 0;

    if (empty($name)) {
        sendResponse(false, null, 'Nama kantor wajib diisi.', 400);
    }

    try {
        $stmt = $pdo->prepare("
            INSERT INTO offices (id, nama_kantor, alamat, latitude, longitude, radius, is_primary, is_active)
            VALUES (:id, :nama, :alamat, :lat, :lng, :radius, :is_primary, 1)
            ON DUPLICATE KEY UPDATE 
                nama_kantor = VALUES(nama_kantor),
                alamat = VALUES(alamat),
                latitude = VALUES(latitude),
                longitude = VALUES(longitude),
                radius = VALUES(radius),
                is_primary = VALUES(is_primary)
        ");
        $stmt->execute([
            'id'         => $id,
            'nama'       => $name,
            'alamat'     => $address,
            'lat'        => $lat,
            'lng'        => $lng,
            'radius'     => $radius,
            'is_primary' => $isPrimary,
        ]);

        sendResponse(true, ['id' => $id, 'name' => $name], 'Lokasi kantor berhasil disimpan.');
    } catch (\Exception $e) {
        sendResponse(false, null, 'Gagal menyimpan kantor: ' . $e->getMessage(), 500);
    }
} else {
    sendResponse(false, null, 'Action tidak valid.', 400);
}
