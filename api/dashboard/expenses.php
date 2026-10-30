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
    // 1. Data kendaraan untuk menghitung biaya per KM
    $vStmt = $db->prepare("SELECT current_odometer FROM vehicles WHERE id = :id LIMIT 1");
    $vStmt->execute([':id' => $vehicleId]);
    $vehicle = $vStmt->fetch();
    $currentOdo = $vehicle ? (int)$vehicle['current_odometer'] : 0;

    // 2. Total all time & total count
    $totalStmt = $db->prepare(
        "SELECT COALESCE(SUM(cost), 0) AS total_all_time, COUNT(id) AS service_count 
         FROM service_logs 
         WHERE vehicle_id = :vehicle_id"
    );
    $totalStmt->execute([':vehicle_id' => $vehicleId]);
    $totalRow = $totalStmt->fetch();
    $totalAllTime = (float)$totalRow['total_all_time'];
    $serviceCount = (int)$totalRow['service_count'];

    // 3. Total bulan ini
    $monthStmt = $db->prepare(
        "SELECT COALESCE(SUM(cost), 0) AS total_this_month 
         FROM service_logs 
         WHERE vehicle_id = :vehicle_id 
           AND MONTH(service_date) = MONTH(CURRENT_DATE()) 
           AND YEAR(service_date) = YEAR(CURRENT_DATE())"
    );
    $monthStmt->execute([':vehicle_id' => $vehicleId]);
    $totalThisMonth = (float)$monthStmt->fetch()['total_this_month'];

    // 4. Total tahun ini
    $yearStmt = $db->prepare(
        "SELECT COALESCE(SUM(cost), 0) AS total_this_year 
         FROM service_logs 
         WHERE vehicle_id = :vehicle_id 
           AND YEAR(service_date) = YEAR(CURRENT_DATE())"
    );
    $yearStmt->execute([':vehicle_id' => $vehicleId]);
    $totalThisYear = (float)$yearStmt->fetch()['total_this_year'];

    // 5. Rincian pengeluaran per kategori servis
    $catStmt = $db->prepare(
        "SELECT st.name AS category_name, st.icon, 
                COALESCE(SUM(sl.cost), 0) AS category_cost, 
                COUNT(sl.id) AS count
         FROM service_logs sl
         JOIN service_types st ON sl.service_type_id = st.id
         WHERE sl.vehicle_id = :vehicle_id
         GROUP BY st.id, st.name, st.icon
         ORDER BY category_cost DESC"
    );
    $catStmt->execute([':vehicle_id' => $vehicleId]);
    $catList = $catStmt->fetchAll();

    $categoryBreakdown = [];
    foreach ($catList as $c) {
        $cost = (float)$c['category_cost'];
        $percentage = $totalAllTime > 0 ? round(($cost / $totalAllTime) * 100, 1) : 0;
        $categoryBreakdown[] = [
            "name"       => $c['category_name'],
            "icon"       => $c['icon'],
            "cost"       => $cost,
            "count"      => (int)$c['count'],
            "percentage" => $percentage
        ];
    }

    // Include the current month and the five preceding calendar months.
    $trendsStmt = $db->prepare(
        "SELECT DATE_FORMAT(service_date, '%Y-%m') AS month_key,
                COALESCE(SUM(cost), 0) AS total_cost
         FROM service_logs
         WHERE vehicle_id = :vehicle_id
           AND service_date >= DATE_FORMAT(DATE_SUB(CURRENT_DATE(), INTERVAL 5 MONTH), '%Y-%m-01')
           AND service_date < DATE_ADD(LAST_DAY(CURRENT_DATE()), INTERVAL 1 DAY)
         GROUP BY month_key
         ORDER BY month_key ASC"
    );
    $trendsStmt->execute([':vehicle_id' => $vehicleId]);
    $trendsByMonth = [];
    foreach ($trendsStmt->fetchAll() as $trend) {
        $trendsByMonth[$trend['month_key']] = (float)$trend['total_cost'];
    }

    $monthlyTrends = [];
    $currentMonth = new DateTimeImmutable('first day of this month');
    for ($offset = 5; $offset >= 0; $offset--) {
        $month = $currentMonth->modify("-$offset months");
        $monthKey = $month->format('Y-m');
        $monthlyTrends[] = [
            'month_key' => $monthKey,
            'month_label' => $month->format('M Y'),
            'total_cost' => $trendsByMonth[$monthKey] ?? 0.0,
        ];
    }

    // Biaya perawatan per KM
    $costPerKm = $currentOdo > 0 ? round($totalAllTime / $currentOdo, 2) : 0.0;

    sendResponse("success", "Rekapitulasi pengeluaran berhasil diambil.", [
        "total_all_time"     => $totalAllTime,
        "total_this_month"   => $totalThisMonth,
        "total_this_year"    => $totalThisYear,
        "service_count"      => $serviceCount,
        "cost_per_km"        => $costPerKm,
        "category_breakdown" => $categoryBreakdown,
        "monthly_trends"     => $monthlyTrends
    ]);
} catch (PDOException $e) {
    error_log($e->getMessage());
    sendResponse("error", "Gagal mengambil data pengeluaran.", null, 500);
}
?>
