<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';

function admin_start_session(): void
{
    if (session_status() === PHP_SESSION_ACTIVE) {
        return;
    }

    ini_set('session.use_strict_mode', '1');
    session_name('autolog_admin');
    session_set_cookie_params([
        'lifetime' => 0,
        'path' => '/autolog/api/admin',
        'secure' => !empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off',
        'httponly' => true,
        'samesite' => 'Strict',
    ]);
    session_start();
}

function admin_db(): PDO
{
    $connection = (new Database())->getConnection();
    if (!$connection instanceof PDO) {
        throw new RuntimeException('Koneksi database admin tidak tersedia.');
    }

    return $connection;
}

function admin_escape(mixed $value): string
{
    return htmlspecialchars((string)$value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function admin_require_login(): void
{
    admin_start_session();
    if (!isset($_SESSION['admin_id'])) {
        header('Location: login.php');
        exit;
    }
}

function admin_csrf_token(): string
{
    admin_start_session();
    if (!isset($_SESSION['admin_csrf'])) {
        $_SESSION['admin_csrf'] = bin2hex(random_bytes(32));
    }

    return $_SESSION['admin_csrf'];
}

function admin_verify_csrf(): void
{
    admin_start_session();
    $token = $_POST['csrf_token'] ?? '';
    if (!is_string($token) || !hash_equals($_SESSION['admin_csrf'] ?? '', $token)) {
        http_response_code(400);
        exit('Permintaan tidak valid. Muat ulang halaman dan coba lagi.');
    }
}

function admin_redirect(string $page): never
{
    header('Location: index.php?page=' . rawurlencode($page));
    exit;
}

function admin_set_flash(string $type, string $message): void
{
    $_SESSION['admin_flash'] = ['type' => $type, 'message' => $message];
}

function admin_take_flash(): ?array
{
    $flash = $_SESSION['admin_flash'] ?? null;
    unset($_SESSION['admin_flash']);

    return is_array($flash) ? $flash : null;
}

function admin_pagination(PDO $db, string $countSql, array $params = []): array
{
    $stmt = $db->prepare($countSql);
    $stmt->execute($params);
    $total = (int)$stmt->fetchColumn();
    $page = filter_input(INPUT_GET, 'p', FILTER_VALIDATE_INT);
    $page = max(1, $page ?: 1);
    $perPage = 25;

    return [
        'total' => $total,
        'page' => $page,
        'per_page' => $perPage,
        'offset' => ($page - 1) * $perPage,
        'pages' => max(1, (int)ceil($total / $perPage)),
    ];
}
