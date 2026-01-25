<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once 'db.php';

$booking_id = $_GET['booking_id'] ?? '';

if (empty($booking_id)) {
    echo json_encode([
        "status" => "error",
        "message" => "booking_id is required"
    ]);
    $conn->close();
    exit;
}

$sql = "
SELECT
  b.*,
  u.full_name AS customer_name,
  u.phone     AS customer_phone,
  u.email     AS customer_email,
  s.name      AS service_name,
  s.description AS service_description,
  s.duration_minutes,
  cc.plate_number AS car_plate,
  cc.brand        AS car_brand,
  cc.model        AS car_model,
  cc.color        AS car_color,
  cc.notes        AS car_notes,
  ba.assignment_id,
  ba.team_id,
  ba.employee_id,
  ba.assigned_by,
  ba.assigned_at,
  ba.started_at,
  ba.finished_at,
  e.full_name AS employee_name,
  t.name AS team_name
FROM bookings b
JOIN users u           ON u.user_id = b.customer_id
JOIN services s        ON s.service_id = b.service_id
JOIN customer_cars cc  ON cc.car_id = b.car_id
LEFT JOIN booking_assignments ba ON ba.booking_id = b.booking_id
LEFT JOIN users e ON ba.employee_id = e.user_id
LEFT JOIN teams t ON ba.team_id = t.team_id
WHERE b.booking_id = ?
LIMIT 1
";

$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode([
        "status" => "error",
        "message" => "Prepare failed",
        "error" => $conn->error
    ]);
    $conn->close();
    exit;
}

$stmt->bind_param("i", $booking_id);

if (!$stmt->execute()) {
    echo json_encode([
        "status" => "error",
        "message" => "Execute failed",
        "error" => $stmt->error
    ]);
    $stmt->close();
    $conn->close();
    exit;
}

$result = $stmt->get_result();
$job = $result->fetch_assoc();

if ($job) {
    echo json_encode([
        "status" => "success",
        "job" => $job
    ]);
} else {
    echo json_encode([
        "status" => "error",
        "message" => "Booking not found"
    ]);
}

$stmt->close();
$conn->close();
?>
