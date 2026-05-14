-- Fix manager password: Update the password_hash for the manager account
-- Replace 'salom@example.com' with your actual manager email
-- Replace 'manager123' with your desired password

-- First, generate the password hash using PHP:
-- php -r "echo password_hash('manager123', PASSWORD_DEFAULT);"
-- Then copy the hash and use it in the UPDATE statement below

-- Example UPDATE (replace the hash with one generated from PHP):
UPDATE users 
SET password_hash = '$2y$10$replace_this_with_a_generated_hash'
WHERE email = 'salom@example.com' AND role = 'MANAGER';

-- Or use this safer approach: Update via the PHP script with POST form data
-- curl -X POST http://localhost:8888/api/update_manager_password.php \
--   -d "email=salom@example.com" \
--   -d "password=manager123"
