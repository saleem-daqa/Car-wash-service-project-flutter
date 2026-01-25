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

$customer_id = $_POST['customer_id'] ?? null;
$car_id = $_POST['car_id'] ?? null;
$service_name = $_POST['service_name'] ?? '';
$price = $_POST['price'] ?? '';
$booking_date = $_POST['booking_date'] ?? '';
$booking_time = $_POST['booking_time'] ?? '';
$latitude = $_POST['latitude'] ?? null;
$longitude = $_POST['longitude'] ?? null;
$notes = $_POST['notes'] ?? '';
$payment_method = $_POST['payment_method'] ?? '';
$address_text = $_POST['address_text'] ?? '';

if (empty($customer_id) || empty($car_id) || empty($service_name) || 
    empty($price) || empty($booking_date) || empty($booking_time)) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing required fields"
    ]);
    $conn->close();
    exit;
}

$service_stmt = $conn->prepare("SELECT service_id FROM services WHERE name = ? LIMIT 1");
$service_stmt->bind_param("s", $service_name);
$service_stmt->execute();
$service_result = $service_stmt->get_result();

if ($service_result->num_rows === 0) {
    $service_stmt->close();
    
    $priceFloat = floatval($price);
    $insert_service = $conn->prepare("INSERT INTO services (name, description, price, duration_minutes, is_active) VALUES (?, ?, ?, 45, 1)");
    $description = "Auto-created service";
    $insert_service->bind_param("ssd", $service_name, $description, $priceFloat);
    
    if (!$insert_service->execute()) {
        echo json_encode([
            "status" => "error",
            "message" => "Failed to create service: " . $insert_service->error
        ]);
        $insert_service->close();
        $conn->close();
        exit;
    }
    
    $service_id = $conn->insert_id;
    $insert_service->close();
} else {
    $service_row = $service_result->fetch_assoc();
    $service_id = $service_row['service_id'];
    $service_stmt->close();
}

$datetime = new DateTime($booking_date);
$time_parts = explode(' ', $booking_time);
$time_str = $time_parts[0];
$period = isset($time_parts[1]) ? $time_parts[1] : 'AM';

list($hour, $minute) = explode(':', $time_str);
$hour = intval($hour);

if ($period === 'PM' && $hour !== 12) {
    $hour += 12;
} elseif ($period === 'AM' && $hour === 12) {
    $hour = 0;
}

$datetime->setTime($hour, intval($minute));
$scheduled_at = $datetime->format('Y-m-d H:i:s');

$paymentMethodEnum = 'CASH';
if (strtoupper($payment_method) === 'VISA') {
    $paymentMethodEnum = 'VISA';
} elseif (strtoupper($payment_method) === 'WALLET') {
    $paymentMethodEnum = 'WALLET';
}

$sql = "INSERT INTO bookings 
        (customer_id, car_id, service_id, address_text, latitude, longitude, 
         scheduled_at, status, price_total, payment_method, special_instructions) 
        VALUES (?, ?, ?, ?, ?, ?, ?, 'CONFIRMED', ?, ?, ?)";

$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode([
        "status" => "error",
        "message" => "Prepare failed: " . $conn->error
    ]);
    $conn->close();
    exit;
}

$lat = floatval($latitude ?? 0);
$lng = floatval($longitude ?? 0);
$priceFloat = floatval($price);

$stmt->bind_param(
    "iiisddsdss",
    $customer_id,
    $car_id,
    $service_id,
    $address_text,
    $lat,
    $lng,
    $scheduled_at,
    $priceFloat,
    $paymentMethodEnum,
    $notes
);

if ($stmt->execute()) {
    $booking_id = $conn->insert_id;
    
    if ($paymentMethodEnum === 'WALLET') {
        $conn->begin_transaction();
        try {
            $wallet_stmt = $conn->prepare("SELECT balance FROM wallets WHERE customer_id = ? FOR UPDATE");
            $wallet_stmt->bind_param("i", $customer_id);
            $wallet_stmt->execute();
            $wallet_result = $wallet_stmt->get_result();
            
            if ($wallet_result->num_rows === 0) {
                throw new Exception("Wallet not found");
            }
            
            $wallet = $wallet_result->fetch_assoc();
            $currentBalance = (float)$wallet["balance"];
            
            if ($currentBalance < $priceFloat) {
                throw new Exception("Insufficient wallet balance");
            }
            
            $newBalance = $currentBalance - $priceFloat;
            $wallet_stmt->close();
            
            $update_wallet = $conn->prepare("UPDATE wallets SET balance = ? WHERE customer_id = ?");
            $update_wallet->bind_param("di", $newBalance, $customer_id);
            $update_wallet->execute();
            $update_wallet->close();
            
            $txn_stmt = $conn->prepare("INSERT INTO wallet_transactions (customer_id, booking_id, txn_type, amount, note) VALUES (?, ?, 'PAYMENT', ?, ?)");
            $note = "Payment for booking #$booking_id";
            $txn_stmt->bind_param("iids", $customer_id, $booking_id, $priceFloat, $note);
            $txn_stmt->execute();
            $txn_stmt->close();
            
            $conn->commit();
        } catch (Exception $e) {
            $conn->rollback();
            $stmt->close();
            echo json_encode([
                "status" => "error",
                "message" => "Wallet payment failed: " . $e->getMessage()
            ]);
            $conn->close();
            exit;
        }
    }
    
    echo json_encode([
        "status" => "success",
        "message" => "Booking saved successfully",
        "booking_id" => $booking_id
    ]);
} else {
    echo json_encode([
        "status" => "error",
        "message" => "Execute failed: " . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>
