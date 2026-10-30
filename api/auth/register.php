<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse("error", "Metode request tidak didukung. Gunakan POST.", null, 405);
}

$input = getRequestData();
$nameInput = $input['name'] ?? '';
$emailInput = $input['email'] ?? '';
$passwordInput = $input['password'] ?? '';
if (!is_string($nameInput) || !is_string($emailInput) || !is_string($passwordInput)) {
    sendResponse("error", "Nama, email, dan password harus berupa teks.", null, 400);
}
$name = trim($nameInput);
$email = trim($emailInput);
$password = trim($passwordInput);

if (empty($name) || empty($email) || empty($password)) {
    sendResponse("error", "Nama, email, dan password wajib diisi.", null, 400);
}

if (mb_strlen($name, 'UTF-8') > 100 || mb_strlen($email, 'UTF-8') > 150) {
    sendResponse("error", "Nama atau email melebihi batas panjang yang diizinkan.", null, 400);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    sendResponse("error", "Format email tidak valid.", null, 400);
}

if (strlen($password) < 6 || strlen($password) > 72) {
    sendResponse("error", "Password harus berjumlah 6 hingga 72 byte.", null, 400);
}

$db = (new Database())->getConnection();

try {
    $checkStmt = $db->prepare("SELECT id FROM users WHERE email = :email LIMIT 1");
    $checkStmt->execute([':email' => $email]);
    if ($checkStmt->fetch()) {
        sendResponse("error", "Email sudah terdaftar. Silakan login atau gunakan email lain.", null, 409);
    }

    $passwordHash = password_hash($password, PASSWORD_BCRYPT);
    $db->beginTransaction();
    $insertStmt = $db->prepare(
        "INSERT INTO users (name, email, password_hash, created_at) VALUES (:name, :email, :password_hash, NOW())"
    );
    $insertStmt->execute([
        ':name'          => $name,
        ':email'         => $email,
        ':password_hash' => $passwordHash,
    ]);

    $userId = (int)$db->lastInsertId();
    $token = createUserSession($db, $userId);
    $db->commit();

    sendResponse("success", "Registrasi berhasil.", [
        "user" => [
            "id"    => $userId,
            "name"  => $name,
            "email" => $email
        ],
        "token" => $token
    ], 201);
} catch (PDOException $e) {
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    if ($e->getCode() === '23000') {
        sendResponse("error", "Email sudah terdaftar. Silakan login atau gunakan email lain.", null, 409);
    }
    error_log($e->getMessage());
    sendResponse("error", "Gagal melakukan registrasi.", null, 500);
}
?>
