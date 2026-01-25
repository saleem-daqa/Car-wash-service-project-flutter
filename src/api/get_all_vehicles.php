<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'db.php';

$customer_id = isset($_POST['customer_id']) ? intval($_POST['customer_id']) : 0;

if ($customer_id === 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Missing customer_id'
    ]);
    exit;
}

$stmt = $conn->prepare(
    "SELECT car_id, plate_number, type, brand, model, color, notes 
     FROM customer_cars 
     WHERE customer_id = ? 
     ORDER BY created_at DESC"
);

if (!$stmt) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Prepare failed: ' . $conn->error
    ]);
    $conn->close();
    exit;
}

$stmt->bind_param("i", $customer_id);
$stmt->execute();
$result = $stmt->get_result();

$vehicles = [];
while ($row = $result->fetch_assoc()) {
    $vehicles[] = [
        'car_id' => $row['car_id'],
        'plate_number' => $row['plate_number'],
        'type' => $row['type'],
        'brand' => $row['brand'],
        'model' => $row['model'],
        'color' => $row['color'],
        'notes' => $row['notes']
    ];
}

echo json_encode([
    'status' => 'success',
    'vehicles' => $vehicles,
    'count' => count($vehicles)
]);

$stmt->close();
$conn->close();
?>
