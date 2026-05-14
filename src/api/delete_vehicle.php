<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/db.php';

require_post();

$car_id = isset($_POST['car_id']) ? (int)$_POST['car_id'] : 0;
$customer_id = isset($_POST['customer_id']) ? (int)$_POST['customer_id'] : 0;

if ($car_id <= 0) {
    json_response([
        'status' => 'error',
        'message' => 'Missing car_id'
    ], 400);
}

$check_stmt = $conn->prepare("SELECT car_id, customer_id, brand, model FROM customer_cars WHERE car_id = ? LIMIT 1");
$check_stmt->bind_param("i", $car_id);
$check_stmt->execute();
$result = $check_stmt->get_result();

if ($result->num_rows === 0) {
    $check_stmt->close();
    json_response([
        'status' => 'error',
        'message' => 'Vehicle not found'
    ], 404);
}

$vehicle = $result->fetch_assoc();
$check_stmt->close();

if ($customer_id > 0 && (int)$vehicle['customer_id'] !== $customer_id) {
    json_response([
        'status' => 'error',
        'message' => 'This vehicle does not belong to you'
    ], 403);
}

$booking_stmt = $conn->prepare("SELECT booking_id FROM bookings WHERE car_id = ? LIMIT 1");
$booking_stmt->bind_param("i", $car_id);
$booking_stmt->execute();
$booking_result = $booking_stmt->get_result();

if ($booking_result->num_rows > 0) {
    $booking_stmt->close();
    json_response([
        'status' => 'error',
        'message' => 'Vehicle cannot be deleted because it has bookings'
    ], 409);
}
$booking_stmt->close();

$stmt = $conn->prepare("DELETE FROM customer_cars WHERE car_id = ?");
$stmt->bind_param("i", $car_id);

if (!$stmt->execute()) {
    error_log("Delete vehicle failed for car $car_id");
    $stmt->close();
    json_response([
        'status' => 'error',
        'message' => 'Failed to delete vehicle'
    ], 500);
}

$stmt->close();
json_response([
    'status' => 'success',
    'message' => "Vehicle {$vehicle['brand']} {$vehicle['model']} deleted successfully"
]);
?>
