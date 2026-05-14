<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER["REQUEST_METHOD"] === "OPTIONS") {
    exit(0);
}

require_once __DIR__ . "/helpers.php";
require_once __DIR__ . "/db.php";

require_post();

$email = strtolower(clean($_POST["email"] ?? ""));
$password = (string)($_POST["password"] ?? "");

if ($email === "" || $password === "") {
    json_response([
        "status" => "error",
        "message" => "Please enter email and password"
    ], 400);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    json_response([
        "status" => "error",
        "message" => "Invalid email or password"
    ], 401);
}

$stmt = $conn->prepare("
    SELECT user_id, full_name, email, phone, password_hash, role
    FROM users
    WHERE email = ? AND is_active = 1
    LIMIT 1
");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows !== 1) {
    $stmt->close();
    $conn->close();
    json_response([
        "status" => "error",
        "message" => "Invalid email or password"
    ], 401);
}

$user = $result->fetch_assoc();
$stmt->close();

if (!verify_user_password($password, $user["password_hash"])) {
    $conn->close();
    json_response([
        "status" => "error",
        "message" => "Invalid email or password"
    ], 401);
}

migrate_legacy_password_if_needed(
    $conn,
    (int)$user["user_id"],
    $password,
    $user["password_hash"]
);

echo json_encode([
    "status" => "success",
    "user_id" => (int)$user["user_id"],
    "role" => $user["role"],
    "user" => [
        "id" => (int)$user["user_id"],
        "name" => $user["full_name"],
        "email" => $user["email"],
        "phone" => $user["phone"]
    ]
]);

$conn->close();
