<?php

function getBearerToken(): ?string {
    $headers = function_exists('getallheaders') ? getallheaders() : [];
    $authorization = $headers['Authorization'] ?? $headers['authorization'] ??
        $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';

    if (!is_string($authorization) || !preg_match('/^Bearer ([a-f0-9]{64})$/i', trim($authorization), $matches)) {
        return null;
    }

    return $matches[1];
}

function createUserSession(PDO $db, int $userId): string {
    $token = bin2hex(random_bytes(32));
    $db->exec("DELETE FROM user_sessions WHERE expires_at <= NOW()");
    $stmt = $db->prepare(
        "INSERT INTO user_sessions (user_id, token_hash, expires_at)
         VALUES (:user_id, :token_hash, DATE_ADD(NOW(), INTERVAL 30 DAY))"
    );
    $stmt->execute([
        ':user_id' => $userId,
        ':token_hash' => hash('sha256', $token),
    ]);

    return $token;
}

function requireAuthenticatedUser(PDO $db): int {
    $token = getBearerToken();
    if ($token === null) {
        sendResponse("error", "Autentikasi diperlukan.", null, 401);
    }

    $stmt = $db->prepare(
        "SELECT user_id FROM user_sessions
         WHERE token_hash = :token_hash AND expires_at > NOW()
         LIMIT 1"
    );
    $stmt->execute([':token_hash' => hash('sha256', $token)]);
    $userId = $stmt->fetchColumn();

    if ($userId === false) {
        sendResponse("error", "Sesi tidak valid atau telah kedaluwarsa. Silakan login kembali.", null, 401);
    }

    return (int)$userId;
}

function requireVehicleOwnership(PDO $db, int $userId, int $vehicleId): void {
    $stmt = $db->prepare(
        "SELECT id FROM vehicles WHERE id = :vehicle_id AND user_id = :user_id LIMIT 1"
    );
    $stmt->execute([
        ':vehicle_id' => $vehicleId,
        ':user_id' => $userId,
    ]);

    if ($stmt->fetchColumn() === false) {
        sendResponse("error", "Kendaraan tidak ditemukan.", null, 404);
    }
}
