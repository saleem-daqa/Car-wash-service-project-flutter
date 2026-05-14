<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, X-Setup-Key");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/db.php';

require_post();
require_setup_key();

$full_name = clean($_POST['full_name'] ?? '');
$email = strtolower(clean($_POST['email'] ?? ''));
$phone = clean($_POST['phone'] ?? '');
$password = (string)($_POST['password'] ?? '');

if ($full_name === '' || $email === '' || $phone === '' || $password === '') {
    json_response([
        'status' => 'error',
        'message' => 'All fields are required (full_name, email, phone, password)'
    ], 400);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    json_response([
        'status' => 'error',
        'message' => 'Invalid email format'
    ], 400);
}

validate_password_or_error($password);

$stmt = $conn->prepare("SELECT user_id FROM users WHERE email = ? OR phone = ? LIMIT 1");
$stmt->bind_param("ss", $email, $phone);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $stmt->close();
    json_response([
        'status' => 'error',
        'message' => 'Email or phone already exists'
    ], 409);
}
$stmt->close();

$role = 'MANAGER';
$password_hash = hash_user_password($password);

$stmt = $conn->prepare("
    INSERT INTO users (full_name, email, phone, password_hash, role, is_active)
    VALUES (?, ?, ?, ?, ?, 1)
");
$stmt->bind_param("sssss", $full_name, $email, $phone, $password_hash, $role);

if (!$stmt->execute()) {
    error_log("Create manager failed for email $email");
    $stmt->close();
    json_response([
        'status' => 'error',
        'message' => 'Failed to create manager account'
    ], 500);
}

$user_id = (int)$stmt->insert_id;
$stmt->close();

json_response([
    'status' => 'success',
    'message' => 'Manager account created successfully',
    'user_id' => $user_id
]);
?>
