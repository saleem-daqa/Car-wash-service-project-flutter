<?php
header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . "/helpers.php";
require_once __DIR__ . "/db.php";

require_post();

// Read JSON body
$input = get_json_input();
if (!$input) {
    error("Invalid JSON body", 400);
}

$name = clean($input["name"] ?? "");
$description = clean($input["description"] ?? "");
$price = $input["price"] ?? null;
$duration = $input["duration_minutes"] ?? 30;
$is_active = $input["is_active"] ?? 1;

// Validate required fields
if ($name === "") {
    error("name is required", 400);
}
if ($price === null || $price === "" || !is_numeric($price)) {
    error("price must be a number", 400);
}
if (!is_numeric($duration) || intval($duration) <= 0) {
    error("duration_minutes must be a positive number", 400);
}
$is_active = ($is_active == 1 || $is_active === true || $is_active === "1") ? 1 : 0;

// Optional: enforce positive price
if (floatval($price) < 0) {
    error("price must be >= 0", 400);
}

// Check duplicate name (because you have UNIQUE uq_services_name)
$check = $conn->prepare("SELECT service_id FROM services WHERE name = ? LIMIT 1");
$check->bind_param("s", $name);
$check->execute();
$checkRes = $check->get_result();
if ($checkRes && $checkRes->num_rows > 0) {
    error("Service name already exists", 409);
}
$check->close();

// Insert
$stmt = $conn->prepare("
    INSERT INTO services (name, description, price, duration_minutes, is_active)
    VALUES (?, ?, ?, ?, ?)
");
if (!$stmt) {
    error("Prepare failed: " . $conn->error, 500);
}

$priceFloat = floatval($price);
$durationInt = intval($duration);
$stmt->bind_param("ssdii", $name, $description, $priceFloat, $durationInt, $is_active);

if (!$stmt->execute()) {
    $stmt->close();
    error("Insert failed: " . $conn->error, 500);
}

$newId = $stmt->insert_id;
$stmt->close();

// Return created service row
$get = $conn->prepare("SELECT * FROM services WHERE service_id = ? LIMIT 1");
$get->bind_param("i", $newId);
$get->execute();
$row = $get->get_result()->fetch_assoc();
$get->close();

success(["service" => $row], "Service created");
