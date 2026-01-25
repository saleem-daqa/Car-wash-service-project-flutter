<?php
require_once "db.php";
require_once "helpers.php";

try {
  // Total bookings
  $q = $conn->query("SELECT COUNT(*) AS c FROM bookings");
  $totalBookings = (int)$q->fetch_assoc()["c"];

  // Bookings by status
  $byStatus = [];
  $q = $conn->query("SELECT status, COUNT(*) AS c FROM bookings GROUP BY status");
  while ($row = $q->fetch_assoc()) {
    $byStatus[] = ["status" => $row["status"], "count" => (int)$row["c"]];
  }

  // Services
  $q = $conn->query("SELECT COUNT(*) AS c FROM services");
  $totalServices = (int)$q->fetch_assoc()["c"];

  $q = $conn->query("SELECT COUNT(*) AS c FROM services WHERE is_active = 1");
  $activeServices = (int)$q->fetch_assoc()["c"];

  // Active employees
  $stmt = $conn->prepare("SELECT COUNT(*) AS c FROM users WHERE role='EMPLOYEE' AND is_active=1");
  $stmt->execute();
  $activeEmployees = (int)$stmt->get_result()->fetch_assoc()["c"];
  $stmt->close();

  // Wallet totals
  $q = $conn->query("SELECT COALESCE(SUM(amount),0) AS s FROM wallet_transactions WHERE txn_type='RECHARGE'");
  $totalRecharge = (float)$q->fetch_assoc()["s"];

  $q = $conn->query("SELECT COALESCE(SUM(amount),0) AS s FROM wallet_transactions WHERE txn_type='PAYMENT'");
  $totalWalletPayments = (float)$q->fetch_assoc()["s"];

  // Total Revenue - sum of all completed booking payments
  $q = $conn->query("SELECT COALESCE(SUM(price_total),0) AS s FROM bookings WHERE status='COMPLETED'");
  $totalRevenue = (float)$q->fetch_assoc()["s"];

  // Ratings
  $q = $conn->query("SELECT COALESCE(AVG(rating),0) AS avg_rating, COUNT(*) AS c FROM ratings_feedback");
  $r = $q->fetch_assoc();
  $avgRating = (float)$r["avg_rating"];
  $ratingCount = (int)$r["c"];

  respond([
    "total_bookings" => $totalBookings,
    "bookings_by_status" => $byStatus,
    "total_services" => $totalServices,
    "active_services" => $activeServices,
    "active_employees" => $activeEmployees,
    "total_recharge" => $totalRecharge,
    "total_wallet_payments" => $totalWalletPayments,
    "total_revenue" => $totalRevenue,
    "avg_rating" => $avgRating,
    "rating_count" => $ratingCount
  ]);
} catch (Exception $e) {
  respond(["error" => "Failed to load manager stats", "details" => $e->getMessage()], 500);
}
