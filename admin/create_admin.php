<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/../api/config/database.php';

function read_value(string $prompt): string
{
    fwrite(STDOUT, $prompt);
    $value = fgets(STDIN);
    return $value === false ? '' : trim($value);
}

$email = strtolower(read_value('Email admin: '));
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    fwrite(STDERR, "Format email tidak valid.\n");
    exit(1);
}

$password = read_value('Password admin (minimal 12 karakter): ');
if (strlen($password) < 12) {
    fwrite(STDERR, "Password admin harus minimal 12 karakter.\n");
    exit(1);
}

try {
    $db = (new Database())->getConnection();
    $db->exec(
        "CREATE TABLE IF NOT EXISTS admin_users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            email VARCHAR(150) NOT NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci"
    );

    $stmt = $db->prepare(
        'INSERT INTO admin_users (email, password_hash) VALUES (:email, :password_hash)
         ON DUPLICATE KEY UPDATE password_hash = VALUES(password_hash)'
    );
    $stmt->execute([
        ':email' => $email,
        ':password_hash' => password_hash($password, PASSWORD_DEFAULT),
    ]);

    fwrite(STDOUT, "Akun admin berhasil disimpan. Buka /autolog/admin/ untuk login.\n");
} catch (PDOException $exception) {
    fwrite(STDERR, "Gagal menyiapkan akun admin: " . $exception->getMessage() . "\n");
    exit(1);
}
