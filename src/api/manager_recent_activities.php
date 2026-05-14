<?php
require_once "db.php";
require_once "helpers.php";

$limit = isset($_GET["limit"]) ? (int)$_GET["limit"] : 20;
if ($limit <= 0 || $limit > 100) $limit = 20;

try {
  $activities = [];

  // bookings
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

  // wallet txns
  $stmt = $conn->prepare("
    SELECT txn_id, txn_type, amount, created_at
    FROM wallet_transactions
    ORDER BY created_at DESC
    LIMIT ?
  ");
  $stmt->bind_param("i", $limit);
  $stmt->execute();
  $res = $stmt->get_result();
  while ($row = $res->fetch_assoc()) {
    $id = (int)$row["txn_id"];
    $activities[] = [
      "type" => "wallet",
      "id" => $id,
      "title" => "Wallet txn #$id",
      "subtitle" => $row["txn_type"] . " - Amount: " . (float)$row["amount"],
      "time" => $row["created_at"]
    ];
  }
  $stmt->close();

  // feedback
  $stmt = $conn->prepare("
    SELECT feedback_id, rating, created_at
    FROM ratings_feedback
    ORDER BY created_at DESC
    LIMIT ?
  ");
  $stmt->bind_param("i", $limit);
  $stmt->execute();
  $res = $stmt->get_result();
  while ($row = $res->fetch_assoc()) {
    $id = (int)$row["feedback_id"];
    $activities[] = [
      "type" => "feedback",
      "id" => $id,
      "title" => "Feedback #$id",
      "subtitle" => "Rating: " . (int)$row["rating"],
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
  respond(["error" => "Failed to load activities"], 500);
}
