<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse("error", "Metode tidak diizinkan. Gunakan GET.", null, 405);
}

$vehicleId = filter_var($_GET['vehicle_id'] ?? null, FILTER_VALIDATE_INT);
if (!$vehicleId) {
    sendResponse("error", "Parameter vehicle_id wajib disertakan.", null, 400);
}

$db = (new Database())->getConnection();
$authenticatedUserId = requireAuthenticatedUser($db);
requireVehicleOwnership($db, $authenticatedUserId, $vehicleId);

try {
    // 1. Ambil data kendaraan saat ini
    $vStmt = $db->prepare("SELECT id, brand_model, license_plate, current_odometer FROM vehicles WHERE id = :id LIMIT 1");
    $vStmt->execute([':id' => $vehicleId]);
    $vehicle = $vStmt->fetch();

    if (!$vehicle) {
        sendResponse("error", "Kendaraan tidak ditemukan.", null, 404);
    }

    $currentOdo = (int)$vehicle['current_odometer'];
    $today = new DateTimeImmutable('today');

    // 2. Ambil pengingat aktif (pending) beserta informasi jenis servis
    $stmt = $db->prepare(
        "SELECT r.id, r.vehicle_id, r.service_type_id, r.due_km, r.due_date, r.status,
                st.name AS service_type_name, st.icon AS service_type_icon,
                st.default_km_interval, st.default_month_interval
         FROM reminders r
         JOIN service_types st ON r.service_type_id = st.id
         WHERE r.vehicle_id = :vehicle_id AND r.status = 'pending'
         ORDER BY r.due_km ASC, r.due_date ASC"
    );
    $stmt->execute([':vehicle_id' => $vehicleId]);
    $reminders = $stmt->fetchAll();

    $calculatedReminders = [];

    foreach ($reminders as $r) {
        $dueKm = $r['due_km'] !== null ? (int)$r['due_km'] : null;
        $dueDateStr = $r['due_date'] ?? null;

        $remainingKm = null;
        $remainingDays = null;
        $isOverdue = false;
        $isNear = false;

        // Kalkulasi berdasarkan KM
        if ($dueKm !== null) {
            $remainingKm = $dueKm - $currentOdo;
            if ($remainingKm <= 0) {
                $isOverdue = true;
            } elseif ($remainingKm <= 500) {
                $isNear = true;
            }
        }

        // Kalkulasi berdasarkan Tanggal
        if ($dueDateStr !== null) {
            $dueDate = new DateTimeImmutable($dueDateStr);
            $diff = $today->diff($dueDate);
            $days = (int)$diff->format("%r%a");
            $remainingDays = $days;

            if ($days < 0) {
                $isOverdue = true;
            } elseif ($days <= 7) {
                $isNear = true;
            }
        }

        // Tentukan Status Warna & Label
        // Merah = Wajib Servis / Terlewat
        // Kuning = Mendekati (<= 500 KM atau <= 7 Hari)
        // Hijau = Aman
        if ($isOverdue) {
            $statusColor = "merah"; // Red
            $statusLabel = "Wajib Servis!";
            $badgeColorHex = "#EF4444";
        } elseif ($isNear) {
            $statusColor = "kuning"; // Yellow / Amber
            $statusLabel = "Mendekati Waktu Servis";
            $badgeColorHex = "#F59E0B";
        } else {
            $statusColor = "hijau"; // Green
            $statusLabel = "Aman";
            $badgeColorHex = "#10B981";
        }

        // Hitung estimasi progress penggunaan interval
        $kmInterval = (int)$r['default_km_interval'];
        $progress = 0.5;
        if ($dueKm !== null && $kmInterval > 0) {
            $lastKm = $dueKm - $kmInterval;
            $traveled = $currentOdo - $lastKm;
            $progress = max(0.0, min(1.0, $traveled / $kmInterval));
        }

        $calculatedReminders[] = [
            "id"                   => (int)$r['id'],
            "vehicle_id"           => (int)$r['vehicle_id'],
            "service_type_id"      => (int)$r['service_type_id'],
            "service_type_name"    => $r['service_type_name'],
            "service_type_icon"    => $r['service_type_icon'],
            "due_km"               => $dueKm,
            "due_date"             => $dueDateStr,
            "remaining_km"         => $remainingKm,
            "remaining_days"       => $remainingDays,
            "status_color"         => $statusColor,
            "status_label"         => $statusLabel,
            "badge_color_hex"      => $badgeColorHex,
            "progress_percentage"  => round($progress, 2)
        ];
    }

    sendResponse("success", "Kalkulasi status komponen pengingat berhasil.", [
        "current_odometer" => $currentOdo,
        "reminders"        => $calculatedReminders
    ]);
} catch (PDOException $e) {
    error_log($e->getMessage());
    sendResponse("error", "Gagal menghitung pengingat.", null, 500);
}
?>
