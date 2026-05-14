<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once "db.php";
require_once "helpers.php";

if ($_SERVER["REQUEST_METHOD"] !== "POST") respond(["error" => "POST only"], 405);

$in = read_json_body();

$plateNumber = trim($in["plate_number"] ?? "");
$model = trim($in["model"] ?? "");
$isActive = isset($in["is_active"]) ? (int)$in["is_active"] : 1;

if ($plateNumber === "" || $model === "") {
  respond(["error" => "Required: plate_number, model"], 400);
}

if ($isActive !== 0 && $isActive !== 1) $isActive = 1;

try {
  $checkPlate = $conn->prepare("SELECT company_car_id FROM company_cars WHERE plate_number = ? LIMIT 1");
  $checkPlate->bind_param("s", $plateNumber);
  $checkPlate->execute();
  $plateExists = $checkPlate->get_result()->fetch_assoc();
  $checkPlate->close();

  if ($plateExists) {
    respond(["error" => "Plate number already exists"], 409);
  }

  $stmt = $conn->prepare("
    INSERT INTO company_cars (plate_number, model, is_active)
    VALUES (?, ?, ?)
  ");
  $stmt->bind_param("ssi", $plateNumber, $model, $isActive);
  $stmt->execute();

  $carId = (int)$stmt->insert_id;
  $stmt->close();

  $getCar = $conn->prepare("SELECT * FROM company_cars WHERE company_car_id = ? LIMIT 1");
  $getCar->bind_param("i", $carId);
  $getCar->execute();
  $car = $getCar->get_result()->fetch_assoc();
  $getCar->close();

  respond(["ok" => true, "car" => $car], 201);
} catch (mysqli_sql_exception $e) {
  if ($e->getCode() == 1062) {
    respond(["error" => "Plate number already exists"], 409);
  }
  respond(["error" => "Failed to create company car"], 500);
}
