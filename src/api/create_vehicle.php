<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

$conn = new mysqli("localhost", "root", "1234", "car_wash_db");

if ($conn->connect_error) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Database connection failed'
    ]);
    exit;
}

$customer_id = isset($_POST['customer_id']) ? intval($_POST['customer_id']) : 0;
$plate_number = $_POST['plate_number'] ?? '';
$brand = $_POST['car_brand'] ?? $_POST['brand'] ?? '';
$model = $_POST['car_model'] ?? $_POST['model'] ?? '';
$color = $_POST['color'] ?? '';
$notes = $_POST['notes'] ?? '';

if ($customer_id === 0 || empty($plate_number) || empty($brand) || empty($model)) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Missing required fields (customer_id, plate_number, brand, model)'
    ]);
    exit;
}

// Check if plate number already exists for this customer
$check_stmt = $conn->prepare("SELECT car_id FROM customer_cars WHERE customer_id = ? AND plate_number = ?");
$check_stmt->bind_param("is", $customer_id, $plate_number);
$check_stmt->execute();
$check_result = $check_stmt->get_result();

if ($check_result->num_rows > 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'This plate number already exists for your account'
    ]);
    $check_stmt->close();
    $conn->close();
    exit;
}
$check_stmt->close();

$insert_stmt = $conn->prepare(
    "INSERT INTO customer_cars (customer_id, plate_number, brand, model, color, notes) 
     VALUES (?, ?, ?, ?, ?, ?)"
);

if (!$insert_stmt) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Prepare failed: ' . $conn->error
    ]);
    $conn->close();
    exit;
}

$insert_stmt->bind_param("isssss", $customer_id, $plate_number, $brand, $model, $color, $notes);

if ($insert_stmt->execute()) {
    echo json_encode([
        'status' => 'success',
        'message' => 'Vehicle created successfully',
        'car_id' => $insert_stmt->insert_id
    ]);
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'Failed to create vehicle: ' . $insert_stmt->error
    ]);
}

$insert_stmt->close();
$conn->close();
?>