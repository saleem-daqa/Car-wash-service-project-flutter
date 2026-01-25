<?php
require_once "db.php";
require_once "helpers.php";

$active = isset($_GET["active"]) ? (int)$_GET["active"] : -1;

try {
  if ($active === 0 || $active === 1) {
    $stmt = $conn->prepare("
      SELECT t.team_id, t.name, t.company_car_id, t.is_active, t.created_at,
             cc.plate_number as car_plate, cc.model as car_model,
             COUNT(tm.employee_id) as member_count
      FROM teams t
      LEFT JOIN company_cars cc ON t.company_car_id = cc.company_car_id
      LEFT JOIN team_members tm ON t.team_id = tm.team_id
      WHERE t.is_active = ?
      GROUP BY t.team_id
      ORDER BY t.team_id DESC
    ");
    $stmt->bind_param("i", $active);
    $stmt->execute();
    $res = $stmt->get_result();
  } else {
    $res = $conn->query("
      SELECT t.team_id, t.name, t.company_car_id, t.is_active, t.created_at,
             cc.plate_number as car_plate, cc.model as car_model,
             COUNT(tm.employee_id) as member_count
      FROM teams t
      LEFT JOIN company_cars cc ON t.company_car_id = cc.company_car_id
      LEFT JOIN team_members tm ON t.team_id = tm.team_id
      GROUP BY t.team_id
      ORDER BY t.team_id DESC
    ");
  }

  $teams = [];
  while ($row = $res->fetch_assoc()) {
    $row["team_id"] = (int)$row["team_id"];
    $row["company_car_id"] = (int)$row["company_car_id"];
    $row["is_active"] = (int)$row["is_active"];
    $row["member_count"] = (int)$row["member_count"];
    $teams[] = $row;
  }

  respond(["teams" => $teams]);
} catch (Exception $e) {
  respond(["error" => "Failed to fetch teams", "details" => $e->getMessage()], 500);
}
