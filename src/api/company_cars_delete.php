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
$carId = (int)($in["company_car_id"] ?? 0);

if ($carId <= 0) respond(["error" => "Required: company_car_id"], 400);

try {
  $checkTeam = $conn->prepare("SELECT team_id FROM teams WHERE company_car_id = ? LIMIT 1");
  $checkTeam->bind_param("i", $carId);
  $checkTeam->execute();
  $teamUsing = $checkTeam->get_result()->fetch_assoc();
  $checkTeam->close();

  if ($teamUsing) {
    respond(["error" => "Cannot delete company car (it is assigned to a team)"], 409);
  }

  $stmt = $conn->prepare("DELETE FROM company_cars WHERE company_car_id=?");
  $stmt->bind_param("i", $carId);
  $stmt->execute();
  respond(["ok" => true, "affected" => (int)$stmt->affected_rows]);
} catch (mysqli_sql_exception $e) {
  respond(["error" => "Failed to delete company car"], 500);
}
