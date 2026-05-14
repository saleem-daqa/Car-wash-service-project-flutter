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

$customer_id = $_POST['customer_id'] ?? $_POST['user_id'] ?? 0;

if ($customer_id == 0) {
    echo json_encode([
        "status" => "error",
        "message" => "customer_id is required"
    ]);
    $conn->close();
    exit;
}

$conn->begin_transaction();

try {
    $stmt = $conn->prepare("SELECT balance, points FROM wallets WHERE customer_id = ? FOR UPDATE");
    $stmt->bind_param("i", $customer_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        $stmt->close();
        throw new Exception("Wallet not found");
    }
    
    $wallet = $result->fetch_assoc();
    $currentPoints = (int)$wallet["points"];
    $currentBalance = (float)$wallet["balance"];
    
    if ($currentPoints == 0) {
        $stmt->close();
        throw new Exception("You have no points to convert");
    }
    
    // 5 points = 1 NIS
    $pointsToNisRate = 0.2;
    $convertedAmount = $currentPoints * $pointsToNisRate;
    $newBalance = $currentBalance + $convertedAmount;
    
    $update_stmt = $conn->prepare("UPDATE wallets SET balance = ?, points = 0 WHERE customer_id = ?");
    $update_stmt->bind_param("di", $newBalance, $customer_id);
    $update_stmt->execute();
    $update_stmt->close();
    
    $txn_stmt = $conn->prepare("INSERT INTO wallet_transactions (customer_id, txn_type, amount, points_used, note) VALUES (?, 'POINTS_CONVERTED', ?, ?, ?)");
    $note = "Converted $currentPoints points to " . number_format($convertedAmount, 2) . " NIS";
    $txn_stmt->bind_param("idss", $customer_id, $convertedAmount, $currentPoints, $note);
    $txn_stmt->execute();
    $txn_stmt->close();
    
    $conn->commit();
    
    echo json_encode([
        "status" => "success",
        "message" => "Points converted successfully",
        "converted_amount" => $convertedAmount,
        "new_balance" => $newBalance,
        "points_converted" => $currentPoints
    ]);
    
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode([
        "status" => "error",
        "message" => "Operation failed"
    ]);
}

$conn->close();
?>
