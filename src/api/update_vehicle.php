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
$plate_number = strtoupper(clean($_POST['plate_number'] ?? ''));
$type = clean($_POST['type'] ?? 'Car/Sedan');
$brand = clean($_POST['car_brand'] ?? $_POST['brand'] ?? '');
$model = clean($_POST['car_model'] ?? $_POST['model'] ?? '');
$color = clean($_POST['color'] ?? '');
$notes = clean($_POST['notes'] ?? '');

if ($car_id <= 0 || $customer_id <= 0 || $plate_number === '' || $brand === '' || $model === '') {
    json_response([
        'status' => 'error',
        'message' => 'Missing required fields'
    ], 400);
}

if (strlen($plate_number) < 3 || strlen($plate_number) > 30 ||
    !preg_match('/^[A-Z0-9\-\s]+$/', $plate_number)) {
    json_response([
        'status' => 'error',
        'message' => 'Invalid plate number'
    ], 400);
}

if (strlen($brand) > 60 || strlen($model) > 60 || strlen($type) > 50) {
    json_response([
        'status' => 'error',
        'message' => 'Vehicle fields are too long'
    ], 400);
}

$owner_stmt = $conn->prepare("SELECT customer_id FROM customer_cars WHERE car_id = ? LIMIT 1");
$owner_stmt->bind_param("i", $car_id);
$owner_stmt->execute();
$owner_result = $owner_stmt->get_result();

if ($owner_result->num_rows === 0) {
    $owner_stmt->close();
    json_response([
        'status' => 'error',
        'message' => 'Vehicle not found'
    ], 404);
}

$owner_row = $owner_result->fetch_assoc();
$owner_stmt->close();

if ((int)$owner_row['customer_id'] !== $customer_id) {
    json_response([
        'status' => 'error',
        'message' => 'This vehicle does not belong to you'
    ], 403);
}

$check_stmt = $conn->prepare("SELECT car_id FROM customer_cars WHERE customer_id = ? AND plate_number = ? AND car_id != ? LIMIT 1");
$check_stmt->bind_param("isi", $customer_id, $plate_number, $car_id);
$check_stmt->execute();
$check_result = $check_stmt->get_result();

if ($check_result->num_rows > 0) {
    $check_stmt->close();
    json_response([
        'status' => 'error',
        'message' => 'This plate number already exists for your account'
    ], 409);
}
$check_stmt->close();

$update_stmt = $conn->prepare("
    UPDATE customer_cars
    SET plate_number = ?, type = ?, brand = ?, model = ?, color = ?, notes = ?
    WHERE car_id = ? AND customer_id = ?
");
$update_stmt->bind_param("ssssssii", $plate_number, $type, $brand, $model, $color, $notes, $car_id, $customer_id);

if (!$update_stmt->execute()) {
    error_log("Update vehicle failed for car $car_id");
    $update_stmt->close();
    json_response([
        'status' => 'error',
        'message' => 'Failed to update vehicle'
    ], 500);
}

$update_stmt->close();
json_response([
    'status' => 'success',
    'message' => 'Vehicle updated successfully',
    'car_id' => $car_id
]);
?>
