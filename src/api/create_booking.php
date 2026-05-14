<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/db.php';

require_post();

$customer_id = isset($_POST['customer_id']) ? (int)$_POST['customer_id'] : 0;
$car_id = isset($_POST['car_id']) ? (int)$_POST['car_id'] : 0;
$service_name = clean($_POST['service_name'] ?? '');
$price = $_POST['price'] ?? '';
$booking_date = trim($_POST['booking_date'] ?? '');
$booking_time = trim($_POST['booking_time'] ?? '');
$latitude = $_POST['latitude'] ?? null;
$longitude = $_POST['longitude'] ?? null;
$notes = clean($_POST['notes'] ?? '');
$payment_method = strtoupper(trim($_POST['payment_method'] ?? 'CASH'));
$address_text = clean($_POST['address_text'] ?? '');

if ($customer_id <= 0 || $car_id <= 0 || $service_name === '' ||
    $price === '' || $booking_date === '' || $booking_time === '') {
    json_response([
        "status" => "error",
        "message" => "Missing required fields"
    ], 400);
}

if (!is_numeric($price) || (float)$price <= 0) {
    json_response([
        "status" => "error",
        "message" => "price must be a positive number"
    ], 400);
}

if ($latitude === null || $longitude === null || !is_numeric($latitude) || !is_numeric($longitude)) {
    json_response([
        "status" => "error",
        "message" => "Valid latitude and longitude are required"
    ], 400);
}

$scheduled = DateTime::createFromFormat('Y-m-d g:i A', "$booking_date $booking_time")
    ?: DateTime::createFromFormat('Y-m-d H:i', "$booking_date $booking_time");

if (!$scheduled) {
    json_response([
        "status" => "error",
        "message" => "Invalid booking date or time"
    ], 400);
}

$paymentMethodEnum = in_array($payment_method, ['CASH', 'VISA', 'WALLET'], true)
    ? $payment_method
    : 'CASH';

$priceFloat = (float)$price;
$lat = (float)$latitude;
$lng = (float)$longitude;
$scheduled_at = $scheduled->format('Y-m-d H:i:s');

$customer_stmt = $conn->prepare("SELECT user_id FROM users WHERE user_id = ? AND role = 'CUSTOMER' AND is_active = 1 LIMIT 1");
$customer_stmt->bind_param("i", $customer_id);
$customer_stmt->execute();
$customer = $customer_stmt->get_result()->fetch_assoc();
$customer_stmt->close();

if (!$customer) {
    json_response([
        "status" => "error",
        "message" => "Customer not found"
    ], 404);
}

$car_stmt = $conn->prepare("SELECT car_id FROM customer_cars WHERE car_id = ? AND customer_id = ? LIMIT 1");
$car_stmt->bind_param("ii", $car_id, $customer_id);
$car_stmt->execute();
$car = $car_stmt->get_result()->fetch_assoc();
$car_stmt->close();

if (!$car) {
    json_response([
        "status" => "error",
        "message" => "Vehicle not found for this customer"
    ], 403);
}

$conn->begin_transaction();

try {
    $service_stmt = $conn->prepare("SELECT service_id FROM services WHERE name = ? LIMIT 1");
    $service_stmt->bind_param("s", $service_name);
    $service_stmt->execute();
    $service_result = $service_stmt->get_result();

    if ($service_result->num_rows === 0) {
        $service_stmt->close();

        $insert_service = $conn->prepare("
            INSERT INTO services (name, description, price, duration_minutes, is_active)
            VALUES (?, ?, ?, 45, 1)
        ");
        $description = "Auto-created service";
        $insert_service->bind_param("ssd", $service_name, $description, $priceFloat);
        $insert_service->execute();
        $service_id = (int)$conn->insert_id;
        $insert_service->close();
    } else {
        $service_row = $service_result->fetch_assoc();
        $service_id = (int)$service_row['service_id'];
        $service_stmt->close();
    }

    if ($paymentMethodEnum === 'WALLET') {
        $wallet_stmt = $conn->prepare("SELECT balance FROM wallets WHERE customer_id = ? FOR UPDATE");
        $wallet_stmt->bind_param("i", $customer_id);
        $wallet_stmt->execute();
        $wallet_result = $wallet_stmt->get_result();

        if ($wallet_result->num_rows === 0) {
            throw new RuntimeException("WALLET_NOT_FOUND");
        }

        $wallet = $wallet_result->fetch_assoc();
        $currentBalance = (float)$wallet["balance"];
        $wallet_stmt->close();

        if ($currentBalance < $priceFloat) {
            throw new RuntimeException("INSUFFICIENT_WALLET_BALANCE");
        }
    }

    $stmt = $conn->prepare("
        INSERT INTO bookings
        (customer_id, car_id, service_id, address_text, latitude, longitude,
         scheduled_at, status, price_total, payment_method, special_instructions)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'CONFIRMED', ?, ?, ?)
    ");

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
    $stmt->execute();
    $booking_id = (int)$conn->insert_id;
    $stmt->close();

    if ($paymentMethodEnum === 'WALLET') {
        $update_wallet = $conn->prepare("UPDATE wallets SET balance = balance - ? WHERE customer_id = ?");
        $update_wallet->bind_param("di", $priceFloat, $customer_id);
        $update_wallet->execute();
        $update_wallet->close();

        $txn_stmt = $conn->prepare("
            INSERT INTO wallet_transactions (customer_id, booking_id, txn_type, amount, note)
            VALUES (?, ?, 'PAYMENT', ?, ?)
        ");
        $note = "Payment for booking #$booking_id";
        $txn_stmt->bind_param("iids", $customer_id, $booking_id, $priceFloat, $note);
        $txn_stmt->execute();
        $txn_stmt->close();
    }

    $conn->commit();

    json_response([
        "status" => "success",
        "message" => "Booking saved successfully",
        "booking_id" => $booking_id
    ]);
} catch (RuntimeException $e) {
    $conn->rollback();
    $safeMessage = "Could not create booking";
    if ($e->getMessage() === "WALLET_NOT_FOUND") {
        $safeMessage = "Wallet not found";
    } elseif ($e->getMessage() === "INSUFFICIENT_WALLET_BALANCE") {
        $safeMessage = "Insufficient wallet balance";
    }
    json_response([
        "status" => "error",
        "message" => $safeMessage
    ], 400);
} catch (Throwable $e) {
    $conn->rollback();
    error_log("Create booking failed: " . $e->getMessage());
    json_response([
        "status" => "error",
        "message" => "Could not create booking"
    ], 500);
}
?>
