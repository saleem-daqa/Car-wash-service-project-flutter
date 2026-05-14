<?php
require_once "db.php";
require_once "helpers.php";

if ($_SERVER["REQUEST_METHOD"] !== "POST") respond(["error" => "POST only"], 405);

$in = read_json_body();

$fullName = trim($in["full_name"] ?? "");
$email = trim($in["email"] ?? "");
$phone = trim($in["phone"] ?? "");
$password = (string)($in["password"] ?? "");

if ($fullName === "" || $email === "" || $phone === "" || $password === "") {
  respond(["error" => "Required: full_name, email, phone, password"], 400);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
  respond(["error" => "Invalid email format"], 400);
}

if (!is_strong_password($password)) {
  respond(["error" => "Password must be at least 8 characters and include letters and numbers"], 400);
}

$role = "EMPLOYEE";
$isActive = 1;

try {
  $stmt = $conn->prepare("SELECT user_id FROM users WHERE email=? OR phone=? LIMIT 1");
  $stmt->bind_param("ss", $email, $phone);
  $stmt->execute();
  $exists = $stmt->get_result()->fetch_assoc();
  $stmt->close();

  if ($exists) respond(["error" => "Email or phone already exists"], 409);

  $stmt = $conn->prepare("
    INSERT INTO users (full_name, email, phone, password_hash, role, is_active)
    VALUES (?, ?, ?, ?, ?, ?)
  ");
  $passwordHash = hash_user_password($password);
  $stmt->bind_param("sssssi", $fullName, $email, $phone, $passwordHash, $role, $isActive);
  $stmt->execute();

  respond(["ok" => true, "user_id" => (int)$stmt->insert_id], 201);
} catch (Exception $e) {
  respond(["error" => "Failed to create employee"], 500);
}
?>
