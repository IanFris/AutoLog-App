<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse("error", "Metode request tidak didukung. Gunakan POST.", null, 405);
}

$input = getRequestData();
$email = trim($input['email'] ?? '');
$password = trim($input['password'] ?? '');

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

    sendResponse("success", "Login berhasil.", [
        "user" => [
            "id"    => (int)$user['id'],
            "name"  => $user['name'],
            "email" => $user['email']
        ]
    ]);
} catch (PDOException $e) {
    sendResponse("error", "Terjadi kesalahan pada server: " . $e->getMessage(), null, 500);
}
?>
