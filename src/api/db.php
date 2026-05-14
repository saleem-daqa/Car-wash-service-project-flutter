<?php
// db.php - shared MySQL connection for the car wash API.
//
// Configure production or non-standard local environments with:
// CARWASH_DB_NAME, CARWASH_DB_HOSTS, CARWASH_DB_PORTS, CARWASH_DB_USERS,
// CARWASH_DB_PASSWORDS. Comma-separated values are supported for hosts,
// ports, users, and passwords.

ini_set('display_errors', 0);
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

function env_list(string $key, array $fallback): array
{
    $value = getenv($key);
    if ($value === false || trim($value) === "") {
        return $fallback;
    }

    return array_map("trim", explode(",", $value));
}

$dbname = getenv("CARWASH_DB_NAME") ?: "car_wash_db";
$hosts = env_list("CARWASH_DB_HOSTS", ["127.0.0.1", "localhost"]);
$ports = array_map("intval", env_list("CARWASH_DB_PORTS", ["8889", "3306"]));
$usernames = env_list("CARWASH_DB_USERS", ["apiuser", "root"]);
$passwords = env_list("CARWASH_DB_PASSWORDS", ["", "root"]);

$conn = null;
$lastError = "";

foreach ($hosts as $host) {
    foreach ($ports as $port) {
        foreach ($usernames as $username) {
            foreach ($passwords as $password) {
                try {
                    $conn = new mysqli($host, $username, $password, $dbname, $port);
                    $conn->set_charset("utf8mb4");
                    return;
                } catch (mysqli_sql_exception $e) {
                    $lastError = $e->getMessage();
                    $conn = null;
                }
            }
        }
    }
}

error_log("CarWash DB connection failed: " . $lastError);

header("Content-Type: application/json; charset=UTF-8");
http_response_code(500);
echo json_encode([
    "status" => "error",
    "message" => "Database connection failed. Check server configuration."
]);
exit;
