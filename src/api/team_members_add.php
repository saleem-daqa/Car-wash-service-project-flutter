<?php
require_once "db.php";
require_once "helpers.php";

if ($_SERVER["REQUEST_METHOD"] !== "POST") respond(["error" => "POST only"], 405);

$in = read_json_body();

$teamId = (int)($in["team_id"] ?? 0);
$employeeId = (int)($in["employee_id"] ?? 0);

if ($teamId <= 0 || $employeeId <= 0) {
  respond(["error" => "Required: team_id, employee_id"], 400);
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

  $checkEmployee = $conn->prepare("SELECT user_id, role FROM users WHERE user_id = ? AND role = 'EMPLOYEE'");
  $checkEmployee->bind_param("i", $employeeId);
  $checkEmployee->execute();
  $employeeExists = $checkEmployee->get_result()->fetch_assoc();
  $checkEmployee->close();

  if (!$employeeExists) {
    respond(["error" => "Employee not found"], 404);
  }

  $checkExisting = $conn->prepare("SELECT team_id FROM team_members WHERE employee_id = ? LIMIT 1");
  $checkExisting->bind_param("i", $employeeId);
  $checkExisting->execute();
  $existing = $checkExisting->get_result()->fetch_assoc();
  $checkExisting->close();

  if ($existing) {
    respond(["error" => "Employee is already assigned to a team"], 409);
  }

  $stmt = $conn->prepare("INSERT INTO team_members (team_id, employee_id) VALUES (?, ?)");
  $stmt->bind_param("ii", $teamId, $employeeId);
  $stmt->execute();

  respond(["ok" => true, "message" => "Employee assigned to team successfully"]);
} catch (mysqli_sql_exception $e) {
  if ($e->getCode() == 1062) {
    respond(["error" => "Employee is already in this team"], 409);
  }
  respond(["error" => "Failed to assign employee"], 500);
}
