<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'db.php';

$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
$password = $_POST['password'] ?? '';

if ($user_id === 0 || $password === '') {
    echo json_encode(['status' => 'error', 'message' => 'Missing required fields']);
    exit;
}

$stmt = $conn->prepare("SELECT password_hash FROM users WHERE user_id = ?");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'User not found']);
    $stmt->close();
    $conn->close();
    exit;
}

$row = $result->fetch_assoc();
$stored_password = $row['password_hash'];
$stmt->close();

if ($password === $stored_password) {
    echo json_encode(['status' => 'success', 'message' => 'Password is correct']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Password is incorrect']);
}

$conn->close();
?>
