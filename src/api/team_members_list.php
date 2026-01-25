<?php
require_once "db.php";
require_once "helpers.php";

$teamId = isset($_GET["team_id"]) ? (int)$_GET["team_id"] : 0;

try {
  if ($teamId > 0) {
    $stmt = $conn->prepare("
      SELECT tm.employee_id, u.full_name, u.email, u.phone, u.is_active
      FROM team_members tm
      JOIN users u ON tm.employee_id = u.user_id
      WHERE tm.team_id = ?
      ORDER BY u.full_name
    ");
    $stmt->bind_param("i", $teamId);
    $stmt->execute();
    $res = $stmt->get_result();
  } else {
    $res = $conn->query("
      SELECT tm.team_id, tm.employee_id, u.full_name, u.email, u.phone, u.is_active, t.name as team_name
      FROM team_members tm
      JOIN users u ON tm.employee_id = u.user_id
      JOIN teams t ON tm.team_id = t.team_id
      ORDER BY t.name, u.full_name
    ");
  }

  $members = [];
  while ($row = $res->fetch_assoc()) {
    $row["employee_id"] = (int)$row["employee_id"];
    $row["is_active"] = (int)$row["is_active"];
    if (isset($row["team_id"])) {
      $row["team_id"] = (int)$row["team_id"];
    }
    $members[] = $row;
  }

  respond(["members" => $members]);
} catch (Exception $e) {
  respond(["error" => "Failed to fetch team members", "details" => $e->getMessage()], 500);
}
