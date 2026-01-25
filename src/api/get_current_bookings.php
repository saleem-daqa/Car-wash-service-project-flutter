<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

include "db.php";

$user_id = $_POST['user_id'] ?? 0;

if ($user_id == 0) {
    echo json_encode([
        "status" => "error",
        "message" => "User ID missing"
    ]);
    exit;
}

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
        ORDER BY b.scheduled_at DESC";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$bookings = [];

while ($row = $result->fetch_assoc()) {
    $bookings[] = $row;
}

echo json_encode([
    "status" => "success",
    "bookings" => $bookings
]);

$stmt->close();
$conn->close(); 
?>