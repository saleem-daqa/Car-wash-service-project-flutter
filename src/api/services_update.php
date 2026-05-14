<?php
require_once "db.php";
require_once "helpers.php";

if ($_SERVER["REQUEST_METHOD"] !== "PUT") respond(["error" => "PUT only"], 405);

$in = read_json_body();

$serviceId = (int)($in["service_id"] ?? 0);
$name = trim($in["name"] ?? "");
$description = $in["description"] ?? null;
$price = $in["price"] ?? null;
$duration = $in["duration_minutes"] ?? null;
$isActive = isset($in["is_active"]) ? (int)$in["is_active"] : 1;

if ($serviceId <= 0 || $name === "" || $price === null || $duration === null) {
  respond(["error" => "Required: service_id, name, price, duration_minutes"], 400);
}
if ($isActive !== 0 && $isActive !== 1) $isActive = 1;

$price = (float)$price;
$duration = (int)$duration;

try {
  $stmt = $conn->prepare("
    UPDATE services
    SET name=?, description=?, price=?, duration_minutes=?, is_active=?
    WHERE service_id=?
  ");
  $stmt->bind_param("ssdiii", $name, $description, $price, $duration, $isActive, $serviceId);
  $stmt->execute();
  respond(["ok" => true, "affected" => (int)$stmt->affected_rows]);
} catch (mysqli_sql_exception $e) {
  if ($e->getCode() == 1062) respond(["error" => "Service name already exists"], 409);
  respond(["error" => "Failed to update service"], 500);
}
