<?php
$servername = "localhost";   // Usually localhost for XAMPP
$username = "root";          // Default username for XAMPP MySQL
$password = "1234";              // Default password is empty for XAMPP MySQL
$dbname = "car_wash_db";    // Your database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>
