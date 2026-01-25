<?php
// Simple script to generate password hash for MySQL insertion
// Usage: php generate_password_hash.php

$password = $argv[1] ?? 'manager123';

if (empty($password)) {
    echo "Usage: php generate_password_hash.php <password>\n";
    echo "Example: php generate_password_hash.php manager123\n";
    exit(1);
}

$hash = password_hash($password, PASSWORD_DEFAULT);
echo "\nPassword: $password\n";
echo "Hash: $hash\n\n";

echo "SQL INSERT statement:\n";
echo "INSERT INTO users (full_name, email, phone, password_hash, role, is_active)\n";
echo "VALUES ('Manager Name', 'manager@example.com', '1234567890', '$hash', 'MANAGER', 1);\n\n";
