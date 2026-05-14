<?php
require_once "db.php";
require_once "helpers.php";

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

try {
  $services = [
    [
      'name' => 'Basic Wash',
      'description' => 'Complete exterior hand wash with premium soap, thorough tire cleaning and shining, wheel wells cleaned, windows wiped, and quick interior wipe-down',
      'price' => 15.00,
      'duration_minutes' => 30
    ],
    [
      'name' => 'Deluxe Wash',
      'description' => 'Everything in Basic plus full interior vacuuming, dashboard and console cleaning, leather conditioning, tire dressing, and wax protection for lasting shine',
      'price' => 25.00,
      'duration_minutes' => 45
    ],
    [
      'name' => 'Premium Wash',
      'description' => 'Complete Deluxe service plus engine bay cleaning, undercarriage wash, clay bar treatment, premium wax application, and interior detailing with odor elimination',
      'price' => 40.00,
      'duration_minutes' => 60
    ]
  ];

  $created = [];
  $skipped = [];

  foreach ($services as $service) {
    $check = $conn->prepare("SELECT service_id FROM services WHERE name = ? LIMIT 1");
    $check->bind_param("s", $service['name']);
    $check->execute();
    $exists = $check->get_result()->fetch_assoc();
    $check->close();

    if ($exists) {
      $skipped[] = $service['name'];
      continue;
    }

    $stmt = $conn->prepare("INSERT INTO services (name, description, price, duration_minutes, is_active) VALUES (?, ?, ?, ?, 1)");
    $stmt->bind_param("ssdi", $service['name'], $service['description'], $service['price'], $service['duration_minutes']);
    $stmt->execute();
    $stmt->close();

    $created[] = $service['name'];
  }

  echo json_encode([
    "status" => "success",
    "created" => $created,
    "skipped" => $skipped,
    "message" => "Default services processed"
  ]);
} catch (Exception $e) {
  http_response_code(500);
  echo json_encode([
    "status" => "error",
    "message" => "Operation failed"
  ]);
}
