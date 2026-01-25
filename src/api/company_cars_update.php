<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once "db.php";
require_once "helpers.php";

if ($_SERVER["REQUEST_METHOD"] !== "PUT") respond(["error" => "PUT only"], 405);

$in = read_json_body();

$carId = (int)($in["company_car_id"] ?? 0);
$plateNumber = isset($in["plate_number"]) ? trim($in["plate_number"]) : null;
$model = isset($in["model"]) ? trim($in["model"]) : null;
$isActive = isset($in["is_active"]) ? (int)$in["is_active"] : null;

if ($carId <= 0) {
  respond(["error" => "Required: company_car_id"], 400);
}

try {
  $checkCar = $conn->prepare("SELECT company_car_id FROM company_cars WHERE company_car_id = ?");
  $checkCar->bind_param("i", $carId);
  $checkCar->execute();
  $carExists = $checkCar->get_result()->fetch_assoc();
  $checkCar->close();

  if (!$carExists) {
    respond(["error" => "Company car not found"], 404);
  }

  $updates = [];
  $params = [];
  $types = "";

  if ($plateNumber !== null && $plateNumber !== "") {
    $checkPlate = $conn->prepare("SELECT company_car_id FROM company_cars WHERE plate_number = ? AND company_car_id != ? LIMIT 1");
    $checkPlate->bind_param("si", $plateNumber, $carId);
    $checkPlate->execute();
    $plateExists = $checkPlate->get_result()->fetch_assoc();
    $checkPlate->close();

    if ($plateExists) {
      respond(["error" => "Plate number already exists"], 409);
    }

    $updates[] = "plate_number = ?";
    $params[] = $plateNumber;
    $types .= "s";
  }

  if ($model !== null && $model !== "") {
    $updates[] = "model = ?";
    $params[] = $model;
    $types .= "s";
  }

  if ($isActive !== null && ($isActive === 0 || $isActive === 1)) {
    $updates[] = "is_active = ?";
    $params[] = $isActive;
    $types .= "i";
  }

  if (empty($updates)) {
    respond(["error" => "No valid fields to update"], 400);
  }

  $params[] = $carId;
  $types .= "i";

  $sql = "UPDATE company_cars SET " . implode(", ", $updates) . " WHERE company_car_id = ?";
  $stmt = $conn->prepare($sql);
  $stmt->bind_param($types, ...$params);
  $stmt->execute();

  respond(["ok" => true, "affected" => (int)$stmt->affected_rows]);
} catch (mysqli_sql_exception $e) {
  if ($e->getCode() == 1062) {
    respond(["error" => "Plate number already exists"], 409);
  }
  respond(["error" => "Failed to update company car", "details" => $e->getMessage()], 500);
}
