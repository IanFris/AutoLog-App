<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse("error", "Metode tidak diizinkan. Gunakan GET.", null, 405);
}

$db = (new Database())->getConnection();

try {
    $stmt = $db->query(
        "SELECT id, name, default_km_interval, default_month_interval, icon 
         FROM service_types 
         ORDER BY id ASC"
    );
    $types = $stmt->fetchAll();

    foreach ($types as &$t) {
        $t['id'] = (int)$t['id'];
        $t['default_km_interval'] = (int)$t['default_km_interval'];
        $t['default_month_interval'] = (int)$t['default_month_interval'];
    }

    sendResponse("success", "Katalog jenis servis berhasil diambil.", $types);
} catch (PDOException $e) {
    error_log($e->getMessage());
    sendResponse("error", "Gagal mengambil data jenis servis.", null, 500);
}
?>
