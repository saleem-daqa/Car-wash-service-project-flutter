<?php
require_once "db.php";
require_once "helpers.php";

try {
  $res = $conn->query("
    SELECT company_car_id, plate_number, model, is_active, created_at
    FROM company_cars
    ORDER BY company_car_id DESC
  ");

  $cars = [];
  while ($row = $res->fetch_assoc()) {
    $row["company_car_id"] = (int)$row["company_car_id"];
    $row["is_active"] = (int)$row["is_active"];
    $cars[] = $row;
  }

  respond(["cars" => $cars]);
} catch (Exception $e) {
  respond(["error" => "Failed to fetch company cars", "details" => $e->getMessage()], 500);
}
