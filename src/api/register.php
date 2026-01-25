<?php
header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . "/helpers.php";
require_once __DIR__ . "/db.php";

require_post();

$input = get_json_input();
if (!$input) {
    error("Invalid JSON body", 400);
}

$full_name = clean($input["full_name"] ?? $input["name"] ?? "");
$email     = clean($input["email"] ?? "");
$phone     = clean($input["phone"] ?? "");
$password  = $input["password"] ?? "";
$role = "CUSTOMER";

if ($full_name === "" || $email === "" || $phone === "" || $password === "" || $role === "") {
    error("Please fill all required fields (full_name, email, phone, password, role)", 400);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    error("Invalid email format", 400);
}

if (strlen($password) < 6) {
    error("Password must be at least 6 characters", 400);
}

$valid_roles = ["CUSTOMER", "EMPLOYEE", "MANAGER"];
if (!in_array($role, $valid_roles)) {
    error("Invalid role", 400);
}

$stmt = $conn->prepare("SELECT user_id FROM users WHERE email = ? LIMIT 1");
$stmt->bind_param("s", $email);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows > 0) {
    $stmt->close();
    error("Email already registered", 409);
}
$stmt->close();

$stmt = $conn->prepare("SELECT user_id FROM users WHERE phone = ? LIMIT 1");
$stmt->bind_param("s", $phone);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows > 0) {
    $stmt->close();
    error("Phone already registered", 409);
}
$stmt->close();

$stmt = $conn->prepare("
    INSERT INTO users (full_name, email, phone, password_hash, role, is_active)
    VALUES (?, ?, ?, ?, ?, 1)
");
$stmt->bind_param("sssss", $full_name, $email, $phone, $password, $role);

if (!$stmt->execute()) {
    $err = $stmt->error;
    $stmt->close();
    error("Failed to register user: " . $err, 500);
}

$user_id = $stmt->insert_id;
$stmt->close();

success(["user_id" => $user_id], "Registration successful");
?>