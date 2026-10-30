<?php
// ====================================================================
// AutoLog Backend - Database Connection (PDO)
// Host: localhost | Database: autolog_db | User: root | Password: ""
// ====================================================================

class Database {
    private string $host = "localhost";
    private string $db_name = "autolog_db";
    private string $username = "root";
    private string $password = "";
    private ?PDO $conn = null;

    public function getConnection(): ?PDO {
        $this->conn = null;
        try {
            $dsn = "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8mb4";
            $options = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ];
            $this->conn = new PDO($dsn, $this->username, $this->password, $options);
        } catch (PDOException $exception) {
            header("Access-Control-Allow-Origin: *");
            header("Content-Type: application/json; charset=UTF-8");
            http_response_code(500);
            echo json_encode([
                "status"  => "error",
                "message" => "Koneksi database gagal: " . $exception->getMessage(),
                "data"    => null
            ]);
            exit;
        }
        return $this->conn;
    }
}
?>
