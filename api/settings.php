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
        'offices'       => [
            [
                'id'          => 'hq',
                'name'        => 'Kantor Pusat Tirtafield Tanjung Pinang',
                'address'     => 'Jl. Wisata Bahari No. 12, Tanjung Pinang Timur, Kepulauan Riau',
                'latitude'    => 0.92031,
                'longitude'   => 104.46069,
                'radius'      => 50.0,
                'is_primary'  => true,
            ],
            [
                'id'          => 'bintan_center',
                'name'        => 'Unit Pelayanan Bintan Centre',
                'address'     => 'Komp. Bintan Centre Blok A No. 5-6, Tanjung Pinang',
                'latitude'    => 0.92550,
                'longitude'   => 104.47120,
                'radius'      => 60.0,
                'is_primary'  => false,
            ],
            [
                'id'          => 'ipa_sei_pulai',
                'name'        => 'Instalasi Pengolahan Air (IPA) Sei Pulai',
                'address'     => 'Kawasan Waduk Sei Pulai, Bintan',
                'latitude'    => 0.90810,
                'longitude'   => 104.43250,
                'radius'      => 100.0,
                'is_primary'  => false,
            ],
        ],
    ]
];

$action = $_GET['action'] ?? $_POST['action'] ?? 'get';

if (!file_exists($settingsFile)) {
    file_put_contents($settingsFile, json_encode($defaultSettings, JSON_PRETTY_PRINT));
}

$currentSettings = json_decode(file_get_contents($settingsFile), true) ?: $defaultSettings;

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
    }
    sendResponse(true, $currentSettings['geofencing'], 'Pengaturan geofencing & lokasi kantor berhasil disimpan.');
} else {
    sendResponse(false, null, 'Action tidak valid.', 400);
}
