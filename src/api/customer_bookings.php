<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/db.php';

$customer_id = request_param('customer_id', '');
$type = $_GET['type'] ?? 'all';
$pagination = pagination_params(50, 100);
$limit = (int)$pagination["limit"];
$offset = (int)$pagination["offset"];

if (empty($customer_id) || !is_numeric($customer_id) || (int)$customer_id <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "customer_id is required"
    ]);
    $conn->close();
    exit;
}

$customer_id = (int)$customer_id;

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
LIMIT $limit OFFSET $offset
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

$stmt->bind_param("i", $customer_id);

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
    "data" => $bookings,
    "pagination" => pagination_payload(count($bookings), $pagination)
]);

$stmt->close();
$conn->close();
?>
