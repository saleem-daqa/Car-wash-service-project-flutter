<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

$servername = "localhost";
$username = "root";
$password = "1234";
$dbname = "car_wash_db";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'DB connection failed']);
    exit();
}

$user_id = $_POST['user_id'] ?? '';
$phone = $_POST['phone'] ?? '';
$plate_number = $_POST['plate_number'] ?? '';
$car_model = $_POST['car_model'] ?? '';

if (!$user_id || !$phone || !$plate_number || !$car_model) {
    echo json_encode(['status' => 'error', 'message' => 'Missing required fields']);
    exit();
}

$stmt = $conn->prepare("UPDATE users SET phone = ? WHERE user_id = ?");
if (!$stmt) {
    echo json_encode(['status' => 'error', 'message' => 'Prepare failed for phone update']);
    exit();
}
$stmt->bind_param("si", $phone, $user_id);
if (!$stmt->execute()) {
    echo json_encode(['status' => 'error', 'message' => 'Failed to update phone']);
    $stmt->close();
    $conn->close();
    exit();
}
$stmt->close();

$brand = $_POST['car_brand'] ?? '';

$stmt = $conn->prepare(
    "INSERT INTO customer_cars (customer_id, plate_number, brand, model)
     VALUES (?, ?, ?, ?)"
);
$stmt->bind_param("isss", $user_id, $plate_number, $brand, $car_model);
if ($stmt->execute()) {
    echo json_encode(['status' => 'success']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Failed to insert car details']);
}

$stmt->close();
$conn->close();
?>
