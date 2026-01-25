<?php
require_once "db.php";
require_once "helpers.php";

try {
  $usersTotal = (int)$conn->query("SELECT COUNT(*) c FROM users")->fetch_assoc()["c"];
  $customers = (int)$conn->query("SELECT COUNT(*) c FROM users WHERE role='CUSTOMER'")->fetch_assoc()["c"];
  $employees = (int)$conn->query("SELECT COUNT(*) c FROM users WHERE role='EMPLOYEE'")->fetch_assoc()["c"];
  $managers  = (int)$conn->query("SELECT COUNT(*) c FROM users WHERE role='MANAGER'")->fetch_assoc()["c"];

  $teamsTotal = (int)$conn->query("SELECT COUNT(*) c FROM teams")->fetch_assoc()["c"];
  $activeTeams = (int)$conn->query("SELECT COUNT(*) c FROM teams WHERE is_active=1")->fetch_assoc()["c"];

  $bookingsTotal = (int)$conn->query("SELECT COUNT(*) c FROM bookings")->fetch_assoc()["c"];
  $completedBookings = (int)$conn->query("SELECT COUNT(*) c FROM bookings WHERE status='COMPLETED'")->fetch_assoc()["c"];

  $servicesTotal = (int)$conn->query("SELECT COUNT(*) c FROM services")->fetch_assoc()["c"];
  $activeServices = (int)$conn->query("SELECT COUNT(*) c FROM services WHERE is_active=1")->fetch_assoc()["c"];

  respond([
    "users_total" => $usersTotal,
    "customers" => $customers,
    "employees" => $employees,
    "managers" => $managers,
    "teams_total" => $teamsTotal,
    "active_teams" => $activeTeams,
    "bookings_total" => $bookingsTotal,
    "completed_bookings" => $completedBookings,
    "services_total" => $servicesTotal,
    "active_services" => $activeServices
  ]);
} catch (Exception $e) {
  respond(["error" => "Failed to load admin stats", "details" => $e->getMessage()], 500);
}
