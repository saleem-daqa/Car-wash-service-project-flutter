<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/db.php';

$customer_id = request_int_param('customer_id', 0, 0, PHP_INT_MAX);
$pagination = pagination_params(100, 200);
$limit = (int)$pagination["limit"];
$offset = (int)$pagination["offset"];
$search = trim((string)request_param('search', ''));
$sort = strtolower(trim((string)request_param('sort', 'created_at')));
$direction = sort_direction_param();

$sortColumns = [
    'created_at' => 'created_at',
    'plate_number' => 'plate_number',
    'brand' => 'brand',
    'model' => 'model',
];
$sortColumn = $sortColumns[$sort] ?? 'created_at';

if ($customer_id === 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Missing customer_id'
    ]);
    exit;
}

$where = ["customer_id = ?"];
$types = "i";
$params = [$customer_id];

if ($search !== '') {
    $like = "%" . $search . "%";
    $where[] = "(plate_number LIKE ? OR brand LIKE ? OR model LIKE ? OR color LIKE ?)";
    $types .= "ssss";
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
}

$whereSql = implode(" AND ", $where);

$stmt = $conn->prepare(
    "SELECT car_id, plate_number, type, brand, model, color, notes 
     FROM customer_cars 
     WHERE $whereSql
     ORDER BY $sortColumn $direction
     LIMIT $limit OFFSET $offset"
);

if (!$stmt) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error occurred'
    ]);
    $conn->close();
    exit;
}

bind_statement_params($stmt, $types, $params);
$stmt->execute();
$result = $stmt->get_result();

$vehicles = [];
while ($row = $result->fetch_assoc()) {
    $vehicles[] = [
        'car_id' => $row['car_id'],
        'plate_number' => $row['plate_number'],
        'type' => $row['type'],
        'brand' => $row['brand'],
        'model' => $row['model'],
        'color' => $row['color'],
        'notes' => $row['notes']
    ];
}

echo json_encode([
    'status' => 'success',
    'vehicles' => $vehicles,
    'count' => count($vehicles),
    'pagination' => pagination_payload(count($vehicles), $pagination)
]);

$stmt->close();
$conn->close();
?>
