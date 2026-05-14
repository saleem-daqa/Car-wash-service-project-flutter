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

$user_id = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;
$current_password = (string)($_POST['current_password'] ?? '');
$new_password = (string)($_POST['new_password'] ?? '');

if ($user_id <= 0 || $current_password === '' || $new_password === '') {
    json_response([
        'status' => 'error',
        'message' => 'Missing required fields'
    ], 400);
}

if (!is_strong_password($new_password)) {
    json_response([
        'status' => 'error',
        'message' => 'New password must be at least 8 characters and include letters and numbers'
    ], 400);
}

if (hash_equals($current_password, $new_password)) {
    json_response([
        'status' => 'error',
        'message' => 'New password must be different from the current password'
    ], 400);
}

$stmt = $conn->prepare("SELECT password_hash FROM users WHERE user_id = ? AND is_active = 1 LIMIT 1");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    $stmt->close();
    json_response([
        'status' => 'error',
        'message' => 'User not found'
    ], 404);
}

$row = $result->fetch_assoc();
$stored_password = $row['password_hash'];
$stmt->close();

if (!verify_user_password($current_password, $stored_password)) {
    json_response([
        'status' => 'error',
        'message' => 'Current password is incorrect'
    ], 401);
}

migrate_legacy_password_if_needed($conn, $user_id, $current_password, $stored_password);
$new_password_hash = hash_user_password($new_password);

$update_stmt = $conn->prepare("UPDATE users SET password_hash = ? WHERE user_id = ?");
$update_stmt->bind_param("si", $new_password_hash, $user_id);

if (!$update_stmt->execute()) {
    error_log("Change password failed for user $user_id");
    $update_stmt->close();
    json_response([
        'status' => 'error',
        'message' => 'Failed to update password'
    ], 500);
}

$update_stmt->close();
json_response([
    'status' => 'success',
    'message' => 'Password changed successfully'
]);
?>
