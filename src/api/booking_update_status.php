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

$booking_id = $_POST['booking_id'] ?? '';
$action     = $_POST['action'] ?? '';

if (empty($booking_id) || empty($action)) {
    echo json_encode([
        "status" => "error",
        "message" => "booking_id and action are required"
    ]);
    $conn->close();
    exit;
}

if ($action !== 'start' && $action !== 'finish') {
    echo json_encode([
        "status" => "error",
        "message" => "action must be start or finish"
    ]);
    $conn->close();
    exit;
}

$stmt = $conn->prepare("SELECT status FROM bookings WHERE booking_id = ? LIMIT 1");

if (!$stmt) {
    echo json_encode([
        "status" => "error",
        "message" => "Prepare failed (select status)",
        "error" => $conn->error
    ]);
    $conn->close();
    exit;
}

$stmt->bind_param("i", $booking_id);

if (!$stmt->execute()) {
    echo json_encode([
        "status" => "error",
        "message" => "Execute failed (select status)",
        "error" => $stmt->error
    ]);
    $stmt->close();
    $conn->close();
    exit;
}

$res = $stmt->get_result();
$row = $res->fetch_assoc();
$stmt->close();

if (!$row) {
    echo json_encode([
        "status" => "error",
        "message" => "Booking not found"
    ]);
    $conn->close();
    exit;
}

$currentStatus = $row['status'];

if ($action === 'start' && !in_array($currentStatus, ['ASSIGNED', 'CONFIRMED'], true)) {
    echo json_encode([
        "status" => "error",
        "message" => "Cannot start from status: $currentStatus"
    ]);
    $conn->close();
    exit;
}

if ($action === 'finish' && $currentStatus !== 'IN_PROGRESS') {
    echo json_encode([
        "status" => "error",
        "message" => "Cannot finish from status: $currentStatus"
    ]);
    $conn->close();
    exit;
}

$conn->begin_transaction();

