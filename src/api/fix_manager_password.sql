-- Fix manager password: Update the password_hash for the manager account
-- Replace 'salom@example.com' with your actual manager email
-- Replace '1234567' with your desired password

-- First, generate the password hash using PHP:
-- php -r "echo password_hash('1234567', PASSWORD_DEFAULT);"
-- Then copy the hash and use it in the UPDATE statement below

-- Example UPDATE (replace the hash with one generated from PHP):
UPDATE users 
SET password_hash = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'
WHERE email = 'salom@example.com' AND role = 'MANAGER';

-- Or use this simpler approach: Update via the PHP script
-- Visit: http://localhost:8888/api/update_manager_password.php?email=salom@example.com&password=1234567
