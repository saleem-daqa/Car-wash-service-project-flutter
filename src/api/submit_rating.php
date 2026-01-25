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
$rating = isset($_POST['rating']) ? (int)$_POST['rating'] : 0;
$feedback = trim($_POST['feedback'] ?? '');

if (empty($booking_id) || $rating < 1 || $rating > 5) {
    echo json_encode([
        "status" => "error",
        "message" => "booking_id and rating (1-5) are required"
    ]);
    $conn->close();
    exit;
}

$stmt = $conn->prepare("SELECT booking_id FROM bookings WHERE booking_id = ? AND status = 'COMPLETED' LIMIT 1");
$stmt->bind_param("i", $booking_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode([
        "status" => "error",
        "message" => "Booking not found or not completed"
    ]);
    $stmt->close();
    $conn->close();
    exit;
}
$stmt->close();

$stmt = $conn->prepare("SELECT rating_id FROM ratings_feedback WHERE booking_id = ? LIMIT 1");
$stmt->bind_param("i", $booking_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $stmt->close();
    echo json_encode([
        "status" => "error",
        "message" => "Rating already submitted for this booking"
    ]);
    $conn->close();
    exit;
}
$stmt->close();

$stmt = $conn->prepare("
    INSERT INTO ratings_feedback (booking_id, rating, feedback_text, created_at)
    VALUES (?, ?, ?, NOW())
");

if (!$stmt) {
    echo json_encode([
        "status" => "error",
        "message" => "Prepare failed",
        "error" => $conn->error
    ]);
    $conn->close();
    exit;
}

$stmt->bind_param("iis", $booking_id, $rating, $feedback);

if ($stmt->execute()) {
    echo json_encode([
        "status" => "success",
        "message" => "Rating submitted successfully"
    ]);
} else {
    echo json_encode([
        "status" => "error",
        "message" => "Failed to submit rating",
        "error" => $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>
