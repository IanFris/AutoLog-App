<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse("error", "Metode request tidak didukung. Gunakan POST.", null, 405);
}

$input = getRequestData();
$name = trim($input['name'] ?? '');
$email = trim($input['email'] ?? '');
$password = trim($input['password'] ?? '');

if (empty($name) || empty($email) || empty($password)) {
    sendResponse("error", "Nama, email, dan password wajib diisi.", null, 400);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    sendResponse("error", "Format email tidak valid.", null, 400);
}

if (strlen($password) < 6) {
    sendResponse("error", "Password minimal 6 karakter.", null, 400);
}

$db = (new Database())->getConnection();

// Periksa apakah email sudah terdaftar
$checkStmt = $db->prepare("SELECT id FROM users WHERE email = :email LIMIT 1");
$checkStmt->execute([':email' => $email]);
if ($checkStmt->fetch()) {
    sendResponse("error", "Email sudah terdaftar. Silakan login atau gunakan email lain.", null, 409);
}

// Hash password dengan algoritma BCRYPT
$passwordHash = password_hash($password, PASSWORD_BCRYPT);

try {
    $insertStmt = $db->prepare(
        "INSERT INTO users (name, email, password_hash, created_at) VALUES (:name, :email, :password_hash, NOW())"
    );
    $insertStmt->execute([
        ':name'          => $name,
        ':email'         => $email,
        ':password_hash' => $passwordHash,
    ]);

    $userId = (int)$db->lastInsertId();

    sendResponse("success", "Registrasi berhasil.", [
        "user" => [
            "id"    => $userId,
            "name"  => $name,
            "email" => $email
        ]
    ], 201);
} catch (PDOException $e) {
    sendResponse("error", "Gagal melakukan registrasi: " . $e->getMessage(), null, 500);
}
?>

