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

-- Create manager account (plain text password)
INSERT INTO users (full_name, email, phone, password_hash, role, is_active)
VALUES (
    'Manager',
    'manager@carwash.com',
    '0501234567',
    'manager123',  -- Plain text password (no hashing)
    'MANAGER',
    1
);
```

**Login Credentials:**
- Email: `manager@carwash.com`
- Password: `manager123`

---

## Option 1: Using the API (Recommended)

### Via Browser/Postman:
```
POST http://localhost:8888/api/create_manager.php
Content-Type: application/x-www-form-urlencoded

full_name=Manager Name
email=manager@example.com
phone=1234567890
password=manager123
```

### Via cURL:
```bash
curl -X POST http://localhost:8888/api/create_manager.php \
  -d "full_name=Manager Name" \
  -d "email=manager@example.com" \
  -d "phone=1234567890" \
  -d "password=manager123"
```

---

## Option 2: Direct SQL Insert (Without Deleting Existing Data)

If you just want to add a manager without deleting existing accounts:

```sql
INSERT INTO users (full_name, email, phone, password_hash, role, is_active)
VALUES (
    'Your Manager Name',
    'manager@example.com',
    '1234567890',
    'your_password_here',  -- Plain text password (no hashing)
    'MANAGER',
    1
);
```

**Important:**
- Email must be unique
- Phone must be unique
- Password is stored as **plain text** (no hashing)
- Replace the values with your actual manager details

---

## Example Manager Account

```sql
INSERT INTO users (full_name, email, phone, password_hash, role, is_active)
VALUES (
    'John Manager',
    'john@manager.com',
    '0501234567',
    'manager123',  -- Plain text password
    'MANAGER',
    1
);
```

**Login with:**
- Email: `john@manager.com`
- Password: `manager123`

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
