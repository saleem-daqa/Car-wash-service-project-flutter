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

$customer_id = isset($_POST['customer_id']) ? (int)$_POST['customer_id'] : 0;
$plate_number = strtoupper(clean($_POST['plate_number'] ?? ''));
$type = clean($_POST['type'] ?? 'Car/Sedan');
$brand = clean($_POST['car_brand'] ?? $_POST['brand'] ?? '');
$model = clean($_POST['car_model'] ?? $_POST['model'] ?? '');
$color = clean($_POST['color'] ?? '');
$notes = clean($_POST['notes'] ?? '');

if ($customer_id <= 0 || $plate_number === '' || $brand === '' || $model === '') {
    json_response([
        'status' => 'error',
        'message' => 'Missing required fields (customer_id, plate_number, brand, model)'
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

$customer_stmt = $conn->prepare("SELECT user_id FROM users WHERE user_id = ? AND role = 'CUSTOMER' AND is_active = 1 LIMIT 1");
$customer_stmt->bind_param("i", $customer_id);
$customer_stmt->execute();
$customer = $customer_stmt->get_result()->fetch_assoc();
$customer_stmt->close();

if (!$customer) {
    json_response([
        'status' => 'error',
        'message' => 'Customer not found'
    ], 404);
}

$check_stmt = $conn->prepare("SELECT car_id FROM customer_cars WHERE customer_id = ? AND plate_number = ? LIMIT 1");
$check_stmt->bind_param("is", $customer_id, $plate_number);
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

$insert_stmt = $conn->prepare("
    INSERT INTO customer_cars (customer_id, plate_number, type, brand, model, color, notes)
    VALUES (?, ?, ?, ?, ?, ?, ?)
");
$insert_stmt->bind_param("issssss", $customer_id, $plate_number, $type, $brand, $model, $color, $notes);

if (!$insert_stmt->execute()) {
    error_log("Create vehicle failed for customer $customer_id");
    $insert_stmt->close();
    json_response([
        'status' => 'error',
        'message' => 'Failed to create vehicle'
    ], 500);
}

$car_id = (int)$insert_stmt->insert_id;
$insert_stmt->close();

json_response([
    'status' => 'success',
    'message' => 'Vehicle created successfully',
    'car_id' => $car_id
]);
?>
