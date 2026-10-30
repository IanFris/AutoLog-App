<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse("error", "Metode request tidak didukung. Gunakan POST.", null, 405);
}

$db = (new Database())->getConnection();
requireAuthenticatedUser($db);
$token = getBearerToken();
try {
    $stmt = $db->prepare("DELETE FROM user_sessions WHERE token_hash = :token_hash");
    $stmt->execute([':token_hash' => hash('sha256', $token)]);
} catch (PDOException $exception) {
    error_log($exception->getMessage());
    sendResponse("error", "Logout gagal. Silakan coba kembali.", null, 500);
}

sendResponse("success", "Logout berhasil.");
