-- Database performance and integrity migration for existing car_wash_db installs.
-- Run once after backing up the database. New installs already include these
-- indexes and constraints in MobilePRJ.sql.

USE car_wash_db;

ALTER TABLE customer_cars
  ADD INDEX idx_customer_cars_customer_created (customer_id, created_at),
  ADD INDEX idx_customer_cars_plate (plate_number);

ALTER TABLE services
  ADD INDEX idx_services_active (is_active, service_id),
  ADD CONSTRAINT chk_services_price_non_negative CHECK (price >= 0),
  ADD CONSTRAINT chk_services_duration_positive CHECK (duration_minutes > 0);

ALTER TABLE company_cars
  ADD INDEX idx_company_cars_active (is_active, company_car_id);

ALTER TABLE team_members
  ADD INDEX idx_team_members_employee (employee_id);

ALTER TABLE bookings
  ADD INDEX idx_bookings_customer_status_created (customer_id, status, created_at),
  ADD INDEX idx_bookings_status_created (status, created_at),
  ADD INDEX idx_bookings_service (service_id),
  ADD INDEX idx_bookings_car (car_id),
  ADD CONSTRAINT chk_bookings_price_non_negative CHECK (price_total >= 0);

ALTER TABLE booking_assignments
  ADD INDEX idx_assignments_booking_employee (booking_id, employee_id);

ALTER TABLE wallets
  ADD CONSTRAINT chk_wallets_balance_non_negative CHECK (balance >= 0),
  ADD CONSTRAINT chk_wallets_points_non_negative CHECK (points >= 0);

ALTER TABLE ratings_feedback
  ADD INDEX idx_feedback_customer_created (customer_id, created_at);
