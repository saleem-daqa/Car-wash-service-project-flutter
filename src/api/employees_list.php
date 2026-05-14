<?php
require_once "db.php";
require_once "helpers.php";

$active = isset($_GET["active"]) ? (int)$_GET["active"] : -1;

try {
  if ($active === 0 || $active === 1) {
    $stmt = $conn->prepare("
      SELECT user_id, full_name, email, phone, role, is_active, created_at
      FROM users
      WHERE role='EMPLOYEE' AND is_active=?
      ORDER BY user_id DESC
    ");
    $stmt->bind_param("i", $active);
    $stmt->execute();
    $res = $stmt->get_result();
  } else {
    $res = $conn->query("
      SELECT user_id, full_name, email, phone, role, is_active, created_at
      FROM users
      WHERE role='EMPLOYEE'
      ORDER BY user_id DESC
    ");
  }

  $employees = [];
  while ($row = $res->fetch_assoc()) {
    $row["user_id"] = (int)$row["user_id"];
    $row["is_active"] = (int)$row["is_active"];
    $employees[] = $row;
  }

  respond(["employees" => $employees]);
} catch (Exception $e) {
  respond(["error" => "Failed to fetch employees"], 500);
}
