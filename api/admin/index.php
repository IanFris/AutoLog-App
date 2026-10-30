<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';
admin_require_login();
$db = admin_db();
$allowedPages = ['overview', 'users', 'vehicles', 'services', 'catalog'];
$page = (string)($_GET['page'] ?? 'overview');
if (!in_array($page, $allowedPages, true)) {
    http_response_code(404);
    $page = 'overview';
}

$search = trim((string)($_GET['q'] ?? ''));
$flash = admin_take_flash();
$csrfToken = admin_csrf_token();
$counts = [];
foreach ([
    'users' => 'users',
    'vehicles' => 'vehicles',
    'services' => 'service_logs',
    'catalog' => 'service_types',
] as $key => $table) {
    $counts[$key] = (int)$db->query("SELECT COUNT(*) FROM `$table`")->fetchColumn();
}
$totalSpent = (float)$db->query('SELECT COALESCE(SUM(cost), 0) FROM service_logs')->fetchColumn();
$recentLogs = $db->query(
    'SELECT sl.service_date, sl.cost, st.name AS service_name,
            v.brand_model, v.license_plate, u.name AS user_name
     FROM service_logs sl
     JOIN vehicles v ON v.id = sl.vehicle_id
     JOIN users u ON u.id = v.user_id
     JOIN service_types st ON st.id = sl.service_type_id
     ORDER BY sl.service_date DESC, sl.id DESC LIMIT 8'
)->fetchAll();

$rows = [];
$pagination = null;
if ($page === 'users') {
    $where = $search === '' ? '' : ' WHERE name LIKE :search_name OR email LIKE :search_email';
    $params = $search === '' ? [] : [':search_name' => "%$search%", ':search_email' => "%$search%"];
    $pagination = admin_pagination($db, "SELECT COUNT(*) FROM users$where", $params);
    $stmt = $db->prepare(
        "SELECT u.id, u.name, u.email, u.created_at,
                (SELECT COUNT(*) FROM vehicles v WHERE v.user_id = u.id) AS vehicle_count
         FROM users u$where ORDER BY u.id DESC LIMIT :limit OFFSET :offset"
    );
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->bindValue(':limit', $pagination['per_page'], PDO::PARAM_INT);
    $stmt->bindValue(':offset', $pagination['offset'], PDO::PARAM_INT);
    $stmt->execute();
    $rows = $stmt->fetchAll();
} elseif ($page === 'vehicles') {
    $where = $search === '' ? '' : ' WHERE v.brand_model LIKE :search_model OR v.license_plate LIKE :search_plate OR u.name LIKE :search_owner';
    $params = $search === '' ? [] : [
        ':search_model' => "%$search%",
        ':search_plate' => "%$search%",
        ':search_owner' => "%$search%",
    ];
    $pagination = admin_pagination(
        $db,
        "SELECT COUNT(*) FROM vehicles v JOIN users u ON u.id = v.user_id$where",
        $params
    );
    $stmt = $db->prepare(
        "SELECT v.id, v.type, v.brand_model, v.license_plate, v.current_odometer, v.created_at,
                u.name AS user_name, u.email AS user_email
         FROM vehicles v JOIN users u ON u.id = v.user_id$where
         ORDER BY v.id DESC LIMIT :limit OFFSET :offset"
    );
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->bindValue(':limit', $pagination['per_page'], PDO::PARAM_INT);
    $stmt->bindValue(':offset', $pagination['offset'], PDO::PARAM_INT);
    $stmt->execute();
    $rows = $stmt->fetchAll();
} elseif ($page === 'services') {
    $where = $search === '' ? '' : ' WHERE u.name LIKE :search_owner OR v.license_plate LIKE :search_plate OR v.brand_model LIKE :search_model OR st.name LIKE :search_service OR sl.workshop_name LIKE :search_workshop';
    $params = $search === '' ? [] : [
        ':search_owner' => "%$search%",
        ':search_plate' => "%$search%",
        ':search_model' => "%$search%",
        ':search_service' => "%$search%",
        ':search_workshop' => "%$search%",
    ];
    $joins = ' FROM service_logs sl
               JOIN vehicles v ON v.id = sl.vehicle_id
               JOIN users u ON u.id = v.user_id
               JOIN service_types st ON st.id = sl.service_type_id';
    $pagination = admin_pagination($db, "SELECT COUNT(*)$joins$where", $params);
    $stmt = $db->prepare(
        "SELECT sl.id, sl.service_date, sl.odometer_km, sl.cost, sl.workshop_name, sl.notes,
                sl.receipt_photo_url, st.name AS service_name, v.brand_model, v.license_plate,
                u.name AS user_name$joins$where
         ORDER BY sl.service_date DESC, sl.id DESC LIMIT :limit OFFSET :offset"
    );
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->bindValue(':limit', $pagination['per_page'], PDO::PARAM_INT);
    $stmt->bindValue(':offset', $pagination['offset'], PDO::PARAM_INT);
    $stmt->execute();
    $rows = $stmt->fetchAll();
} elseif ($page === 'catalog') {
    $where = $search === '' ? '' : ' WHERE name LIKE :search';
    $params = $search === '' ? [] : [':search' => "%$search%"];
    $pagination = admin_pagination($db, "SELECT COUNT(*) FROM service_types$where", $params);
    $stmt = $db->prepare(
        "SELECT id, name, default_km_interval, default_month_interval, icon, created_at
         FROM service_types$where ORDER BY id DESC LIMIT :limit OFFSET :offset"
    );
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->bindValue(':limit', $pagination['per_page'], PDO::PARAM_INT);
    $stmt->bindValue(':offset', $pagination['offset'], PDO::PARAM_INT);
    $stmt->execute();
    $rows = $stmt->fetchAll();
}

