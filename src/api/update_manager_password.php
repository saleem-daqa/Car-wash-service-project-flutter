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

$email = strtolower(clean($_POST['email'] ?? ''));
$new_password = (string)($_POST['password'] ?? '');

if ($email === '' || $new_password === '') {
    json_response([
        'status' => 'error',
        'message' => 'Email and password are required'
    ], 400);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    json_response([
        'status' => 'error',
        'message' => 'Invalid email format'
    ], 400);
}

validate_password_or_error($new_password);

$password_hash = hash_user_password($new_password);
$stmt = $conn->prepare("UPDATE users SET password_hash = ? WHERE email = ? AND role = 'MANAGER'");
$stmt->bind_param("ss", $password_hash, $email);

if (!$stmt->execute()) {
    error_log("Update manager password failed for email $email");
    $stmt->close();
    json_response([
        'status' => 'error',
        'message' => 'Failed to update password'
    ], 500);
}

if ($stmt->affected_rows <= 0) {
    $stmt->close();
    json_response([
        'status' => 'error',
        'message' => 'No manager found with that email'
    ], 404);
}

$stmt->close();
json_response([
    'status' => 'success',
    'message' => 'Password updated successfully',
    'email' => $email
]);
?>
