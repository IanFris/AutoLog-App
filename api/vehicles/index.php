<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/auth.php';

$method = $_SERVER['REQUEST_METHOD'];
$db = (new Database())->getConnection();

if ($method === 'GET') {
    $authenticatedUserId = requireAuthenticatedUser($db);
    $requestedUserId = filter_var($_GET['user_id'] ?? null, FILTER_VALIDATE_INT);
    if (!$requestedUserId) {
        sendResponse("error", "Parameter user_id diperlukan.", null, 400);
    }
    if ($requestedUserId !== $authenticatedUserId) {
        sendResponse("error", "Akses ditolak.", null, 403);
    }
    $userId = $authenticatedUserId;

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
        error_log($e->getMessage());
        sendResponse("error", "Gagal mengambil data kendaraan.", null, 500);
    }
} elseif ($method === 'POST') {
    $input = getRequestData();
    $userId = filter_var($input['user_id'] ?? null, FILTER_VALIDATE_INT);
    $authenticatedUserId = requireAuthenticatedUser($db);
    $typeInput = $input['type'] ?? 'motor';
    $brandModelInput = $input['brand_model'] ?? '';
    $licensePlateInput = $input['license_plate'] ?? '';
    if (!is_string($typeInput) || !is_string($brandModelInput) || !is_string($licensePlateInput)) {
        sendResponse("error", "Data kendaraan tidak valid.", null, 400);
    }
    $type = strtolower(trim($typeInput));
    $brandModel = trim($brandModelInput);
    $licensePlate = strtoupper(trim($licensePlateInput));
    $odometer = filter_var($input['current_odometer'] ?? 0, FILTER_VALIDATE_INT);

    if (!$userId || $userId <= 0 || $brandModel === '' || $licensePlate === '' ||
        $odometer === false || $odometer < 0 || $odometer > 2147483647) {
        sendResponse("error", "Data kendaraan tidak valid.", null, 400);
    }
    if ($userId !== $authenticatedUserId) {
        sendResponse("error", "Akses ditolak.", null, 403);
    }
    $userId = $authenticatedUserId;

    if (!in_array($type, ['motor', 'mobil'])) {
        sendResponse("error", "Tipe kendaraan tidak valid.", null, 400);
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
        error_log($e->getMessage());
        sendResponse("error", "Gagal menyimpan kendaraan.", null, 500);
    }
} elseif ($method === 'PUT') {
    $input = getRequestData();
    $id = filter_var($input['id'] ?? null, FILTER_VALIDATE_INT);
    $authenticatedUserId = requireAuthenticatedUser($db);

    if (!$id || $id <= 0) {
        sendResponse("error", "ID kendaraan wajib disertakan.", null, 400);
    }

    requireVehicleOwnership($db, $authenticatedUserId, $id);

    $typeInput = $input['type'] ?? null;
    $brandModelInput = $input['brand_model'] ?? null;
    $licensePlateInput = $input['license_plate'] ?? null;
    $odometer = filter_var($input['current_odometer'] ?? null, FILTER_VALIDATE_INT);

    $updateFields = [];
    $params = [':id' => $id, ':user_id' => $authenticatedUserId];

    if ($typeInput !== null) {
        $type = strtolower(trim((string)$typeInput));
        if (!in_array($type, ['motor', 'mobil'], true)) {
            sendResponse("error", "Tipe kendaraan tidak valid.", null, 400);
        }
        $updateFields[] = "type = :type";
        $params[':type'] = $type;
    }

    if ($brandModelInput !== null) {
        $brandModel = trim((string)$brandModelInput);
        if ($brandModel === '') {
            sendResponse("error", "Merk dan model kendaraan wajib diisi.", null, 400);
        }
        $updateFields[] = "brand_model = :brand_model";
        $params[':brand_model'] = $brandModel;
    }

    if ($licensePlateInput !== null) {
        $licensePlate = strtoupper(trim((string)$licensePlateInput));
        if ($licensePlate === '') {
            sendResponse("error", "Nomor polisi kendaraan wajib diisi.", null, 400);
        }
        $updateFields[] = "license_plate = :license_plate";
        $params[':license_plate'] = $licensePlate;
    }

    if ($odometer !== null && $odometer !== false) {
        if ($odometer < 0 || $odometer > 2147483647) {
            sendResponse("error", "Odometer kendaraan tidak valid.", null, 400);
        }
        $check = $db->prepare(
            "SELECT current_odometer FROM vehicles WHERE id = :id AND user_id = :user_id LIMIT 1"
        );
        $check->execute([':id' => $id, ':user_id' => $authenticatedUserId]);
        $currentOdometer = $check->fetchColumn();
        if ($currentOdometer === false) {
            sendResponse("error", "Kendaraan tidak ditemukan.", null, 404);
        }
        if ($odometer < (int)$currentOdometer) {
            sendResponse("error", "Odometer tidak boleh lebih kecil dari data saat ini.", null, 400);
        }
        $updateFields[] = "current_odometer = :current_odometer";
        $params[':current_odometer'] = $odometer;
    }

    if (empty($updateFields)) {
        sendResponse("error", "Tidak ada data kendaraan yang diubah.", null, 400);
    }

    try {
        $stmt = $db->prepare(
            "UPDATE vehicles SET " . implode(', ', $updateFields) . " WHERE id = :id AND user_id = :user_id"
        );
        $stmt->execute($params);

        $fetch = $db->prepare(
            "SELECT id, user_id, type, brand_model, license_plate, current_odometer, created_at
             FROM vehicles WHERE id = :id AND user_id = :user_id LIMIT 1"
        );
        $fetch->execute([':id' => $id, ':user_id' => $authenticatedUserId]);
        $updatedVehicle = $fetch->fetch();

        sendResponse("success", "Data kendaraan berhasil diperbarui.", [
            "id" => (int)$updatedVehicle['id'],
            "user_id" => (int)$updatedVehicle['user_id'],
            "type" => $updatedVehicle['type'],
            "brand_model" => $updatedVehicle['brand_model'],
            "license_plate" => $updatedVehicle['license_plate'],
            "current_odometer" => (int)$updatedVehicle['current_odometer'],
            "created_at" => $updatedVehicle['created_at'],
        ]);
    } catch (PDOException $e) {
        error_log($e->getMessage());
        sendResponse("error", "Gagal memperbarui kendaraan.", null, 500);
    }
} elseif ($method === 'DELETE') {
    $input = getRequestData();
    $id = filter_var($input['id'] ?? $_GET['id'] ?? null, FILTER_VALIDATE_INT);
    $authenticatedUserId = requireAuthenticatedUser($db);

    if (!$id || $id <= 0) {
        sendResponse("error", "ID kendaraan wajib disertakan.", null, 400);
    }

    requireVehicleOwnership($db, $authenticatedUserId, $id);

    try {
        $stmt = $db->prepare(
            "DELETE FROM vehicles WHERE id = :id AND user_id = :user_id"
        );
        $stmt->execute([':id' => $id, ':user_id' => $authenticatedUserId]);

        sendResponse("success", "Kendaraan berhasil dihapus.", ["id" => $id]);
    } catch (PDOException $e) {
        error_log($e->getMessage());
        sendResponse("error", "Gagal menghapus kendaraan.", null, 500);
    }
} else {
    sendResponse("error", "Metode tidak diizinkan.", null, 405);
}
?>
