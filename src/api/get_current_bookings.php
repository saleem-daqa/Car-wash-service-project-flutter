<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/db.php';

$user_id = request_param('user_id', 0);
$pagination = pagination_params(50, 100);
$limit = (int)$pagination["limit"];
$offset = (int)$pagination["offset"];

if (!is_numeric($user_id) || (int)$user_id <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "User ID missing"
    ]);
    $conn->close();
    exit;
}

$user_id = (int)$user_id;

$sql = "SELECT 
            b.booking_id AS id,
            s.name AS service_name,
            DATE(b.scheduled_at) AS booking_date,
            TIME_FORMAT(b.scheduled_at, '%H:%i') AS booking_time,
            cc.plate_number AS vehicle_plate,
            b.price_total AS price,
            b.status
        FROM bookings b
        JOIN services s ON b.service_id = s.service_id
        JOIN customer_cars cc ON b.car_id = cc.car_id
        WHERE b.customer_id = ?
        AND b.status IN ('PENDING', 'CONFIRMED', 'ASSIGNED', 'IN_PROGRESS')
        ORDER BY b.scheduled_at DESC
        LIMIT $limit OFFSET $offset";

$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode([
        "status" => "error",
        "message" => "Prepare failed",
    ]);
    $conn->close();
    exit;
}

$stmt->bind_param("i", $user_id);

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
        "id" => (int)$row["id"],
        "service_name" => $row["service_name"],
        "booking_date" => $row["booking_date"],
        "booking_time" => $row["booking_time"],
        "vehicle_plate" => $row["vehicle_plate"],
        "price" => (float)$row["price"],
        "status" => $row["status"]
    ];
}

echo json_encode([
    "status" => "success",
    "bookings" => $bookings,
    "pagination" => pagination_payload(count($bookings), $pagination)
]);

$stmt->close();
$conn->close();
?>
