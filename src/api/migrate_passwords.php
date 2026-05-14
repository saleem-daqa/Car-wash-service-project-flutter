<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/db.php';

echo "Starting password migration...\n";

$stmt = $conn->prepare("SELECT user_id, password_hash FROM users");
$stmt->execute();
$result = $stmt->get_result();

$updated = 0;
$skipped = 0;

while ($row = $result->fetch_assoc()) {
    $user_id = $row['user_id'];
    $stored_password = $row['password_hash'];
    
    if (!is_password_hash_value($stored_password)) {
        $hashed = hash_user_password($stored_password);
        
        $update_stmt = $conn->prepare("UPDATE users SET password_hash = ? WHERE user_id = ?");
        $update_stmt->bind_param("si", $hashed, $user_id);
        
        if ($update_stmt->execute()) {
            $updated++;
            echo "Updated user ID: $user_id\n";
        }
        $update_stmt->close();
    } else {
        $skipped++;
    }
}

$stmt->close();
$conn->close();

echo "\nMigration complete!\n";
echo "Updated: $updated users\n";
echo "Skipped (already hashed): $skipped users\n";
?>
