<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once __DIR__ . "/helpers.php";
require_once __DIR__ . "/db.php";

$active = isset($_GET["active"]) ? (int)$_GET["active"] : -1;

if ($active === 0 || $active === 1) {
  $result = $conn->query("SELECT * FROM services WHERE is_active = $active ORDER BY service_id DESC");
} else {
  $result = $conn->query("SELECT * FROM services ORDER BY service_id DESC");
}

$services = [];
while ($row = $result->fetch_assoc()) {
    $services[] = $row;
}

echo json_encode([
    "status" => "success",
    "services" => $services
]);
exit;
