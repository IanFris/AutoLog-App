<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/auth.php';

$method = $_SERVER['REQUEST_METHOD'];
$db = (new Database())->getConnection();

if ($method === 'GET') {
    $authenticatedUserId = requireAuthenticatedUser($db);
    $vehicleId = $_GET['vehicle_id'] ?? null;
    if (!$vehicleId) {
        sendResponse("error", "Parameter vehicle_id wajib disertakan.", null, 400);
    }
    $vehicleId = filter_var($vehicleId, FILTER_VALIDATE_INT);
    if (!$vehicleId) {
        sendResponse("error", "Parameter vehicle_id tidak valid.", null, 400);
    }
    requireVehicleOwnership($db, $authenticatedUserId, $vehicleId);

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
        error_log($e->getMessage());
        sendResponse("error", "Gagal mengambil riwayat servis.", null, 500);
    }
} elseif ($method === 'POST') {
    $input = getRequestData();
    $authenticatedUserId = requireAuthenticatedUser($db);
    $vehicleId = filter_var($input['vehicle_id'] ?? null, FILTER_VALIDATE_INT);
    $serviceTypeId = filter_var($input['service_type_id'] ?? null, FILTER_VALIDATE_INT);
    $serviceDate = $input['service_date'] ?? date('Y-m-d');
    $odometerKm = filter_var($input['odometer_km'] ?? null, FILTER_VALIDATE_INT);
    $costInput = $input['cost'] ?? null;
    $workshopInput = $input['workshop_name'] ?? 'Bengkel Umum';
    $notesInput = $input['notes'] ?? '';
    if (!is_string($workshopInput) || !is_string($notesInput)) {
        sendResponse("error", "Nama bengkel dan catatan harus berupa teks.", null, 400);
    }
    $workshopName = trim($workshopInput);
    $notes = trim($notesInput);
    $parsedServiceDate = is_string($serviceDate)
        ? DateTimeImmutable::createFromFormat('!Y-m-d', $serviceDate)
        : false;
    $dateErrors = DateTimeImmutable::getLastErrors();

    if (
        !$vehicleId || $vehicleId <= 0 || !$serviceTypeId || $serviceTypeId <= 0 ||
        $odometerKm === false || $odometerKm <= 0 || $odometerKm > 2147483647 ||
        $parsedServiceDate === false || $parsedServiceDate->format('Y-m-d') !== $serviceDate ||
        ($dateErrors !== false && ($dateErrors['warning_count'] > 0 || $dateErrors['error_count'] > 0)) ||
        !is_numeric($costInput) || !is_finite((float)$costInput) ||
        (float)$costInput < 0 || (float)$costInput > 9999999999.99
    ) {
        sendResponse("error", "vehicle_id, service_type_id, service_date, dan odometer_km wajib diisi dengan benar.", null, 400);
    }
    $cost = (float)$costInput;
    requireVehicleOwnership($db, $authenticatedUserId, $vehicleId);

    // The client only accepts images; PDFs and other non-image uploads are rejected.
    $receiptPhotoUrl = null;
    $uploadedFilePath = null;
    if (isset($_FILES['receipt_photo']) && $_FILES['receipt_photo']['error'] !== UPLOAD_ERR_NO_FILE) {
        $upload = $_FILES['receipt_photo'];
        if ($upload['error'] !== UPLOAD_ERR_OK) {
            sendResponse("error", "Gagal menerima file nota.", null, 400);
        }
        if ($upload['size'] > 5 * 1024 * 1024) {
            sendResponse("error", "Ukuran foto nota maksimal 5 MB.", null, 400);
        }

        $mimeType = (new finfo(FILEINFO_MIME_TYPE))->file($upload['tmp_name']);
        $allowedMimeTypes = [
            'image/jpeg' => 'jpg',
            'image/png' => 'png',
            'image/webp' => 'webp',
        ];
        if (!isset($allowedMimeTypes[$mimeType])) {
            sendResponse("error", "File nota harus berupa gambar JPG, PNG, atau WEBP.", null, 400);
        }

        $uploadDir = __DIR__ . '/../uploads/';
        if (!is_dir($uploadDir)) {
            if (!mkdir($uploadDir, 0755, true) && !is_dir($uploadDir)) {
                sendResponse("error", "Folder penyimpanan nota tidak dapat dibuat.", null, 500);
            }
        }

        $newFileName = 'receipt_' . bin2hex(random_bytes(16)) . '.' . $allowedMimeTypes[$mimeType];
        $uploadedFilePath = $uploadDir . $newFileName;
        if (!move_uploaded_file($upload['tmp_name'], $uploadedFilePath)) {
            $uploadedFilePath = null;
            sendResponse("error", "Foto nota gagal disimpan.", null, 500);
        }
        $receiptPhotoUrl = 'uploads/' . $newFileName;
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
            $dueDate = null;
            if ($monthInterval > 0) {
                $dueMonth = $parsedServiceDate->modify("first day of +$monthInterval months");
                $dueDate = $dueMonth->setDate(
                    (int)$dueMonth->format('Y'),
                    (int)$dueMonth->format('n'),
                    min((int)$parsedServiceDate->format('j'), (int)$dueMonth->format('t'))
                )->format('Y-m-d');
            }

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
        if ($db->inTransaction()) {
            $db->rollBack();
        }
        if ($uploadedFilePath !== null && is_file($uploadedFilePath)) {
            unlink($uploadedFilePath);
        }
        error_log($e->getMessage());
        sendResponse("error", "Gagal menyimpan log servis.", null, 500);
    }
} else {
    sendResponse("error", "Metode tidak diizinkan.", null, 405);
}
?>
