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

$pagination = pagination_params(50, 100);
$limit = (int)$pagination["limit"];
$offset = (int)$pagination["offset"];
$allowedStatuses = ['PENDING', 'CONFIRMED', 'ASSIGNED', 'IN_PROGRESS'];
$status = strtoupper(trim((string)request_param('status', '')));
$search = trim((string)request_param('search', ''));

$where = ["b.status IN ('CONFIRMED', 'ASSIGNED', 'IN_PROGRESS', 'PENDING')"];
$types = "";
$params = [];

if (in_array($status, $allowedStatuses, true)) {
  $where[] = "b.status = ?";
  $types .= "s";
  $params[] = $status;
}

if ($search !== '') {
  $like = "%" . $search . "%";
  $where[] = "(u.full_name LIKE ? OR u.phone LIKE ? OR cc.plate_number LIKE ? OR s.name LIKE ?)";
  $types .= "ssss";
  $params[] = $like;
  $params[] = $like;
  $params[] = $like;
  $params[] = $like;
}

$whereSql = "WHERE " . implode(" AND ", $where);

$sql = "
SELECT
  b.booking_id,
  b.status,
  b.address_text,
  b.latitude,
  b.longitude,
  b.scheduled_at,
  b.payment_method,
  s.name AS service_name,
  cc.plate_number,
  cc.brand,
  cc.model,
  u.full_name AS customer_name,
  u.phone AS customer_phone,
  ba.employee_id,
  ba.team_id,
  e.full_name AS employee_name,
  t.name AS team_name
FROM bookings b
JOIN services s ON b.service_id = s.service_id
JOIN customer_cars cc ON b.car_id = cc.car_id
JOIN users u ON b.customer_id = u.user_id
LEFT JOIN booking_assignments ba ON ba.booking_id = b.booking_id
LEFT JOIN users e ON ba.employee_id = e.user_id
LEFT JOIN teams t ON ba.team_id = t.team_id
$whereSql
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

bind_statement_params($stmt, $types, $params);
$stmt->execute();
$result = $stmt->get_result();

$bookings = [];

while ($row = $result->fetch_assoc()) {
    $bookings[] = [
        "booking_id"   => (int)$row["booking_id"],
        "status"       => $row["status"],
        "address"      => $row["address_text"],
        "address_text" => $row["address_text"],
        "latitude"     => (float)$row["latitude"],
        "longitude"    => (float)$row["longitude"],
        "scheduled_at" => $row["scheduled_at"],
        "payment_method" => $row["payment_method"] ?? 'cash',
        "service_name" => $row["service_name"],
        "customer_name" => $row["customer_name"],
        "customer_phone" => $row["customer_phone"],
        "car" => [
            "plate_number" => $row["plate_number"],
            "brand"        => $row["brand"],
            "model"        => $row["model"]
        ],
        "employee_id" => $row["employee_id"] ? (int)$row["employee_id"] : null,
        "employee_name" => $row["employee_name"] ?? null,
        "team_id" => $row["team_id"] ? (int)$row["team_id"] : null,
        "team_name" => $row["team_name"] ?? null
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
