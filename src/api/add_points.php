<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once 'db.php';

$customer_id = $_POST['customer_id'] ?? 0;
$booking_id = $_POST['booking_id'] ?? 0;
$service_name = $_POST['service_name'] ?? '';

if ($customer_id == 0 || $booking_id == 0 || empty($service_name)) {
    echo json_encode([
        "status" => "error",
        "message" => "customer_id, booking_id, and service_name are required"
    ]);
    $conn->close();
    exit;
}

$pointsMap = [
    'Basic Wash' => 1,
    'Deluxe Wash' => 2,
    'Premium Wash' => 3
];

$pointsToAdd = $pointsMap[$service_name] ?? 1;

$conn->begin_transaction();

try {
    $stmt = $conn->prepare("SELECT points FROM wallets WHERE customer_id = ? FOR UPDATE");
    $stmt->bind_param("i", $customer_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        $stmt->close();
        $insert_stmt = $conn->prepare("INSERT INTO wallets (customer_id, balance, points) VALUES (?, 0.00, ?)");
        $insert_stmt->bind_param("ii", $customer_id, $pointsToAdd);
        $insert_stmt->execute();
        $insert_stmt->close();
    } else {
        $wallet = $result->fetch_assoc();
        $newPoints = (int)$wallet["points"] + $pointsToAdd;
        $stmt->close();
        
        $update_stmt = $conn->prepare("UPDATE wallets SET points = ? WHERE customer_id = ?");
        $update_stmt->bind_param("ii", $newPoints, $customer_id);
        $update_stmt->execute();
        $update_stmt->close();
    }
    
    $txn_stmt = $conn->prepare("INSERT INTO wallet_transactions (customer_id, booking_id, txn_type, points_earned, note) VALUES (?, ?, 'POINTS_EARNED', ?, ?)");
    $note = "Earned $pointsToAdd points from $service_name";
    $txn_stmt->bind_param("iiis", $customer_id, $booking_id, $pointsToAdd, $note);
    $txn_stmt->execute();
    $txn_stmt->close();
    
    $conn->commit();
    
    echo json_encode([
        "status" => "success",
        "message" => "Points added successfully",
        "points_added" => $pointsToAdd
    ]);
    
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}

$conn->close();
?>
