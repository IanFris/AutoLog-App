<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse("error", "Metode request tidak didukung. Gunakan POST.", null, 405);
}

$input = getRequestData();
$emailInput = $input['email'] ?? '';
$passwordInput = $input['password'] ?? '';
if (!is_string($emailInput) || !is_string($passwordInput)) {
    sendResponse("error", "Email dan password harus berupa teks.", null, 400);
}
$email = trim($emailInput);
$password = trim($passwordInput);

if (empty($email) || empty($password)) {
    sendResponse("error", "Email dan password wajib diisi.", null, 400);
}

$db = (new Database())->getConnection();

try {
    $stmt = $db->prepare("SELECT id, name, email, password_hash FROM users WHERE email = :email LIMIT 1");
    $stmt->execute([':email' => $email]);
    $user = $stmt->fetch();

    if (!$user || !password_verify($password, $user['password_hash'])) {
        sendResponse("error", "Email atau password salah.", null, 401);
    }

    $token = createUserSession($db, (int)$user['id']);
    sendResponse("success", "Login berhasil.", [
        "user" => [
            "id"    => (int)$user['id'],
            "name"  => $user['name'],
            "email" => $user['email']
        ],
        "token" => $token
    ]);
} catch (PDOException $e) {
    error_log($e->getMessage());
    sendResponse("error", "Terjadi kesalahan pada server.", null, 500);
}
?>
