<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';
admin_start_session();

if (isset($_SESSION['admin_id'])) {
    header('Location: index.php');
    exit;
}

$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    admin_verify_csrf();
    $email = strtolower(trim((string)($_POST['email'] ?? '')));
    $password = (string)($_POST['password'] ?? '');

    if (!filter_var($email, FILTER_VALIDATE_EMAIL) || $password === '') {
        $error = 'Email atau password admin tidak valid.';
    } else {
        try {
            $stmt = admin_db()->prepare(
                'SELECT id, email, password_hash FROM admin_users WHERE email = :email LIMIT 1'
            );
            $stmt->execute([':email' => $email]);
            $admin = $stmt->fetch();

            if ($admin && password_verify($password, $admin['password_hash'])) {
                session_regenerate_id(true);
                $_SESSION['admin_id'] = (int)$admin['id'];
                $_SESSION['admin_email'] = $admin['email'];
                unset($_SESSION['admin_csrf']);
                header('Location: index.php');
                exit;
            }

            $error = 'Email atau password admin salah.';
        } catch (PDOException $exception) {
            error_log('AutoLog admin login: ' . $exception->getMessage());
            $error = 'Tabel admin belum siap. Jalankan `php admin/create_admin.php` dari folder aplikasi.';
        }
    }
}
?>
<!doctype html>
<html lang="id">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Login Admin | AutoLog</title>
  <link rel="stylesheet" href="admin.css">
</head>
<body class="login-page">
  <main class="login-card">
    <a class="brand" href="login.php"><span class="brand-mark">A</span> AutoLog <small>ADMIN</small></a>
    <h1>Masuk ke dashboard</h1>
    <p class="muted">Gunakan akun admin yang dibuat melalui terminal.</p>
    <?php if ($error !== ''): ?>
      <div class="notice error" role="alert"><?= admin_escape($error) ?></div>
    <?php endif; ?>
    <form method="post" class="stack">
      <input type="hidden" name="csrf_token" value="<?= admin_escape(admin_csrf_token()) ?>">
      <label>Email admin<input type="email" name="email" required autocomplete="username" autofocus></label>
      <label>Password<input type="password" name="password" required autocomplete="current-password"></label>
      <button class="button primary" type="submit">Masuk</button>
    </form>
  </main>
</body>
</html>
