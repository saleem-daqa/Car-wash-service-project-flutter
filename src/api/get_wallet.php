<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once 'db.php';

$customer_id = $_GET['customer_id'] ?? $_POST['customer_id'] ?? $_GET['user_id'] ?? $_POST['user_id'] ?? 0;

if ($customer_id == 0) {
    echo json_encode([
        "status" => "error",
        "message" => "customer_id is required"
    ]);
    $conn->close();
    exit;
}

$stmt = $conn->prepare("SELECT balance, points FROM wallets WHERE customer_id = ? LIMIT 1");

if (!$stmt) {
    echo json_encode([
        "status" => "error",
        "message" => "Prepare failed",
    ]);
    $conn->close();
    exit;
}

$stmt->bind_param("i", $customer_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    $stmt->close();
    
    $insert_stmt = $conn->prepare("INSERT INTO wallets (customer_id, balance, points) VALUES (?, 0.00, 0)");
    $insert_stmt->bind_param("i", $customer_id);
    $insert_stmt->execute();
    $insert_stmt->close();
    
    echo json_encode([
        "status" => "success",
        "balance" => 0.00,
        "points" => 0
    ]);
} else {
    $row = $result->fetch_assoc();
    echo json_encode([
        "status" => "success",
        "balance" => (float)$row["balance"],
        "points" => (int)$row["points"]
    ]);
}

$stmt->close();
$conn->close();
?>
