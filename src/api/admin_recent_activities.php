<?php
require_once "db.php";
require_once "helpers.php";

$limit = isset($_GET["limit"]) ? (int)$_GET["limit"] : 20;
if ($limit <= 0 || $limit > 100) $limit = 20;

try {
  $activities = [];

  // New users
  $stmt = $conn->prepare("
    SELECT user_id, role, created_at
    FROM users
    ORDER BY created_at DESC
    LIMIT ?
  ");
  $stmt->bind_param("i", $limit);
  $stmt->execute();
  $res = $stmt->get_result();
  while ($row = $res->fetch_assoc()) {
    $id = (int)$row["user_id"];
    $activities[] = [
      "type" => "user",
      "id" => $id,
      "title" => "New user #$id",
      "subtitle" => "Role: " . $row["role"],
      "time" => $row["created_at"]
    ];
  }
  $stmt->close();

  // New bookings
  $stmt = $conn->prepare("
    SELECT booking_id, status, created_at
    FROM bookings
    ORDER BY created_at DESC
    LIMIT ?
  ");
  $stmt->bind_param("i", $limit);
  $stmt->execute();
  $res = $stmt->get_result();
  while ($row = $res->fetch_assoc()) {
    $id = (int)$row["booking_id"];
    $activities[] = [
      "type" => "booking",
      "id" => $id,
      "title" => "Booking #$id",
      "subtitle" => "Status: " . $row["status"],
      "time" => $row["created_at"]
    ];
  }
  $stmt->close();

  // sort newest
  usort($activities, function($a, $b) {
    return strcmp($b["time"], $a["time"]);
  });

  respond(["activities" => array_slice($activities, 0, $limit)]);
} catch (Exception $e) {
  respond(["error" => "Failed to load admin activities", "details" => $e->getMessage()], 500);
}
