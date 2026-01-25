<?php
require_once 'db.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

$email = $_POST['email'] ?? $_GET['email'] ?? '';
$new_password = $_POST['password'] ?? $_GET['password'] ?? '1234567';

if (empty($email)) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Email is required'
    ]);
    exit;
}

$stmt = $conn->prepare("UPDATE users SET password_hash = ? WHERE email = ?");
$stmt->bind_param("ss", $new_password, $email);

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Password updated successfully',
            'email' => $email,
            'password' => $new_password
        ]);
    } else {
        echo json_encode([
            'status' => 'error',
            'message' => 'No user found with that email'
        ]);
    }
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'Failed to update password: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>
