<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../config/database.php';

$method = $_SERVER['REQUEST_METHOD'];
$db = (new Database())->getConnection();

if ($method === 'GET') {
    $vehicleId = $_GET['vehicle_id'] ?? null;
    if (!$vehicleId) {
        sendResponse("error", "Parameter vehicle_id wajib disertakan.", null, 400);
    }

    try {
        $stmt = $db->prepare(
            "SELECT sl.id, sl.vehicle_id, sl.service_type_id, sl.service_date, sl.odometer_km, 
                    sl.cost, sl.workshop_name, sl.notes, sl.receipt_photo_url, sl.created_at,
                    st.name AS service_type_name, st.icon AS service_type_icon
             FROM service_logs sl
             JOIN service_types st ON sl.service_type_id = st.id
             WHERE sl.vehicle_id = :vehicle_id
             ORDER BY sl.service_date DESC, sl.id DESC"
        );
        $stmt->execute([':vehicle_id' => $vehicleId]);
        $logs = $stmt->fetchAll();

        foreach ($logs as &$log) {
            $log['id'] = (int)$log['id'];
            $log['vehicle_id'] = (int)$log['vehicle_id'];
            $log['service_type_id'] = (int)$log['service_type_id'];
            $log['odometer_km'] = (int)$log['odometer_km'];
            $log['cost'] = (float)$log['cost'];
        }

        sendResponse("success", "Riwayat servis berhasil diambil.", $logs);
    } catch (PDOException $e) {
        sendResponse("error", "Gagal mengambil riwayat servis: " . $e->getMessage(), null, 500);
    }
} elseif ($method === 'POST') {
    $input = getRequestData();
    $vehicleId = $input['vehicle_id'] ?? null;
    $serviceTypeId = $input['service_type_id'] ?? null;
    $serviceDate = $input['service_date'] ?? date('Y-m-d');
    $odometerKm = (int)($input['odometer_km'] ?? 0);
    $cost = (float)($input['cost'] ?? 0.0);
    $workshopName = trim($input['workshop_name'] ?? 'Bengkel Umum');
    $notes = trim($input['notes'] ?? '');

    if (!$vehicleId || !$serviceTypeId || empty($serviceDate) || $odometerKm <= 0) {
        sendResponse("error", "vehicle_id, service_type_id, service_date, dan odometer_km wajib diisi dengan benar.", null, 400);
    }

    // Handle upload receipt photo jika ada
    $receiptPhotoUrl = null;
    if (isset($_FILES['receipt_photo']) && $_FILES['receipt_photo']['error'] === UPLOAD_ERR_OK) {
        $uploadDir = __DIR__ . '/../uploads/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }

        $fileTmp = $_FILES['receipt_photo']['tmp_name'];
        $fileName = $_FILES['receipt_photo']['name'];
        $fileExt = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));
        $allowedExts = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];

        if (in_array($fileExt, $allowedExts)) {
            $newFileName = 'receipt_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $fileExt;
            $destination = $uploadDir . $newFileName;
            if (move_uploaded_file($fileTmp, $destination)) {
                $receiptPhotoUrl = 'uploads/' . $newFileName;
            }
        }
    }

    try {
        $db->beginTransaction();

        // 1. Insert service log
        $stmt = $db->prepare(
            "INSERT INTO service_logs (vehicle_id, service_type_id, service_date, odometer_km, cost, workshop_name, notes, receipt_photo_url, created_at)
             VALUES (:vehicle_id, :service_type_id, :service_date, :odometer_km, :cost, :workshop_name, :notes, :receipt_photo_url, NOW())"
        );
        $stmt->execute([
            ':vehicle_id'        => $vehicleId,
            ':service_type_id'   => $serviceTypeId,
            ':service_date'      => $serviceDate,
            ':odometer_km'       => $odometerKm,
            ':cost'              => $cost,
            ':workshop_name'     => $workshopName,
            ':notes'             => $notes,
            ':receipt_photo_url' => $receiptPhotoUrl,
        ]);
        $logId = (int)$db->lastInsertId();

        // 2. Perbarui odometer kendaraan jika lebih tinggi dari saat ini
        $updateOdo = $db->prepare(
            "UPDATE vehicles 
             SET current_odometer = :odometer 
             WHERE id = :id AND current_odometer < :odometer"
        );
        $updateOdo->execute([':odometer' => $odometerKm, ':id' => $vehicleId]);

        // 3. Ambil data interval service_type untuk kalkulasi pengingat otomatis
        $typeStmt = $db->prepare("SELECT default_km_interval, default_month_interval FROM service_types WHERE id = :id LIMIT 1");
        $typeStmt->execute([':id' => $serviceTypeId]);
        $typeInfo = $typeStmt->fetch();

        if ($typeInfo) {
            $kmInterval = (int)$typeInfo['default_km_interval'];
            $monthInterval = (int)$typeInfo['default_month_interval'];

            $dueKm = $kmInterval > 0 ? ($odometerKm + $kmInterval) : null;
            $dueDate = $monthInterval > 0 
                ? date('Y-m-d', strtotime("+$monthInterval month", strtotime($serviceDate))) 
                : null;

            // Tandai reminder lama untuk komponen ini sebagai completed
            $markOld = $db->prepare(
                "UPDATE reminders 
                 SET status = 'completed' 
                 WHERE vehicle_id = :vehicle_id AND service_type_id = :service_type_id AND status = 'pending'"
            );
            $markOld->execute([':vehicle_id' => $vehicleId, ':service_type_id' => $serviceTypeId]);

            // Buat reminder baru
            $newRem = $db->prepare(
                "INSERT INTO reminders (vehicle_id, service_type_id, due_km, due_date, status, created_at)
                 VALUES (:vehicle_id, :service_type_id, :due_km, :due_date, 'pending', NOW())"
            );
            $newRem->execute([
                ':vehicle_id'      => $vehicleId,
                ':service_type_id' => $serviceTypeId,
                ':due_km'          => $dueKm,
                ':due_date'        => $dueDate,
            ]);
        }

        $db->commit();

        sendResponse("success", "Catatan servis berhasil ditambahkan.", [
            "id"                => $logId,
            "vehicle_id"        => (int)$vehicleId,
            "service_type_id"   => (int)$serviceTypeId,
            "service_date"      => $serviceDate,
            "odometer_km"       => $odometerKm,
            "cost"              => $cost,
            "workshop_name"     => $workshopName,
            "notes"             => $notes,
            "receipt_photo_url" => $receiptPhotoUrl
        ], 201);
    } catch (PDOException $e) {
        $db->rollBack();
        sendResponse("error", "Gagal menyimpan log servis: " . $e->getMessage(), null, 500);
    }
} else {
    sendResponse("error", "Metode tidak diizinkan.", null, 405);
}
?>

