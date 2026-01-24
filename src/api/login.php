<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

include "db.php";

$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';

if (empty($email) || empty($password)) {
    echo json_encode([
        "status" => "error",
        "message" => "Please enter email and password"
    ]);
    exit;
}

$sql = "SELECT user_id, full_name, email, phone, password_hash, role 
        FROM users 
        WHERE email = ?";

$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $user = $result->fetch_assoc();

    if ($password === $user['password_hash']) {
        echo json_encode([
            "status" => "success",
            "user_id" => $user['user_id'],
            "role" => $user['role'], 
            "user" => [
                "id" => $user['user_id'],
                "name" => $user['full_name'],
                "email" => $user['email'],
                "phone" => $user['phone']
            ]
        ]);
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "Incorrect password"
        ]);
    }
} else {
    echo json_encode([
        "status" => "error",
        "message" => "User not found"
    ]);
}

$stmt->close();
$conn->close();
