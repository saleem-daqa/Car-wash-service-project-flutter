<?php
// db.php - auto-detect MAMP / XAMPP / system MySQL

error_reporting(0);
ini_set('display_errors', 0);

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

// ---- CONFIG (partners only edit this small section) ----
$dbname   = "car_wash_db";

// Most common usernames
$usernames = ["apiuser", "root"];

// Put your likely passwords here (each partner can add theirs)
// - MAMP default: root
// - XAMPP default: "" (empty)
// - Your apiuser: Api#12345 (if you created it)
$passwords = ["Api#12345", "root", "", "1234", "12345678", "Tala12345@@"];

// Most common hosts/ports
$hosts = ["127.0.0.1", "localhost"];
$ports = [8889, 3306];
// -------------------------------------------------------

// Try to connect using combinations (host, port, user, pass)
$conn = null;
$lastError = "";

foreach ($hosts as $host) {
  foreach ($ports as $port) {
    foreach ($usernames as $username) {
      foreach ($passwords as $password) {
        try {
          $conn = new mysqli($host, $username, $password, $dbname, $port);
          $conn->set_charset("utf8mb4");

          // Success — stop searching
          return;
        } catch (mysqli_sql_exception $e) {
          $lastError = $e->getMessage();
          $conn = null;
        }
      }
    }
  }
}

// If we reach here, all attempts failed:
header("Content-Type: application/json; charset=UTF-8");
http_response_code(500);
echo json_encode([
  "error" => "DB connection failed on all known MAMP/XAMPP configs",
  "dbname" => $dbname,
  "tried_hosts" => $hosts,
  "tried_ports" => $ports,
  "tried_users" => $usernames,
  "note" => "Edit db.php config section (passwords/usernames) to match your machine.",
  "last_error" => $lastError
]);
exit;
