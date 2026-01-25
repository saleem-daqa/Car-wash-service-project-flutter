<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'db.php';

$full_name = $_POST['full_name'] ?? '';
$email = $_POST['email'] ?? '';
$phone = $_POST['phone'] ?? '';
$password = $_POST['password'] ?? '';

if (empty($full_name) || empty($email) || empty($phone) || empty($password)) {
    echo json_encode([
        'status' => 'error',
        'message' => 'All fields are required (full_name, email, phone, password)'
    ]);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid email format'
    ]);
    exit;
}

if (strlen($password) < 6) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Password must be at least 6 characters'
    ]);
    exit;
}

$stmt = $conn->prepare("SELECT user_id FROM users WHERE email = ? OR phone = ? LIMIT 1");
$stmt->bind_param("ss", $email, $phone);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Email or phone already exists'
    ]);
    $stmt->close();
    $conn->close();
    exit;
}
$stmt->close();

$role = 'MANAGER';

$stmt = $conn->prepare("
    INSERT INTO users (full_name, email, phone, password_hash, role, is_active)
    VALUES (?, ?, ?, ?, ?, 1)
");
$stmt->bind_param("sssss", $full_name, $email, $phone, $password, $role);

if ($stmt->execute()) {
    $user_id = $stmt->insert_id;
    echo json_encode([
        'status' => 'success',
        'message' => 'Manager account created successfully',
        'user_id' => $user_id
    ]);
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'Failed to create manager account: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>
