<?php
require_once "db.php";
require_once "helpers.php";

if ($_SERVER["REQUEST_METHOD"] !== "PUT") respond(["error" => "PUT only"], 405);

$in = read_json_body();

$teamId = (int)($in["team_id"] ?? 0);
$name = trim($in["name"] ?? "");
$companyCarId = isset($in["company_car_id"]) ? (int)$in["company_car_id"] : null;
$isActive = isset($in["is_active"]) ? (int)$in["is_active"] : null;

if ($teamId <= 0) {
  respond(["error" => "Required: team_id"], 400);
}

if ($name === "" && $companyCarId === null && $isActive === null) {
  respond(["error" => "At least one field required: name, company_car_id, or is_active"], 400);
}

try {
  $checkTeam = $conn->prepare("SELECT team_id FROM teams WHERE team_id = ?");
  $checkTeam->bind_param("i", $teamId);
  $checkTeam->execute();
  $teamExists = $checkTeam->get_result()->fetch_assoc();
  $checkTeam->close();

  if (!$teamExists) {
    respond(["error" => "Team not found"], 404);
  }

  $updates = [];
  $params = [];
  $types = "";

  if ($name !== "") {
    $checkName = $conn->prepare("SELECT team_id FROM teams WHERE name = ? AND team_id != ? LIMIT 1");
    $checkName->bind_param("si", $name, $teamId);
    $checkName->execute();
    $nameExists = $checkName->get_result()->fetch_assoc();
    $checkName->close();

    if ($nameExists) {
      respond(["error" => "Team name already exists"], 409);
    }

    $updates[] = "name = ?";
    $params[] = $name;
    $types .= "s";
  }

  if ($companyCarId !== null && $companyCarId > 0) {
    $checkCar = $conn->prepare("SELECT company_car_id FROM company_cars WHERE company_car_id = ? AND is_active = 1");
    $checkCar->bind_param("i", $companyCarId);
    $checkCar->execute();
    $carExists = $checkCar->get_result()->fetch_assoc();
    $checkCar->close();

    if (!$carExists) {
      respond(["error" => "Company car not found or inactive"], 404);
    }

    $checkCarUsed = $conn->prepare("SELECT team_id FROM teams WHERE company_car_id = ? AND team_id != ? LIMIT 1");
    $checkCarUsed->bind_param("ii", $companyCarId, $teamId);
    $checkCarUsed->execute();
    $carUsed = $checkCarUsed->get_result()->fetch_assoc();
    $checkCarUsed->close();

    if ($carUsed) {
      respond(["error" => "Company car is already assigned to another team"], 409);
    }

    $updates[] = "company_car_id = ?";
    $params[] = $companyCarId;
    $types .= "i";
  }

  if ($isActive !== null && ($isActive === 0 || $isActive === 1)) {
    $updates[] = "is_active = ?";
    $params[] = $isActive;
    $types .= "i";
  }

  if (empty($updates)) {
    respond(["error" => "No valid fields to update"], 400);
  }

  $params[] = $teamId;
  $types .= "i";

  $sql = "UPDATE teams SET " . implode(", ", $updates) . " WHERE team_id = ?";
  $stmt = $conn->prepare($sql);
  $stmt->bind_param($types, ...$params);
  $stmt->execute();

  respond(["ok" => true, "affected" => (int)$stmt->affected_rows]);
} catch (mysqli_sql_exception $e) {
  if ($e->getCode() == 1062) {
    respond(["error" => "Team name or company car already in use"], 409);
  }
  respond(["error" => "Failed to update team", "details" => $e->getMessage()], 500);
} catch (Exception $e) {
  respond(["error" => "Failed to update team", "details" => $e->getMessage()], 500);
}
