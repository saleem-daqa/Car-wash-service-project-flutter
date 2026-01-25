<?php
require_once "db.php";
require_once "helpers.php";

if ($_SERVER["REQUEST_METHOD"] !== "DELETE") respond(["error" => "DELETE only"], 405);

$in = read_json_body();
$employeeId = (int)($in["employee_id"] ?? 0);

if ($employeeId <= 0) respond(["error" => "Required: employee_id"], 400);

try {
  $stmt = $conn->prepare("DELETE FROM team_members WHERE employee_id = ?");
  $stmt->bind_param("i", $employeeId);
  $stmt->execute();
  respond(["ok" => true, "affected" => (int)$stmt->affected_rows]);
} catch (mysqli_sql_exception $e) {
  respond(["error" => "Failed to remove employee from team", "details" => $e->getMessage()], 500);
}
