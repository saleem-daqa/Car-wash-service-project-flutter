<?php
error_reporting(0);
ini_set('display_errors', 0);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json; charset=UTF-8');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'db.php';

$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
$plate_number = trim($_POST['plate_number'] ?? '');
$car_model = trim($_POST['car_model'] ?? '');
$brand = trim($_POST['car_brand'] ?? '');

if (!$user_id || !$plate_number || !$car_model) {
    echo json_encode(['status' => 'error', 'message' => 'Missing required fields']);
    exit();
}

try {
    $stmt = $conn->prepare(
        "INSERT INTO customer_cars (customer_id, plate_number, brand, model)
         VALUES (?, ?, ?, ?)"
    );
    $stmt->bind_param("isss", $user_id, $plate_number, $brand, $car_model);
    
    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Registration completed successfully']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to insert car details: ' . $stmt->error]);
    }
    
    $stmt->close();
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => 'Database error: ' . $e->getMessage()]);
}

$conn->close();
?>
