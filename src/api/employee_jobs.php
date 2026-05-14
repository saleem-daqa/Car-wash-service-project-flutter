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

$employee_id = $_GET['employee_id'] ?? '';

if (empty($employee_id)) {
    echo json_encode([
        "status" => "error",
        "message" => "employee_id is required"
    ]);
    $conn->close();
    exit;
}

$sql = "
SELECT
  b.booking_id,
  b.status,
  b.address_text,
  b.scheduled_at,
  s.name AS service_name,
  cc.plate_number,
  cc.brand,
  cc.model
FROM booking_assignments ba
JOIN bookings b ON ba.booking_id = b.booking_id
JOIN services s ON b.service_id = s.service_id
JOIN customer_cars cc ON b.car_id = cc.car_id
WHERE ba.employee_id = ?
ORDER BY b.created_at DESC
";

$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode([
        "status" => "error",
        "message" => "Prepare failed",
    ]);
    $conn->close();
    exit;
}

$stmt->bind_param("i", $employee_id);

if (!$stmt->execute()) {
    echo json_encode([
        "status" => "error",
        "message" => "Execute failed",
    ]);
    $stmt->close();
    $conn->close();
    exit;
}

$result = $stmt->get_result();
$jobs = [];

while ($row = $result->fetch_assoc()) {
    $jobs[] = [
        "booking_id"   => (int)$row["booking_id"],
        "status"       => $row["status"],
        "address"      => $row["address_text"],
        "scheduled_at" => $row["scheduled_at"],
        "service_name" => $row["service_name"],
        "car" => [
            "plate_number" => $row["plate_number"],
            "brand"        => $row["brand"],
            "model"        => $row["model"]
        ]
    ];
}

echo json_encode([
    "status" => "success",
    "data" => $jobs
]);

$stmt->close();
$conn->close();
?>
