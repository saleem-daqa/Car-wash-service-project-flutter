<?php
// Add CORS headers FIRST
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$servername = "localhost";   
$username = "root";          
$password = "1234";             
$dbname = "car_wash_db";   

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database connection failed"]);
    exit;
}

// Handle GET request - Fetch existing rating
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $booking_id = isset($_GET['booking_id']) ? intval($_GET['booking_id']) : 0;
    
    if ($booking_id <= 0) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid booking ID"]);
        exit;
    }
    
    $stmt = $conn->prepare("SELECT rating, comment FROM ratings_feedback WHERE booking_id = ?");
    $stmt->bind_param("i", $booking_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        echo json_encode([
            "status" => "success",
            "rating" => intval($row['rating']),
            "feedback" => $row['comment']
        ]);
    } else {
        echo json_encode([
            "status" => "success",
            "rating" => 0,
            "feedback" => ""
        ]);
    }
    
    $stmt->close();
    $conn->close();
    exit;
}

// Handle POST request - Save rating
$booking_id = isset($_POST['booking_id']) ? intval($_POST['booking_id']) : 0;
$rating = isset($_POST['rating']) ? intval($_POST['rating']) : 0;
$feedback = isset($_POST['feedback']) ? trim($_POST['feedback']) : '';

if ($booking_id <= 0 || $rating < 1 || $rating > 5) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Invalid input"]);
    exit;
}

$stmt = $conn->prepare("SELECT customer_id FROM bookings WHERE booking_id = ?");
$stmt->bind_param("i", $booking_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    http_response_code(404);
    echo json_encode(["status" => "error", "message" => "Booking not found"]);
    exit;
}

$row = $result->fetch_assoc();
$customer_id = $row['customer_id'];
$stmt->close();

$stmt = $conn->prepare("
  INSERT INTO ratings_feedback (booking_id, customer_id, rating, comment, created_at)
  VALUES (?, ?, ?, ?, NOW())
  ON DUPLICATE KEY UPDATE rating = VALUES(rating), comment = VALUES(comment), created_at = NOW()
");

$stmt->bind_param("iiis", $booking_id, $customer_id, $rating, $feedback);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "Feedback saved"]);
} else {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Failed to save feedback"]);
}

$stmt->close();
$conn->close();
?>