<?php
require_once "db.php";
require_once "helpers.php";

if ($_SERVER["REQUEST_METHOD"] !== "POST") respond(["error" => "POST only"], 405);

$in = read_json_body();

$name = trim($in["name"] ?? "");
$companyCarId = (int)($in["company_car_id"] ?? 0);
$isActive = isset($in["is_active"]) ? (int)$in["is_active"] : 1;

if ($name === "" || $companyCarId <= 0) {
  respond(["error" => "Required: name, company_car_id"], 400);
}

if ($isActive !== 0 && $isActive !== 1) $isActive = 1;

try {
  $checkCar = $conn->prepare("SELECT company_car_id FROM company_cars WHERE company_car_id = ? AND is_active = 1");
  $checkCar->bind_param("i", $companyCarId);
  $checkCar->execute();
  $carExists = $checkCar->get_result()->fetch_assoc();
  $checkCar->close();

  if (!$carExists) {
    respond(["error" => "Company car not found or inactive"], 404);
  }

  $checkName = $conn->prepare("SELECT team_id FROM teams WHERE name = ? LIMIT 1");
  $checkName->bind_param("s", $name);
  $checkName->execute();
  $nameExists = $checkName->get_result()->fetch_assoc();
  $checkName->close();

  if ($nameExists) {
    respond(["error" => "Team name already exists"], 409);
  }

  $checkCarUsed = $conn->prepare("SELECT team_id FROM teams WHERE company_car_id = ? LIMIT 1");
  $checkCarUsed->bind_param("i", $companyCarId);
  $checkCarUsed->execute();
  $carUsed = $checkCarUsed->get_result()->fetch_assoc();
  $checkCarUsed->close();

  if ($carUsed) {
    respond(["error" => "Company car is already assigned to another team"], 409);
  }

  $stmt = $conn->prepare("
    INSERT INTO teams (name, company_car_id, is_active)
    VALUES (?, ?, ?)
  ");
  $stmt->bind_param("sii", $name, $companyCarId, $isActive);
  $stmt->execute();

  $teamId = (int)$stmt->insert_id;
  $stmt->close();

  $getTeam = $conn->prepare("
    SELECT t.team_id, t.name, t.company_car_id, t.is_active, t.created_at,
           cc.plate_number as car_plate, cc.model as car_model
    FROM teams t
    LEFT JOIN company_cars cc ON t.company_car_id = cc.company_car_id
    WHERE t.team_id = ?
  ");
  $getTeam->bind_param("i", $teamId);
  $getTeam->execute();
  $team = $getTeam->get_result()->fetch_assoc();
  $getTeam->close();

  respond(["ok" => true, "team" => $team], 201);
} catch (mysqli_sql_exception $e) {
  if ($e->getCode() == 1062) {
    respond(["error" => "Team name or company car already in use"], 409);
  }
  respond(["error" => "Failed to create team"], 500);
} catch (Exception $e) {
  respond(["error" => "Failed to create team"], 500);
}
