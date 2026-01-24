<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

$servername = "localhost";
$username = "root";
$password = "1234";  
$dbname = "car_wash_db";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'Connection failed: ' . $conn->connect_error]);
    exit();
}

$name = isset($_POST['name']) ? trim($_POST['name']) : '';
$email = isset($_POST['email']) ? trim($_POST['email']) : '';
$password = isset($_POST['password']) ? trim($_POST['password']) : '';
$role = isset($_POST['role']) ? trim($_POST['role']) : 'CUSTOMER';

if (empty($name) || empty($email) || empty($password) || empty($role)) {
    echo json_encode(['status' => 'error', 'message' => 'Please fill all required fields']);
    exit();
}

$stmt = $conn->prepare("SELECT user_id FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Email already registered']);
    $stmt->close();
    $conn->close();
    exit();
}
$stmt->close();

$phone = ''; 

$stmt = $conn->prepare("INSERT INTO users (full_name, email, phone, password_hash, role) VALUES (?, ?, ?, ?, ?)");
$stmt->bind_param("sssss", $name, $email, $phone, $password, $role);

if ($stmt->execute()) {
    echo json_encode(['status' => 'success', 'message' => 'Registration successful', 'user_id' => $stmt->insert_id]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Failed to register user']);
}

$stmt->close();
$conn->close();
?>
