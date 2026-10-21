<?php
require_once __DIR__ . '/config.php';

$settingsFile = __DIR__ . '/settings.json';

$defaultSettings = [
    'operational_hours' => [
        'masuk'             => '08:00',
        'istirahat_keluar'  => '12:00',
        'istirahat_masuk'   => '13:00',
        'pulang'            => '17:00',
        'toleransi_menit'   => 15,
        'auto_lock_outside' => true,
        'hari_kerja'        => 'Senin - Jumat (5 Hari Kerja)',
    ],
    'geofencing' => [
        'strict_mode'   => true,
        'active_office_id' => 'hq',
        'offices'       => []
    ]
];

$action = $_GET['action'] ?? $_POST['action'] ?? 'get';

if (!file_exists($settingsFile)) {
    file_put_contents($settingsFile, json_encode($defaultSettings, JSON_PRETTY_PRINT));
}

$currentSettings = json_decode(file_get_contents($settingsFile), true) ?: $defaultSettings;

// Selalu sinkronkan daftar kantor dengan database tabel `offices`
try {
    $stmt = $pdo->query("SELECT * FROM offices WHERE is_active = 1 ORDER BY is_primary DESC, nama_kantor ASC");
    $dbOffices = $stmt->fetchAll();
    if (!empty($dbOffices)) {
        $syncedOffices = [];
        foreach ($dbOffices as $r) {
            $syncedOffices[] = [
                'id'         => $r['id'],
                'name'       => $r['nama_kantor'],
                'address'    => $r['alamat'],
                'latitude'   => (float)$r['latitude'],
                'longitude'  => (float)$r['longitude'],
                'radius'     => (float)$r['radius'],
                'is_primary' => (bool)$r['is_primary'],
            ];
        }
        $currentSettings['geofencing']['offices'] = $syncedOffices;
    }
} catch (\Exception $e) {
    // Fallback ke settings.json jika database terkendala
}

if ($action === 'get') {
    sendResponse(true, $currentSettings, 'Pengaturan sistem berhasil dimuat.');
} elseif ($action === 'save_operational') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;
    if (!empty($input)) {
        $currentSettings['operational_hours'] = array_merge($currentSettings['operational_hours'], $input);
        file_put_contents($settingsFile, json_encode($currentSettings, JSON_PRETTY_PRINT));
    }
    sendResponse(true, $currentSettings['operational_hours'], 'Pengaturan jam kerja operasional berhasil disimpan.');
} elseif ($action === 'save_geofencing') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;
    if (!empty($input)) {
        $currentSettings['geofencing'] = array_merge($currentSettings['geofencing'], $input);
        file_put_contents($settingsFile, json_encode($currentSettings, JSON_PRETTY_PRINT));

        // Sinkronkan kantor yang disimpan ke tabel `offices`
        if (!empty($input['offices']) && is_array($input['offices'])) {
            try {
                $stmtUpsert = $pdo->prepare("
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
                foreach ($input['offices'] as $off) {
                    $stmtUpsert->execute([
                        'id'         => $off['id'],
                        'nama'       => $off['name'],
                        'alamat'     => $off['address'] ?? '',
                        'lat'        => (float)($off['latitude'] ?? 0),
                        'lng'        => (float)($off['longitude'] ?? 0),
                        'radius'     => (int)($off['radius'] ?? 100),
                        'is_primary' => !empty($off['is_primary']) ? 1 : 0,
                    ]);
                }
            } catch (\Exception $e) {}
        }
    }
    sendResponse(true, $currentSettings['geofencing'], 'Pengaturan geofencing & lokasi kantor berhasil disimpan.');
} else {
    sendResponse(false, null, 'Action tidak valid.', 400);
}
