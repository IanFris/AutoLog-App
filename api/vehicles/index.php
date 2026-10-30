<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../config/database.php';

$method = $_SERVER['REQUEST_METHOD'];
$db = (new Database())->getConnection();

if ($method === 'GET') {
    $userId = $_GET['user_id'] ?? null;
    if (!$userId) {
        sendResponse("error", "Parameter user_id diperlukan.", null, 400);
    }

    try {
        $stmt = $db->prepare(
            "SELECT id, user_id, type, brand_model, license_plate, current_odometer, created_at 
             FROM vehicles 
             WHERE user_id = :user_id 
             ORDER BY id DESC"
        );
        $stmt->execute([':user_id' => $userId]);
        $vehicles = $stmt->fetchAll();

        // Format integer fields
        foreach ($vehicles as &$v) {
            $v['id'] = (int)$v['id'];
            $v['user_id'] = (int)$v['user_id'];
            $v['current_odometer'] = (int)$v['current_odometer'];
        }

        sendResponse("success", "Data kendaraan berhasil diambil.", $vehicles);
    } catch (PDOException $e) {
        sendResponse("error", "Gagal mengambil data kendaraan: " . $e->getMessage(), null, 500);
    }
} elseif ($method === 'POST') {
    $input = getRequestData();
    $userId = $input['user_id'] ?? null;
    $type = strtolower(trim($input['type'] ?? 'motor'));
    $brandModel = trim($input['brand_model'] ?? '');
    $licensePlate = strtoupper(trim($input['license_plate'] ?? ''));
    $odometer = (int)($input['current_odometer'] ?? 0);

    if (!$userId || empty($brandModel) || empty($licensePlate)) {
        sendResponse("error", "user_id, brand_model, dan license_plate wajib diisi.", null, 400);
    }

    if (!in_array($type, ['motor', 'mobil'])) {
        $type = 'motor';
    }

    try {
        $stmt = $db->prepare(
            "INSERT INTO vehicles (user_id, type, brand_model, license_plate, current_odometer, created_at)
             VALUES (:user_id, :type, :brand_model, :license_plate, :current_odometer, NOW())"
        );
        $stmt->execute([
            ':user_id'          => $userId,
            ':type'             => $type,
            ':brand_model'      => $brandModel,
            ':license_plate'    => $licensePlate,
            ':current_odometer' => $odometer,
        ]);

        $newId = (int)$db->lastInsertId();

        sendResponse("success", "Kendaraan berhasil ditambahkan.", [
            "id"               => $newId,
            "user_id"          => (int)$userId,
            "type"             => $type,
            "brand_model"      => $brandModel,
            "license_plate"    => $licensePlate,
            "current_odometer" => $odometer
        ], 201);
    } catch (PDOException $e) {
        sendResponse("error", "Gagal menyimpan kendaraan: " . $e->getMessage(), null, 500);
    }
} elseif ($method === 'PUT') {
    // Update odometer atau info kendaraan
    $input = getRequestData();
    $id = $input['id'] ?? null;
    $odometer = $input['current_odometer'] ?? null;

    if (!$id) {
        sendResponse("error", "ID kendaraan wajib disertakan.", null, 400);
    }

    try {
        if ($odometer !== null) {
            $stmt = $db->prepare("UPDATE vehicles SET current_odometer = :odometer WHERE id = :id");
            $stmt->execute([':odometer' => (int)$odometer, ':id' => $id]);
        }
        sendResponse("success", "Data kendaraan berhasil diperbarui.");
    } catch (PDOException $e) {
        sendResponse("error", "Gagal memperbarui kendaraan: " . $e->getMessage(), null, 500);
    }
} else {
    sendResponse("error", "Metode tidak diizinkan.", null, 405);
}
?>
