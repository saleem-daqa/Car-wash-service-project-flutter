<?php
ini_set('display_errors', 0);
error_reporting(E_ALL);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/php_errors.log');

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

try {
    include "db.php";
    
    if (!isset($conn) || $conn->connect_error) {
        throw new Exception("Database connection failed");
    }

    // Get POST data
    $customer_id = $_POST['customer_id'] ?? null;
    $car_id = $_POST['car_id'] ?? null;
    $service_name = $_POST['service_name'] ?? '';
    $price = $_POST['price'] ?? '';
    $booking_date = $_POST['booking_date'] ?? '';
    $booking_time = $_POST['booking_time'] ?? '';
    $latitude = $_POST['latitude'] ?? null;
    $longitude = $_POST['longitude'] ?? null;
    $notes = $_POST['notes'] ?? '';
    $payment_method = $_POST['payment_method'] ?? '';
    $address_text = $_POST['address_text'] ?? '';

    // Validate required fields
    if (empty($customer_id) || empty($car_id) || empty($service_name) || 
        empty($price) || empty($booking_date) || empty($booking_time)) {
        echo json_encode([
            "status" => "error",
            "message" => "Missing required fields"
        ]);
        exit;
    }

    // Get service_id from service_name - CREATE IF NOT EXISTS
    $service_stmt = $conn->prepare("SELECT service_id FROM services WHERE name = ? LIMIT 1");
    $service_stmt->bind_param("s", $service_name);
    $service_stmt->execute();
    $service_result = $service_stmt->get_result();
    
    if ($service_result->num_rows === 0) {
        // Service doesn't exist - create it
        $service_stmt->close();
        
        $priceFloat = floatval($price);
        $insert_service = $conn->prepare("INSERT INTO services (name, description, price, duration_minutes, is_active) VALUES (?, ?, ?, 45, 1)");
        $description = "Auto-created service";
        $insert_service->bind_param("ssd", $service_name, $description, $priceFloat);
        
        if (!$insert_service->execute()) {
            throw new Exception("Failed to create service");
        }
        
        $service_id = $conn->insert_id;
        $insert_service->close();
    } else {
        $service_row = $service_result->fetch_assoc();
        $service_id = $service_row['service_id'];
        $service_stmt->close();
    }

    // Combine date and time into scheduled_at
    $datetime = new DateTime($booking_date);
    $time_parts = explode(' ', $booking_time); // "7:00 AM"
    $time_str = $time_parts[0]; // "7:00"
    $period = isset($time_parts[1]) ? $time_parts[1] : 'AM'; // "AM" or "PM"
    
    list($hour, $minute) = explode(':', $time_str);
    $hour = intval($hour);
    
    // Convert to 24-hour format
    if ($period === 'PM' && $hour !== 12) {
        $hour += 12;
    } elseif ($period === 'AM' && $hour === 12) {
        $hour = 0;
    }
    
    $datetime->setTime($hour, intval($minute));
    $scheduled_at = $datetime->format('Y-m-d H:i:s');

    // Insert booking
    $sql = "INSERT INTO bookings 
            (customer_id, car_id, service_id, address_text, latitude, longitude, 
             scheduled_at, status, price_total, special_instructions) 
            VALUES (?, ?, ?, ?, ?, ?, ?, 'CONFIRMED', ?, ?)";

    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Booking prepare failed");
    }

    $lat = floatval($latitude);
    $lng = floatval($longitude);
    $priceFloat = floatval($price);

    $stmt->bind_param(
        "iiisddsds",
        $customer_id,
        $car_id,
        $service_id,
        $address_text,
        $lat,
        $lng,
        $scheduled_at,
        $priceFloat,
        $notes
    );

    if ($stmt->execute()) {
        $booking_id = $conn->insert_id;
        
        echo json_encode([
            "status" => "success",
            "message" => "Booking saved successfully",
            "booking_id" => $booking_id
        ]);
    } else {
        throw new Exception("Booking insert failed");
    }

    $stmt->close();
    $conn->close();

} catch (Exception $e) {
    error_log("Booking Error: " . $e->getMessage());
    
    echo json_encode([
        "status" => "error",
        "message" => "Server error occurred"
    ]);
}
?>
