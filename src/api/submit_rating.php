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

$booking_id = isset($_POST['booking_id']) ? (int)$_POST['booking_id'] : 0;
$rating = isset($_POST['rating']) ? (int)$_POST['rating'] : 0;
$feedback = clean($_POST['feedback'] ?? '');

if ($booking_id <= 0 || $rating < 1 || $rating > 5) {
    json_response([
        "status" => "error",
        "message" => "booking_id and rating (1-5) are required"
    ], 400);
}

if (strlen($feedback) > 1000) {
    json_response([
        "status" => "error",
        "message" => "Feedback must be 1000 characters or fewer"
    ], 400);
}

$stmt = $conn->prepare("
    SELECT booking_id, customer_id
    FROM bookings
    WHERE booking_id = ? AND status = 'COMPLETED'
    LIMIT 1
");
$stmt->bind_param("i", $booking_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    $stmt->close();
    json_response([
        "status" => "error",
        "message" => "Booking not found or not completed"
    ], 404);
}

$booking = $result->fetch_assoc();
$customer_id = (int)$booking['customer_id'];
$stmt->close();

$stmt = $conn->prepare("SELECT feedback_id FROM ratings_feedback WHERE booking_id = ? LIMIT 1");
$stmt->bind_param("i", $booking_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $stmt->close();
    json_response([
        "status" => "error",
        "message" => "Rating already submitted for this booking"
    ], 409);
}
$stmt->close();

$stmt = $conn->prepare("
    INSERT INTO ratings_feedback (booking_id, customer_id, rating, comment, created_at)
    VALUES (?, ?, ?, ?, NOW())
");
$stmt->bind_param("iiis", $booking_id, $customer_id, $rating, $feedback);

if (!$stmt->execute()) {
    error_log("Submit rating failed for booking $booking_id");
    $stmt->close();
    json_response([
        "status" => "error",
        "message" => "Failed to submit rating"
    ], 500);
}

$stmt->close();
json_response([
    "status" => "success",
    "message" => "Rating submitted successfully"
]);
?>
