<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'db.php';

$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
$current_password = $_POST['current_password'] ?? '';
$new_password = $_POST['new_password'] ?? '';

if ($user_id === 0 || $current_password === '' || $new_password === '') {
    echo json_encode([
        'status' => 'error',
        'message' => 'Missing required fields'
    ]);
    exit;
}

if (strlen($new_password) < 6) {
    echo json_encode([
        'status' => 'error',
        'message' => 'New password must be at least 6 characters'
    ]);
    exit;
}

$stmt = $conn->prepare("SELECT password_hash FROM users WHERE user_id = ?");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'User not found'
    ]);
    $stmt->close();
    $conn->close();
    exit;
}

$row = $result->fetch_assoc();
$stored_password = $row['password_hash'];
$stmt->close();

if ($current_password !== $stored_password) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Current password is incorrect'
    ]);
    $conn->close();
    exit;
}

$update_stmt = $conn->prepare(
    "UPDATE users SET password_hash = ? WHERE user_id = ?"
);
$update_stmt->bind_param("si", $new_password, $user_id);

if ($update_stmt->execute()) {
    echo json_encode([
        'status' => 'success',
        'message' => 'Password changed successfully'
    ]);
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'Failed to update password: ' . $update_stmt->error
    ]);
}

$update_stmt->close();
$conn->close();
?>
