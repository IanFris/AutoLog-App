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
    // Update odometer atau info kendaraan
    $input = getRequestData();
    $id = filter_var($input['id'] ?? null, FILTER_VALIDATE_INT);
    $odometer = filter_var($input['current_odometer'] ?? null, FILTER_VALIDATE_INT);
    $authenticatedUserId = requireAuthenticatedUser($db);

    if (!$id || $odometer === false || $odometer === null ||
        $odometer < 0 || $odometer > 2147483647) {
        sendResponse("error", "ID kendaraan dan odometer yang valid wajib disertakan.", null, 400);
    }

    try {
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

        $stmt = $db->prepare(
            "UPDATE vehicles
             SET current_odometer = :odometer
             WHERE id = :id AND user_id = :user_id AND current_odometer <= :odometer"
        );
        $stmt->execute([
            ':odometer' => $odometer,
            ':id' => $id,
            ':user_id' => $authenticatedUserId,
        ]);
        if ($stmt->rowCount() === 0) {
            $currentStmt = $db->prepare(
                "SELECT current_odometer FROM vehicles WHERE id = :id AND user_id = :user_id LIMIT 1"
            );
            $currentStmt->execute([':id' => $id, ':user_id' => $authenticatedUserId]);
            $currentOdometer = $currentStmt->fetchColumn();
            if ($currentOdometer === false) {
                sendResponse("error", "Kendaraan tidak ditemukan.", null, 404);
            }
            if ((int)$currentOdometer > $odometer) {
                sendResponse("error", "Odometer berubah. Muat ulang data sebelum mencoba kembali.", null, 409);
            }
        }
        sendResponse("success", "Data kendaraan berhasil diperbarui.");
    } catch (PDOException $e) {
        error_log($e->getMessage());
        sendResponse("error", "Gagal memperbarui kendaraan.", null, 500);
    }
} else {
    sendResponse("error", "Metode tidak diizinkan.", null, 405);
}
?>
