<?php
require_once 'config.php';

$url = $_GET['url'] ?? $_POST['url'] ?? '';

if (empty($url)) {
    sendResponse(false, null, 'URL tidak boleh kosong', 400);
    exit();
}

$url = trim($url);

// Check if raw coordinates like "-7.123, 112.456"
if (preg_match('/^(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)$/', $url, $rawMatches)) {
    sendResponse(true, [
        'latitude' => (float)$rawMatches[1],
        'longitude' => (float)$rawMatches[2],
        'name' => null,
        'resolved_url' => $url
    ], 'Koordinat berhasil dibaca.');
    exit();
}

// Ensure URL has schema
if (!preg_match('~^(?:f|ht)tps?://~i', $url)) {
    $url = 'https://' . $url;
}

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_HEADER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_AUTOREFERER, true);
curl_setopt($ch, CURLOPT_MAXREDIRS, 10);
curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
curl_setopt($ch, CURLOPT_TIMEOUT, 12);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

$response = curl_exec($ch);
$finalUrl = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
curl_close($ch);

if (empty($finalUrl)) {
    $finalUrl = $url;
}

$lat = null;
$lng = null;
$name = null;

// Pattern 1: Exact pin coords !3d<lat>!4d<lng>
if (preg_match('/!3d(-?\d+(?:\.\d+)?)(?:!)?4d(-?\d+(?:\.\d+)?)/', $finalUrl, $matches)) {
    $lat = (float)$matches[1];
    $lng = (float)$matches[2];
}

// Pattern 2: @<lat>,<lng>
if ($lat === null && preg_match('/@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)/', $finalUrl, $matches)) {
    $lat = (float)$matches[1];
    $lng = (float)$matches[2];
}

// Pattern 3: query params q=<lat>,<lng> or query=<lat>,<lng> or ll=<lat>,<lng>
if ($lat === null && preg_match('/(?:[?&](?:q|query|ll)=)(?:loc:)?(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)/', $finalUrl, $matches)) {
    $lat = (float)$matches[1];
    $lng = (float)$matches[2];
}

// Pattern 4: in HTML response body if available
if ($lat === null && !empty($response)) {
    if (preg_match('/content="https:\/\/maps\.google\.com\/maps\/api\/staticmap\?[^"]*center=(-?\d+(?:\.\d+)?)(?:%2C|,)(-?\d+(?:\.\d+)?)/i', $response, $matches)) {
        $lat = (float)$matches[1];
        $lng = (float)$matches[2];
    } elseif (preg_match('/\["https:\/\/www\.google\.com\/maps\/preview\/place\/[^"]*",null,\[(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)\]/', $response, $matches)) {
        $lat = (float)$matches[1];
        $lng = (float)$matches[2];
    }
}

// Extract place name if present: /place/<Place+Name>/
if (preg_match('/\/place\/([^\/@?#]+)/', $finalUrl, $matches)) {
    $decoded = urldecode(str_replace('+', ' ', $matches[1]));
    if (!empty($decoded)) {
        $name = $decoded;
    }
}

if ($lat !== null && $lng !== null) {
    sendResponse(true, [
        'latitude' => $lat,
        'longitude' => $lng,
        'name' => $name,
        'resolved_url' => $finalUrl
    ], 'Koordinat peta berhasil ditentukan dari tautan.');
} else {
    sendResponse(false, ['resolved_url' => $finalUrl], 'Gagal mengekstrak koordinat dari tautan peta ini. Pastikan tautan Google Maps valid.', 422);
}
