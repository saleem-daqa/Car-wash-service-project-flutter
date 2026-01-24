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

$car_id = isset($_POST['car_id']) ? intval($_POST['car_id']) : 0;
$customer_id = isset($_POST['customer_id']) ? intval($_POST['customer_id']) : 0;
$plate_number = $_POST['plate_number'] ?? '';
$brand = $_POST['car_brand'] ?? $_POST['brand'] ?? '';
$model = $_POST['car_model'] ?? $_POST['model'] ?? '';
$color = $_POST['color'] ?? '';
$notes = $_POST['notes'] ?? '';

if ($car_id === 0 || $customer_id === 0 || empty($plate_number) || empty($brand) || empty($model)) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Missing required fields'
    ]);
    exit;
}

$owner_stmt = $conn->prepare("SELECT customer_id FROM customer_cars WHERE car_id = ?");
$owner_stmt->bind_param("i", $car_id);
$owner_stmt->execute();
$owner_result = $owner_stmt->get_result();

if ($owner_result->num_rows === 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Vehicle not found'
    ]);
    $owner_stmt->close();
    $conn->close();
    exit;
}

$owner_row = $owner_result->fetch_assoc();
if ($owner_row['customer_id'] !== $customer_id) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Unauthorized: This vehicle does not belong to you'
    ]);
    $owner_stmt->close();
    $conn->close();
    exit;
}
$owner_stmt->close();

$check_stmt = $conn->prepare("SELECT car_id FROM customer_cars WHERE customer_id = ? AND plate_number = ? AND car_id != ?");
$check_stmt->bind_param("isi", $customer_id, $plate_number, $car_id);
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

$update_stmt = $conn->prepare(
    "UPDATE customer_cars 
     SET plate_number = ?, brand = ?, model = ?, color = ?, notes = ? 
     WHERE car_id = ? AND customer_id = ?"
);

if (!$update_stmt) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Prepare failed: ' . $conn->error
    ]);
    $conn->close();
    exit;
}

$update_stmt->bind_param("sssssii", $plate_number, $brand, $model, $color, $notes, $car_id, $customer_id);

if ($update_stmt->execute()) {
    echo json_encode([
        'status' => 'success',
        'message' => 'Vehicle updated successfully',
        'car_id' => $car_id
    ]);
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'Failed to update vehicle: ' . $update_stmt->error
    ]);
}

$update_stmt->close();
$conn->close();
?>
