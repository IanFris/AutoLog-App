<?php
// ====================================================================
// AutoLog Backend - CORS & Standard Response Helper
// ====================================================================

// Set CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

/**
 * Format response JSON standar:
 * { "status": "success" | "error", "message": "...", "data": ... }
 */
function sendResponse(string $status, string $message, $data = null, int $httpCode = 200): void {
    http_response_code($httpCode);
    echo json_encode([
        "status"  => $status,
        "message" => $message,
        "data"    => $data
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

/**
 * Membaca data request dari JSON body atau $_POST (multipart form data)
 */
function getRequestData(): array {
    $contentType = $_SERVER["CONTENT_TYPE"] ?? '';
    if (stripos($contentType, 'application/json') !== false) {
        $raw = file_get_contents("php://input");
        $json = json_decode($raw, true);
        return is_array($json) ? $json : [];
    }
    return $_POST;
}
?>
