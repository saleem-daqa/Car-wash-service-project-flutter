<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once 'db.php';

$car_id = isset($_POST['car_id']) ? intval($_POST['car_id']) : 0;

if ($car_id === 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Missing car_id'
    ]);
    $conn->close();
    exit;
}

$check_stmt = $conn->prepare("SELECT car_id, brand, model FROM customer_cars WHERE car_id = ?");
$check_stmt->bind_param("i", $car_id);
$check_stmt->execute();
$result = $check_stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Vehicle not found'
    ]);
    $check_stmt->close();
    $conn->close();
    exit;
}

$vehicle = $result->fetch_assoc();
$check_stmt->close();

$stmt = $conn->prepare("DELETE FROM customer_cars WHERE car_id = ?");
if (!$stmt) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Prepare failed: ' . $conn->error
    ]);
    $conn->close();
    exit;
}

$stmt->bind_param("i", $car_id);
if ($stmt->execute()) {
    echo json_encode([
        'status' => 'success',
        'message' => "Vehicle {$vehicle['brand']} {$vehicle['model']} deleted successfully"
    ]);
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'Failed to delete vehicle: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>
