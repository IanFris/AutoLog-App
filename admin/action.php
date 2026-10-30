<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';
admin_require_login();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    header('Allow: POST');
    exit('Metode tidak diizinkan.');
}

admin_verify_csrf();
$db = admin_db();
$action = (string)($_POST['action'] ?? '');
$id = filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT);

try {
    if ($action === 'update_user' && $id) {
        $name = trim((string)($_POST['name'] ?? ''));
        $email = strtolower(trim((string)($_POST['email'] ?? '')));
        if ($name === '' || strlen($name) > 100 || !filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($email) > 150) {
            admin_set_flash('error', 'Nama dan alamat email pengguna harus valid.');
            admin_redirect('users');
        }
        $stmt = $db->prepare('UPDATE users SET name = :name, email = :email WHERE id = :id');
        $stmt->execute([':name' => $name, ':email' => $email, ':id' => $id]);
        admin_set_flash('success', 'Data pengguna berhasil diperbarui.');
        admin_redirect('users');
    }

    if ($action === 'update_vehicle' && $id) {
        $brandModel = trim((string)($_POST['brand_model'] ?? ''));
        $licensePlate = strtoupper(trim((string)($_POST['license_plate'] ?? '')));
        $type = (string)($_POST['type'] ?? '');
        $odometer = filter_input(INPUT_POST, 'current_odometer', FILTER_VALIDATE_INT);
        if ($brandModel === '' || strlen($brandModel) > 120 || $licensePlate === '' || strlen($licensePlate) > 20 ||
            !in_array($type, ['motor', 'mobil'], true) || $odometer === false || $odometer === null || $odometer < 0) {
            admin_set_flash('error', 'Data kendaraan tidak valid.');
            admin_redirect('vehicles');
        }
        $stmt = $db->prepare(
            'UPDATE vehicles SET brand_model = :brand_model, license_plate = :license_plate,
             type = :type, current_odometer = :odometer WHERE id = :id'
        );
        $stmt->execute([
            ':brand_model' => $brandModel,
            ':license_plate' => $licensePlate,
            ':type' => $type,
            ':odometer' => $odometer,
            ':id' => $id,
        ]);
        admin_set_flash('success', 'Data kendaraan berhasil diperbarui.');
        admin_redirect('vehicles');
    }

    if ($action === 'delete_user' && $id) {
        $stmt = $db->prepare('DELETE FROM users WHERE id = :id');
        $stmt->execute([':id' => $id]);
        admin_set_flash('success', $stmt->rowCount() ? 'Pengguna dan data terkait berhasil dihapus.' : 'Pengguna tidak ditemukan.');
        admin_redirect('users');
    }

    if ($action === 'delete_vehicle' && $id) {
        $stmt = $db->prepare('DELETE FROM vehicles WHERE id = :id');
        $stmt->execute([':id' => $id]);
        admin_set_flash('success', $stmt->rowCount() ? 'Kendaraan dan data terkait berhasil dihapus.' : 'Kendaraan tidak ditemukan.');
        admin_redirect('vehicles');
    }

    if ($action === 'delete_service' && $id) {
        $stmt = $db->prepare('SELECT receipt_photo_url FROM service_logs WHERE id = :id');
        $stmt->execute([':id' => $id]);
        $photo = $stmt->fetchColumn();
        $delete = $db->prepare('DELETE FROM service_logs WHERE id = :id');
        $delete->execute([':id' => $id]);

        if ($delete->rowCount() && is_string($photo) && preg_match('#^uploads/[A-Za-z0-9._-]+$#', $photo)) {
            $photoPath = realpath(__DIR__ . '/../api/' . $photo);
            $uploadPath = realpath(__DIR__ . '/../api/uploads');
            if ($photoPath !== false && $uploadPath !== false && str_starts_with($photoPath, $uploadPath . DIRECTORY_SEPARATOR) && is_file($photoPath)) {
                if (!unlink($photoPath)) {
                    error_log('AutoLog admin could not remove receipt file: ' . $photoPath);
                }
            }
        }

        admin_set_flash('success', $delete->rowCount() ? 'Catatan servis berhasil dihapus.' : 'Catatan servis tidak ditemukan.');
        admin_redirect('services');
    }

    if ($action === 'create_catalog' || $action === 'update_catalog') {
        $name = trim((string)($_POST['name'] ?? ''));
        $km = filter_input(INPUT_POST, 'km_interval', FILTER_VALIDATE_INT);
        $months = filter_input(INPUT_POST, 'month_interval', FILTER_VALIDATE_INT);
        $icon = trim((string)($_POST['icon'] ?? ''));

        if ($name === '' || strlen($name) > 100 || $km === false || $km === null || $km < 0 ||
            $months === false || $months === null || $months < 0 || $icon === '' || strlen($icon) > 50) {
            admin_set_flash('error', 'Isi nama, interval, dan ikon dengan nilai yang valid.');
            admin_redirect('catalog');
        }

        if ($action === 'create_catalog') {
            $stmt = $db->prepare(
                'INSERT INTO service_types (name, default_km_interval, default_month_interval, icon)
                 VALUES (:name, :km, :months, :icon)'
            );
            $message = 'Jenis servis berhasil ditambahkan.';
        } elseif ($id) {
            $stmt = $db->prepare(
                'UPDATE service_types
                 SET name = :name, default_km_interval = :km, default_month_interval = :months, icon = :icon
                 WHERE id = :id'
            );
            $stmt->bindValue(':id', $id, PDO::PARAM_INT);
            $message = 'Jenis servis berhasil diperbarui.';
        } else {
            admin_redirect('catalog');
        }

        $stmt->bindValue(':name', $name);
        $stmt->bindValue(':km', $km, PDO::PARAM_INT);
        $stmt->bindValue(':months', $months, PDO::PARAM_INT);
        $stmt->bindValue(':icon', $icon);
        $stmt->execute();
        admin_set_flash('success', $message);
        admin_redirect('catalog');
    }

    if ($action === 'delete_catalog' && $id) {
        $stmt = $db->prepare('DELETE FROM service_types WHERE id = :id');
        $stmt->execute([':id' => $id]);
        admin_set_flash('success', $stmt->rowCount() ? 'Jenis servis berhasil dihapus.' : 'Jenis servis tidak ditemukan.');
        admin_redirect('catalog');
    }

    admin_set_flash('error', 'Aksi tidak valid. Pastikan data yang dikirim lengkap.');
    admin_redirect('overview');
} catch (PDOException $exception) {
    if ($action === 'delete_catalog' && (string)$exception->getCode() === '23000') {
        admin_set_flash('error', 'Jenis servis tidak dapat dihapus karena sudah dipakai dalam riwayat servis atau pengingat.');
        admin_redirect('catalog');
    }

    error_log('AutoLog admin action: ' . $exception->getMessage());
    $target = match ($action) {
        'create_catalog', 'update_catalog', 'delete_catalog' => 'catalog',
        'update_user', 'delete_user' => 'users',
        'update_vehicle', 'delete_vehicle' => 'vehicles',
        'delete_service' => 'services',
        default => 'overview',
    };
    $message = (string)$exception->getCode() === '23000'
        ? 'Data bentrok dengan data yang sudah terdaftar.'
        : 'Data gagal disimpan. Periksa input dan coba lagi.';
    admin_set_flash('error', $message);
    admin_redirect($target);
}
