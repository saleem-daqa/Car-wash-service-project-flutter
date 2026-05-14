# How to Create Manager Accounts

## Quick Start: Reset All Accounts and Create Manager

**⚠️ WARNING: This will delete ALL data in the database!**

Run this SQL script in phpMyAdmin or MySQL:

```sql
USE car_wash_db;

-- Disable foreign key checks temporarily
SET FOREIGN_KEY_CHECKS = 0;

-- Delete all related data first
DELETE FROM wallet_transactions;
DELETE FROM ratings_feedback;
DELETE FROM booking_assignments;
DELETE FROM bookings;
DELETE FROM team_members;
DELETE FROM teams;
DELETE FROM company_cars;
DELETE FROM customer_cars;
DELETE FROM wallets;
DELETE FROM users;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- Reset AUTO_INCREMENT
ALTER TABLE users AUTO_INCREMENT = 1;

-- Do not insert plaintext passwords directly.
-- After this reset, create the manager through create_manager.php so the
-- password is hashed before it is stored.
```

Then create the manager through the API:

```bash
export CARWASH_SETUP_KEY="choose-a-long-random-secret"

curl -X POST http://localhost:8888/api/create_manager.php \
  -H "X-Setup-Key: $CARWASH_SETUP_KEY" \
  -d "full_name=Manager" \
  -d "email=manager@carwash.com" \
  -d "phone=0501234567" \
  -d "password=manager123"
```

---

## Option 1: Using the API (Recommended)

### Via Browser/Postman:
```
POST http://localhost:8888/api/create_manager.php
Content-Type: application/x-www-form-urlencoded
X-Setup-Key: your-long-random-secret

full_name=Manager Name
email=manager@example.com
phone=1234567890
password=manager123
```

### Via cURL:
```bash
curl -X POST http://localhost:8888/api/create_manager.php \
  -H "X-Setup-Key: $CARWASH_SETUP_KEY" \
  -d "full_name=Manager Name" \
  -d "email=manager@example.com" \
  -d "phone=1234567890" \
  -d "password=manager123"
```

---

## Option 2: Direct SQL Insert With A Generated Hash

If you cannot call the API, generate a hash first:

```bash
php -r "echo password_hash('manager123', PASSWORD_DEFAULT);"
```

Then use the generated hash in SQL:

```sql
INSERT INTO users (full_name, email, phone, password_hash, role, is_active)
VALUES (
    'Your Manager Name',
    'manager@example.com',
    '1234567890',
    '$2y$10$replace_this_with_the_generated_hash',
    'MANAGER',
    1
);
```

**Important:**
- Email must be unique
- Phone must be unique
- Passwords must be stored as hashes, never plain text.
- `create_manager.php` and `update_manager_password.php` require `CARWASH_SETUP_KEY`.
- Replace the sample values with your actual manager details.

---

## Example Manager Account

```sql
curl -X POST http://localhost:8888/api/create_manager.php \
  -H "X-Setup-Key: $CARWASH_SETUP_KEY" \
  -d "full_name=John Manager" \
  -d "email=john@manager.com" \
  -d "phone=0501234567" \
  -d "password=manager123"
```

---

## Delete All Accounts (Complete Reset)

To delete all existing accounts and related data:

```sql
USE car_wash_db;

SET FOREIGN_KEY_CHECKS = 0;

DELETE FROM wallet_transactions;
DELETE FROM ratings_feedback;
DELETE FROM booking_assignments;
DELETE FROM bookings;
DELETE FROM team_members;
DELETE FROM teams;
DELETE FROM company_cars;
DELETE FROM customer_cars;
DELETE FROM wallets;
DELETE FROM users;

SET FOREIGN_KEY_CHECKS = 1;

ALTER TABLE users AUTO_INCREMENT = 1;
```

---

## Location of Files

- **SQL Script:** `/src/api/reset_and_create_manager.sql`
- **API Endpoint:** `/src/api/create_manager.php`
- **Guide:** `/src/api/CREATE_MANAGER_ACCOUNT.md`
- **SQL Schema:** `/MobilePRJ.sql`