try {
    if ($action === 'start') {
        // Get employee_id from POST (employee who is starting the job)
        $employee_id = $_POST['employee_id'] ?? null;
        
        if (!$employee_id) {
            throw new Exception("employee_id is required to start a job");
        }
        
        // Check if assignment exists, if not create it
        $check_stmt = $conn->prepare("SELECT assignment_id, employee_id, team_id FROM booking_assignments WHERE booking_id = ?");
        $check_stmt->bind_param("i", $booking_id);
        $check_stmt->execute();
        $assignment_result = $check_stmt->get_result();
        $existing_assignment = $assignment_result->fetch_assoc();
        $check_stmt->close();
        
        if (!$existing_assignment) {
            // Get employee's team
            $team_stmt = $conn->prepare("SELECT team_id FROM team_members WHERE employee_id = ? LIMIT 1");
            $team_stmt->bind_param("i", $employee_id);
            $team_stmt->execute();
            $team_result = $team_stmt->get_result();
            $team_data = $team_result->fetch_assoc();
            $team_id = $team_data ? (int)$team_data['team_id'] : null;
            $team_stmt->close();
            
            // Create assignment
            $create_stmt = $conn->prepare("INSERT INTO booking_assignments (booking_id, employee_id, team_id, assigned_at, started_at) VALUES (?, ?, ?, NOW(), NOW())");
            $create_stmt->bind_param("iii", $booking_id, $employee_id, $team_id);
            if (!$create_stmt->execute()) throw new Exception("Failed to create assignment");
            $create_stmt->close();
        } else {
            // Update existing assignment with employee if not set
            if (!$existing_assignment['employee_id']) {
                $team_stmt = $conn->prepare("SELECT team_id FROM team_members WHERE employee_id = ? LIMIT 1");
                $team_stmt->bind_param("i", $employee_id);
                $team_stmt->execute();
                $team_result = $team_stmt->get_result();
                $team_data = $team_result->fetch_assoc();
                $team_id = $team_data ? (int)$team_data['team_id'] : null;
                $team_stmt->close();
                
                $update_assignment = $conn->prepare("UPDATE booking_assignments SET employee_id = ?, team_id = ?, started_at = IFNULL(started_at, NOW()) WHERE booking_id = ?");
                $update_assignment->bind_param("iii", $employee_id, $team_id, $booking_id);
                if (!$update_assignment->execute()) throw new Exception("Failed to update assignment");
                $update_assignment->close();
            } else {
                // Just update started_at
                $update_stmt = $conn->prepare("UPDATE booking_assignments SET started_at = IFNULL(started_at, NOW()) WHERE booking_id=?");
                $update_stmt->bind_param("i", $booking_id);
                if (!$update_stmt->execute()) throw new Exception("Failed to update started_at");
                $update_stmt->close();
            }
        }
        
        $stmt = $conn->prepare("UPDATE bookings SET status='IN_PROGRESS' WHERE booking_id=?");
        if (!$stmt) throw new Exception("Prepare failed (update bookings start)");
        $stmt->bind_param("i", $booking_id);
        if (!$stmt->execute()) throw new Exception("Execute failed (update bookings start)");
        $stmt->close();

        $conn->commit();

        echo json_encode([
            "status" => "success",
            "new_status" => "IN_PROGRESS"
        ]);
    } else {
        $stmt = $conn->prepare("SELECT customer_id, price_total FROM bookings WHERE booking_id = ?");
        if (!$stmt) throw new Exception("Prepare failed (select booking for finish)");
        $stmt->bind_param("i", $booking_id);
        if (!$stmt->execute()) throw new Exception("Execute failed (select booking for finish)");
        $booking_result = $stmt->get_result();
        $booking_data = $booking_result->fetch_assoc();
        $stmt->close();
        
        $customer_id = $booking_data['customer_id'];
        $price_total = (float)$booking_data['price_total'];
        
        // Calculate points: 15 NIS = 1 point (exact calculation)
        $pointsExact = $price_total / 15;
        // Round to nearest integer for storage (since points is INT in database)
        $pointsToAdd = (int)round($pointsExact);
        
        // If points is 0 but price is > 0, give at least 1 point
        if ($pointsToAdd == 0 && $price_total > 0) {
            $pointsToAdd = 1;
        }
        
        $wallet_stmt = $conn->prepare("SELECT points FROM wallets WHERE customer_id = ? FOR UPDATE");
        $wallet_stmt->bind_param("i", $customer_id);
        $wallet_stmt->execute();
        $wallet_result = $wallet_stmt->get_result();
        
        if ($wallet_result->num_rows === 0) {
            $wallet_stmt->close();
            $insert_wallet = $conn->prepare("INSERT INTO wallets (customer_id, balance, points) VALUES (?, 0.00, ?)");
            $insert_wallet->bind_param("ii", $customer_id, $pointsToAdd);
            $insert_wallet->execute();
            $insert_wallet->close();
        } else {
            $wallet = $wallet_result->fetch_assoc();
            $currentPoints = (int)$wallet["points"];
            $newPoints = $currentPoints + $pointsToAdd;
            $wallet_stmt->close();
            
            $update_wallet = $conn->prepare("UPDATE wallets SET points = ? WHERE customer_id = ?");
            $update_wallet->bind_param("ii", $newPoints, $customer_id);
            $update_wallet->execute();
            $update_wallet->close();
        }
        
        // Show exact calculation in note (e.g., "5.33 points" for 80 NIS)
        $pointsDisplay = number_format($pointsExact, 2, '.', '');
        $txn_stmt = $conn->prepare("INSERT INTO wallet_transactions (customer_id, booking_id, txn_type, points_earned, note) VALUES (?, ?, 'POINTS_EARNED', ?, ?)");
        $note = "Earned $pointsDisplay points from booking (paid {$price_total} NIS, 15 NIS = 1 point)";
        $txn_stmt->bind_param("iiis", $customer_id, $booking_id, $pointsToAdd, $note);
        $txn_stmt->execute();
        $txn_stmt->close();
        
        $stmt = $conn->prepare("UPDATE bookings SET status='COMPLETED' WHERE booking_id=?");
        if (!$stmt) throw new Exception("Prepare failed (update bookings finish)");
        $stmt->bind_param("i", $booking_id);
        if (!$stmt->execute()) throw new Exception("Execute failed (update bookings finish)");
        $stmt->close();

        $stmt = $conn->prepare("UPDATE booking_assignments SET finished_at = IFNULL(finished_at, NOW()) WHERE booking_id=?");
        if (!$stmt) throw new Exception("Prepare failed (update assignment finish)");
        $stmt->bind_param("i", $booking_id);
        if (!$stmt->execute()) throw new Exception("Execute failed (update assignment finish)");
        $stmt->close();

        $conn->commit();

        echo json_encode([
            "status" => "success",
            "new_status" => "COMPLETED",
            "points_added" => $pointsToAdd,
            "points_exact" => round($pointsExact, 2),
            "price_paid" => $price_total
        ]);
    }
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}

$conn->close();
?>
