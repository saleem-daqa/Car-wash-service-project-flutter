<?php
require_once "db.php";
require_once "helpers.php";

if ($_SERVER["REQUEST_METHOD"] !== "DELETE") respond(["error" => "DELETE only"], 405);

$in = read_json_body();
$teamId = (int)($in["team_id"] ?? 0);

if ($teamId <= 0) respond(["error" => "Required: team_id"], 400);

try {
  $stmt = $conn->prepare("DELETE FROM teams WHERE team_id=?");
  $stmt->bind_param("i", $teamId);
  $stmt->execute();
  respond(["ok" => true, "affected" => (int)$stmt->affected_rows]);
} catch (mysqli_sql_exception $e) {
  respond(["error" => "Failed to delete team", "details" => $e->getMessage()], 500);
}
