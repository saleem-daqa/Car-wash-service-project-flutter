<?php
header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . "/helpers.php";
require_once __DIR__ . "/db.php";

require_get();

$result = $conn->query("SELECT * FROM services WHERE is_active = 1");

$services = [];
while ($row = $result->fetch_assoc()) {
    $services[] = $row;
}

success(["services" => $services]);
