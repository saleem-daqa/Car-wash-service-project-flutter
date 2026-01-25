-- Reset Database and Create Manager Account
-- This script will delete all existing data and create a fresh manager account
-- IMPORTANT: This deletes ALL data in the database!

USE car_wash_db;

-- Disable foreign key checks temporarily
SET FOREIGN_KEY_CHECKS = 0;

-- Delete all data from child tables first (in reverse order of dependencies)

-- Delete wallet transactions (references bookings and users)
DELETE FROM wallet_transactions;

-- Delete ratings and feedback (references bookings and users)
DELETE FROM ratings_feedback;

-- Delete booking assignments (references bookings, teams, users)
DELETE FROM booking_assignments;

-- Delete bookings (references users, customer_cars, services)
DELETE FROM bookings;

-- Delete team members (references teams and users)
DELETE FROM team_members;

-- Delete teams (references company_cars)
DELETE FROM teams;

-- Delete company cars
DELETE FROM company_cars;

-- Delete customer cars (references users)
DELETE FROM customer_cars;

-- Delete wallets (references users)
DELETE FROM wallets;

-- Delete services (optional - you might want to keep these)
-- DELETE FROM services;

-- Now delete all users
DELETE FROM users;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- Reset AUTO_INCREMENT to start from 1
ALTER TABLE users AUTO_INCREMENT = 1;
ALTER TABLE customer_cars AUTO_INCREMENT = 1;
ALTER TABLE bookings AUTO_INCREMENT = 1;
ALTER TABLE services AUTO_INCREMENT = 1;
ALTER TABLE company_cars AUTO_INCREMENT = 1;
ALTER TABLE teams AUTO_INCREMENT = 1;

-- Create a new manager account
-- Password is stored as plain text (no hashing)
INSERT INTO users (full_name, email, phone, password_hash, role, is_active)
VALUES (
    'Manager',
    'manager@carwash.com',
    '0501234567',
    'manager123',  -- Plain text password
    'MANAGER',
    1
);

-- Verify the manager account was created
SELECT user_id, full_name, email, phone, role, is_active 
FROM users 
WHERE role = 'MANAGER';

-- Show all users (should only show the manager)
SELECT user_id, full_name, email, role FROM users;
