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

$customer_id = $_GET['customer_id'] ?? '';
$type = $_GET['type'] ?? 'all';

if (empty($customer_id)) {
    echo json_encode([
        "status" => "error",
        "message" => "customer_id is required"
    ]);
    $conn->close();
    exit;
}

$statusFilter = "";
if ($type === 'current') {
    $statusFilter = " AND b.status NOT IN ('COMPLETED', 'CANCELLED')";
} elseif ($type === 'past') {
    $statusFilter = " AND b.status IN ('COMPLETED', 'CANCELLED')";
}

$sql = "
SELECT
  b.booking_id,
  b.status,
  b.address_text,
  b.scheduled_at,
  b.payment_method,
  b.price_total,
  b.created_at,
  s.name AS service_name,
  s.description AS service_description,
  cc.plate_number,
  cc.brand,
  cc.model,
  cc.type AS car_type
FROM bookings b
JOIN services s ON b.service_id = s.service_id
JOIN customer_cars cc ON b.car_id = cc.car_id
WHERE b.customer_id = ? $statusFilter
ORDER BY b.created_at DESC
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

$stmt->bind_param("i", $customer_id);

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
$bookings = [];

while ($row = $result->fetch_assoc()) {
    $bookings[] = [
        "booking_id" => (int)$row["booking_id"],
        "status" => $row["status"],
        "address" => $row["address_text"] ?? '',
        "scheduled_at" => $row["scheduled_at"],
        "payment_method" => $row["payment_method"] ?? 'cash',
        "price" => (float)$row["price_total"],
        "created_at" => $row["created_at"],
        "service_name" => $row["service_name"],
        "service_description" => $row["service_description"] ?? '',
        "car" => [
            "plate_number" => $row["plate_number"],
            "brand" => $row["brand"],
            "model" => $row["model"],
            "type" => $row["car_type"] ?? ''
        ]
    ];
}

echo json_encode([
    "status" => "success",
    "data" => $bookings
]);

$stmt->close();
$conn->close();
?>
