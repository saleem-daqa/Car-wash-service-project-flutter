<?php
error_reporting(0);
ini_set('display_errors', 0);

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

$user_id = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;
$plate_number = strtoupper(clean($_POST['plate_number'] ?? ''));
$car_model = clean($_POST['car_model'] ?? '');
$brand = clean($_POST['car_brand'] ?? '');

if ($user_id <= 0 || $plate_number === '' || $brand === '' || $car_model === '') {
    json_response(['status' => 'error', 'message' => 'Missing required fields'], 400);
}

if (strlen($plate_number) < 3 || strlen($plate_number) > 30 ||
    !preg_match('/^[A-Z0-9\-\s]+$/', $plate_number)) {
    json_response(['status' => 'error', 'message' => 'Invalid plate number'], 400);
}

$customer_stmt = $conn->prepare("SELECT user_id FROM users WHERE user_id = ? AND role = 'CUSTOMER' AND is_active = 1 LIMIT 1");
$customer_stmt->bind_param("i", $user_id);
$customer_stmt->execute();
$customer = $customer_stmt->get_result()->fetch_assoc();
$customer_stmt->close();

if (!$customer) {
    json_response(['status' => 'error', 'message' => 'Customer not found'], 404);
}

$duplicate_stmt = $conn->prepare("SELECT car_id FROM customer_cars WHERE customer_id = ? AND plate_number = ? LIMIT 1");
$duplicate_stmt->bind_param("is", $user_id, $plate_number);
$duplicate_stmt->execute();
$duplicate = $duplicate_stmt->get_result()->fetch_assoc();
$duplicate_stmt->close();

if ($duplicate) {
    json_response(['status' => 'error', 'message' => 'This plate number already exists for your account'], 409);
}

try {
    $stmt = $conn->prepare("
        INSERT INTO customer_cars (customer_id, plate_number, brand, model)
        VALUES (?, ?, ?, ?)
    ");
    $stmt->bind_param("isss", $user_id, $plate_number, $brand, $car_model);

    if (!$stmt->execute()) {
        throw new RuntimeException('Insert failed');
    }

    $stmt->close();
    json_response(['status' => 'success', 'message' => 'Registration completed successfully']);
} catch (Throwable $e) {
    error_log('Complete registration failed: ' . $e->getMessage());
    json_response(['status' => 'error', 'message' => 'Could not complete registration'], 500);
}
?>
