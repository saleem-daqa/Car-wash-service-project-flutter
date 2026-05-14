<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once "db.php";
require_once "helpers.php";

if ($_SERVER["REQUEST_METHOD"] !== "DELETE") respond(["error" => "DELETE only"], 405);

$in = read_json_body();
$serviceId = (int)($in["service_id"] ?? 0);

if ($serviceId <= 0) respond(["error" => "Required: service_id"], 400);

try {
  $stmt = $conn->prepare("DELETE FROM services WHERE service_id=?");
  $stmt->bind_param("i", $serviceId);
  $stmt->execute();
  respond(["ok" => true, "affected" => (int)$stmt->affected_rows]);
} catch (mysqli_sql_exception $e) {
  // If service is referenced by bookings, delete will fail (FK constraint)
  respond(["error" => "Cannot delete service (it may be used in bookings)"], 409);
}