function admin_money(mixed $value): string
{
    return 'Rp ' . number_format((float)$value, 0, ',', '.');
}

function admin_page_url(string $page, array $params = []): string
{
    return 'index.php?' . http_build_query(['page' => $page] + $params);
}
?>
<!doctype html>
<html lang="id">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?= admin_escape(ucfirst($page)) ?> | AutoLog Admin</title>
  <link rel="stylesheet" href="admin.css">
</head>
<body>
<div class="admin-shell">
  <aside class="sidebar">
    <a class="brand" href="index.php"><span class="brand-mark">A</span> AutoLog <small>ADMIN</small></a>
    <p class="side-label">MENU UTAMA</p>
    <nav>
      <?php foreach (['overview' => 'Ringkasan', 'users' => 'Pengguna', 'vehicles' => 'Kendaraan', 'services' => 'Riwayat Servis', 'catalog' => 'Katalog Servis'] as $key => $label): ?>
        <a class="nav-link <?= $page === $key ? 'active' : '' ?>" href="<?= admin_escape(admin_page_url($key)) ?>">
          <span class="nav-dot"></span><?= admin_escape($label) ?>
        </a>
      <?php endforeach; ?>
    </nav>
    <div class="sidebar-bottom">
      <div class="admin-profile"><span class="avatar"><?= admin_escape(strtoupper(substr($_SESSION['admin_email'] ?? 'A', 0, 1))) ?></span><span><strong>Administrator</strong><small><?= admin_escape($_SESSION['admin_email'] ?? '') ?></small></span></div>
      <form method="post" action="logout.php">
        <input type="hidden" name="csrf_token" value="<?= admin_escape($csrfToken) ?>">
        <button class="logout-button" type="submit">Keluar <span aria-hidden="true">↗</span></button>
      </form>
    </div>
  </aside>

  <main class="main-content">
    <header class="topbar"><span class="breadcrumb">AutoLog <span>/</span> <?= admin_escape(ucfirst($page)) ?></span><span class="secure-label"><span></span> Sesi admin aktif</span></header>
    <section class="page-content">
      <?php if ($flash): ?>
        <div class="notice <?= admin_escape($flash['type']) ?>" role="status"><?= admin_escape($flash['message']) ?></div>
      <?php endif; ?>

      <?php if ($page === 'overview'): ?>
        <div class="page-heading"><div><p class="eyebrow">OVERVIEW</p><h1>Dashboard Admin</h1><p class="muted">Pantau aktivitas dan data AutoLog dalam satu tempat.</p></div><span class="date-pill"><?= admin_escape(date('d M Y')) ?></span></div>
        <div class="stats-grid">
          <?php foreach (['users' => ['Total Pengguna', '◎'], 'vehicles' => ['Total Kendaraan', '◇'], 'services' => ['Catatan Servis', '↻'], 'catalog' => ['Jenis Servis', '▤']] as $key => [$label, $icon]): ?>
            <a class="stat-card" href="<?= admin_escape(admin_page_url($key === 'catalog' ? 'catalog' : $key)) ?>"><span class="stat-icon"><?= admin_escape($icon) ?></span><span class="stat-label"><?= admin_escape($label) ?></span><strong><?= number_format($counts[$key]) ?></strong><span class="stat-link">Lihat data <span>→</span></span></a>
          <?php endforeach; ?>
        </div>
        <div class="overview-grid">
          <article class="panel revenue-panel"><p class="eyebrow">TOTAL BIAYA TERCATAT</p><h2><?= admin_escape(admin_money($totalSpent)) ?></h2><p class="muted">Akumulasi biaya servis seluruh pengguna.</p><span class="revenue-mark">Rp</span></article>
          <article class="panel"><div class="panel-heading"><div><h2>Aktivitas terbaru</h2><p class="muted">Catatan servis yang baru ditambahkan.</p></div><a class="text-link" href="<?= admin_escape(admin_page_url('services')) ?>">Semua →</a></div>
            <?php if (!$recentLogs): ?><div class="empty-state">Belum ada catatan servis.</div><?php else: ?>
              <div class="table-wrap"><table><thead><tr><th>PENGGUNA / KENDARAAN</th><th>JENIS SERVIS</th><th>TANGGAL</th><th>BIAYA</th></tr></thead><tbody>
              <?php foreach ($recentLogs as $row): ?><tr><td><strong><?= admin_escape($row['user_name']) ?></strong><small><?= admin_escape($row['brand_model']) ?> · <?= admin_escape($row['license_plate']) ?></small></td><td><?= admin_escape($row['service_name']) ?></td><td><?= admin_escape($row['service_date']) ?></td><td><?= admin_escape(admin_money($row['cost'])) ?></td></tr><?php endforeach; ?>
              </tbody></table></div>
            <?php endif; ?>
          </article>
        </div>
      <?php else: ?>
        <?php
          $titles = ['users' => ['Pengguna', 'Akun yang terdaftar di AutoLog.'], 'vehicles' => ['Kendaraan', 'Kendaraan yang terhubung ke akun pengguna.'], 'services' => ['Riwayat Servis', 'Catatan perawatan kendaraan seluruh pengguna.'], 'catalog' => ['Katalog Servis', 'Atur jenis servis dan interval pengingat.']];
          [$title, $description] = $titles[$page];
        ?>
        <div class="page-heading"><div><p class="eyebrow">MANAJEMEN DATA</p><h1><?= admin_escape($title) ?></h1><p class="muted"><?= admin_escape($description) ?></p></div><span class="result-pill"><?= number_format($pagination['total']) ?> data</span></div>
        <section class="panel data-panel">
          <div class="panel-heading"><form class="search-form" method="get"><input type="hidden" name="page" value="<?= admin_escape($page) ?>"><label class="sr-only" for="search">Cari data</label><input id="search" type="search" name="q" value="<?= admin_escape($search) ?>" placeholder="Cari <?= admin_escape(strtolower($title)) ?>..."><button class="button secondary" type="submit">Cari</button></form>
          <?php if ($page === 'catalog'): ?><button class="button primary" type="button" onclick="document.getElementById('catalog-form').hidden = !document.getElementById('catalog-form').hidden">+ Tambah Jenis Servis</button><?php endif; ?></div>
          <?php if ($page === 'catalog'): ?>
            <form id="catalog-form" class="catalog-form" method="post" action="action.php" hidden>
              <input type="hidden" name="csrf_token" value="<?= admin_escape($csrfToken) ?>"><input type="hidden" name="action" value="create_catalog">
              <label>Nama servis<input name="name" maxlength="100" required></label><label>Interval KM<input name="km_interval" type="number" min="0" value="3000" required></label><label>Interval bulan<input name="month_interval" type="number" min="0" value="3" required></label><label>Ikon Material<input name="icon" maxlength="50" value="build" required></label><button class="button primary" type="submit">Simpan</button>
            </form>
          <?php endif; ?>
          <?php if (!$rows): ?><div class="empty-state">Tidak ada data yang cocok.</div><?php else: ?>
            <div class="table-wrap"><table>
              <?php if ($page === 'users'): ?>
                <thead><tr><th>PENGGUNA</th><th>KENDARAAN</th><th>TERDAFTAR</th><th></th></tr></thead><tbody><?php foreach ($rows as $row): ?><tr><td><strong><?= admin_escape($row['name']) ?></strong><small><?= admin_escape($row['email']) ?></small></td><td><?= number_format((int)$row['vehicle_count']) ?> kendaraan</td><td><?= admin_escape($row['created_at']) ?></td><td class="action-cell"><details><summary class="button secondary">Edit</summary><form class="inline-form" method="post" action="action.php"><input type="hidden" name="csrf_token" value="<?= admin_escape($csrfToken) ?>"><input type="hidden" name="action" value="update_user"><input type="hidden" name="id" value="<?= (int)$row['id'] ?>"><label>Nama<input name="name" maxlength="100" value="<?= admin_escape($row['name']) ?>" required></label><label>Email<input name="email" type="email" maxlength="150" value="<?= admin_escape($row['email']) ?>" required></label><button class="button primary" type="submit">Simpan</button></form></details><form method="post" action="action.php" onsubmit="return confirm('Hapus pengguna ini beserta kendaraan, servis, dan pengingatnya?')"><input type="hidden" name="csrf_token" value="<?= admin_escape($csrfToken) ?>"><input type="hidden" name="action" value="delete_user"><input type="hidden" name="id" value="<?= (int)$row['id'] ?>"><button class="button danger" type="submit">Hapus</button></form></td></tr><?php endforeach; ?></tbody>
              <?php elseif ($page === 'vehicles'): ?>
                <thead><tr><th>KENDARAAN</th><th>PEMILIK</th><th>JENIS</th><th>ODOMETER</th><th></th></tr></thead><tbody><?php foreach ($rows as $row): ?><tr><td><strong><?= admin_escape($row['brand_model']) ?></strong><small><?= admin_escape($row['license_plate']) ?></small></td><td><strong><?= admin_escape($row['user_name']) ?></strong><small><?= admin_escape($row['user_email']) ?></small></td><td><span class="tag"><?= admin_escape(ucfirst($row['type'])) ?></span></td><td><?= number_format((int)$row['current_odometer']) ?> km</td><td class="action-cell"><details><summary class="button secondary">Edit</summary><form class="inline-form" method="post" action="action.php"><input type="hidden" name="csrf_token" value="<?= admin_escape($csrfToken) ?>"><input type="hidden" name="action" value="update_vehicle"><input type="hidden" name="id" value="<?= (int)$row['id'] ?>"><label>Model<input name="brand_model" maxlength="120" value="<?= admin_escape($row['brand_model']) ?>" required></label><label>Plat nomor<input name="license_plate" maxlength="20" value="<?= admin_escape($row['license_plate']) ?>" required></label><label>Jenis<select name="type"><option value="motor" <?= $row['type'] === 'motor' ? 'selected' : '' ?>>Motor</option><option value="mobil" <?= $row['type'] === 'mobil' ? 'selected' : '' ?>>Mobil</option></select></label><label>Odometer (km)<input name="current_odometer" type="number" min="0" value="<?= (int)$row['current_odometer'] ?>" required></label><button class="button primary" type="submit">Simpan</button></form></details><form method="post" action="action.php" onsubmit="return confirm('Hapus kendaraan beserta riwayat servis dan pengingatnya?')"><input type="hidden" name="csrf_token" value="<?= admin_escape($csrfToken) ?>"><input type="hidden" name="action" value="delete_vehicle"><input type="hidden" name="id" value="<?= (int)$row['id'] ?>"><button class="button danger" type="submit">Hapus</button></form></td></tr><?php endforeach; ?></tbody>
              <?php elseif ($page === 'services'): ?>
                <thead><tr><th>PENGGUNA / KENDARAAN</th><th>JENIS SERVIS</th><th>TANGGAL</th><th>ODOMETER</th><th>BIAYA</th><th></th></tr></thead><tbody><?php foreach ($rows as $row): ?><tr><td><strong><?= admin_escape($row['user_name']) ?></strong><small><?= admin_escape($row['brand_model']) ?> · <?= admin_escape($row['license_plate']) ?></small></td><td><?= admin_escape($row['service_name']) ?><small><?= admin_escape($row['workshop_name'] ?? '') ?></small></td><td><?= admin_escape($row['service_date']) ?></td><td><?= number_format((int)$row['odometer_km']) ?> km</td><td><?= admin_escape(admin_money($row['cost'])) ?></td><td><form method="post" action="action.php" onsubmit="return confirm('Hapus catatan servis ini?')"><input type="hidden" name="csrf_token" value="<?= admin_escape($csrfToken) ?>"><input type="hidden" name="action" value="delete_service"><input type="hidden" name="id" value="<?= (int)$row['id'] ?>"><button class="button danger" type="submit">Hapus</button></form></td></tr><?php endforeach; ?></tbody>
              <?php else: ?>
                <thead><tr><th>JENIS SERVIS</th><th>INTERVAL</th><th>IKON</th><th></th></tr></thead><tbody><?php foreach ($rows as $row): ?><tr><td><strong><?= admin_escape($row['name']) ?></strong><small>ID #<?= (int)$row['id'] ?></small></td><td><?= number_format((int)$row['default_km_interval']) ?> km / <?= (int)$row['default_month_interval'] ?> bulan</td><td><span class="tag"><?= admin_escape($row['icon'] ?? 'build') ?></span></td><td class="action-cell"><details><summary class="button secondary">Edit</summary><form class="inline-form" method="post" action="action.php"><input type="hidden" name="csrf_token" value="<?= admin_escape($csrfToken) ?>"><input type="hidden" name="action" value="update_catalog"><input type="hidden" name="id" value="<?= (int)$row['id'] ?>"><label>Nama<input name="name" maxlength="100" value="<?= admin_escape($row['name']) ?>" required></label><label>Interval KM<input name="km_interval" type="number" min="0" value="<?= (int)$row['default_km_interval'] ?>" required></label><label>Interval bulan<input name="month_interval" type="number" min="0" value="<?= (int)$row['default_month_interval'] ?>" required></label><label>Ikon<input name="icon" maxlength="50" value="<?= admin_escape($row['icon'] ?? 'build') ?>" required></label><button class="button primary" type="submit">Simpan</button></form></details><form method="post" action="action.php" onsubmit="return confirm('Hapus jenis servis ini? Jenis yang sudah dipakai tidak dapat dihapus.')"><input type="hidden" name="csrf_token" value="<?= admin_escape($csrfToken) ?>"><input type="hidden" name="action" value="delete_catalog"><input type="hidden" name="id" value="<?= (int)$row['id'] ?>"><button class="button danger" type="submit">Hapus</button></form></td></tr><?php endforeach; ?></tbody>
              <?php endif; ?>
            </table></div>
          <?php endif; ?>
          <?php if ($pagination && $pagination['pages'] > 1): ?><div class="pagination"><span>Halaman <?= $pagination['page'] ?> dari <?= $pagination['pages'] ?></span><div><?php if ($pagination['page'] > 1): ?><a class="button secondary" href="<?= admin_escape(admin_page_url($page, ['q' => $search, 'p' => $pagination['page'] - 1])) ?>">← Sebelumnya</a><?php endif; ?><?php if ($pagination['page'] < $pagination['pages']): ?><a class="button secondary" href="<?= admin_escape(admin_page_url($page, ['q' => $search, 'p' => $pagination['page'] + 1])) ?>">Berikutnya →</a><?php endif; ?></div></div><?php endif; ?>
        </section>
      <?php endif; ?>
    </section>
  </main>
</div>
</body>
</html>
