<?php
require_once "db.php";
require_once "helpers.php";

if ($_SERVER["REQUEST_METHOD"] !== "PUT") respond(["error" => "PUT only"], 405);

$in = read_json_body();
$userId = (int)($in["user_id"] ?? 0);
$isActive = isset($in["is_active"]) ? (int)$in["is_active"] : -1;

if ($userId <= 0 || ($isActive !== 0 && $isActive !== 1)) {
  respond(["error" => "Required: user_id, is_active (0/1)"], 400);
}

try {
  $stmt = $conn->prepare("
    UPDATE users
    SET is_active=?
    WHERE user_id=? AND role='EMPLOYEE'
  ");
  $stmt->bind_param("ii", $isActive, $userId);
  $stmt->execute();
  respond(["ok" => true, "affected" => (int)$stmt->affected_rows]);
} catch (Exception $e) {
  respond(["error" => "Failed to update status"], 500);
}
