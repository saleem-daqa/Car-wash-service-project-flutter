DROP DATABASE IF EXISTS car_wash_db;
CREATE DATABASE car_wash_db;
USE car_wash_db;

SET NAMES utf8mb4;

-- 1) Users (Customer, Employee, Manager)
CREATE TABLE users (
  user_id        INT AUTO_INCREMENT PRIMARY KEY,
  full_name      VARCHAR(100) NOT NULL,
  email          VARCHAR(191) NOT NULL,
  phone          VARCHAR(30)  NOT NULL,
  password_hash  VARCHAR(255) NOT NULL,
  role           ENUM('CUSTOMER','EMPLOYEE','MANAGER') NOT NULL,
  is_active      TINYINT(1) NOT NULL DEFAULT 1,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  UNIQUE KEY uq_users_email (email),
  UNIQUE KEY uq_users_phone (phone),
  KEY idx_users_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2) Customer Cars
CREATE TABLE customer_cars (
  car_id        INT AUTO_INCREMENT PRIMARY KEY,
  customer_id   INT NOT NULL,
  plate_number  VARCHAR(30) NOT NULL,
  type          VARCHAR(50),
  brand         VARCHAR(60) NOT NULL,
  model         VARCHAR(60) NOT NULL,
  color         VARCHAR(40),
  notes         VARCHAR(255),
  is_default    TINYINT(1) NOT NULL DEFAULT 0,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (customer_id) REFERENCES users(user_id)
    ON DELETE CASCADE,

  UNIQUE KEY uq_customer_plate (customer_id, plate_number),
  KEY idx_customer_cars_customer_created (customer_id, created_at),
  KEY idx_customer_cars_plate (plate_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3) Services
CREATE TABLE services (
  service_id        INT AUTO_INCREMENT PRIMARY KEY,
  name              VARCHAR(80) NOT NULL,
  description       TEXT,
  price             DECIMAL(10,2) NOT NULL,
  duration_minutes  INT NOT NULL DEFAULT 30,
  is_active         TINYINT(1) NOT NULL DEFAULT 1,
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  UNIQUE KEY uq_services_name (name),
  KEY idx_services_active (is_active, service_id),
  CHECK (price >= 0),
  CHECK (duration_minutes > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4) Company Cars
CREATE TABLE company_cars (
  company_car_id  INT AUTO_INCREMENT PRIMARY KEY,
  plate_number    VARCHAR(30) NOT NULL,
  model           VARCHAR(60),
  is_active       TINYINT(1) NOT NULL DEFAULT 1,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  UNIQUE KEY uq_company_car_plate (plate_number),
  KEY idx_company_cars_active (is_active, company_car_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5) Teams
CREATE TABLE teams (
  team_id         INT AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(80) NOT NULL,
  company_car_id  INT NOT NULL,
  is_active       TINYINT(1) NOT NULL DEFAULT 1,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (company_car_id) REFERENCES company_cars(company_car_id),

  UNIQUE KEY uq_teams_name (name),
  UNIQUE KEY uq_teams_company_car (company_car_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6) Team Members
CREATE TABLE team_members (
  team_id     INT NOT NULL,
  employee_id INT NOT NULL,
  joined_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (team_id, employee_id),

  FOREIGN KEY (team_id) REFERENCES teams(team_id)
    ON DELETE CASCADE,

  FOREIGN KEY (employee_id) REFERENCES users(user_id)
    ON DELETE CASCADE,

  KEY idx_team_members_employee (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7) Bookings
CREATE TABLE bookings (
  booking_id            INT AUTO_INCREMENT PRIMARY KEY,
  customer_id           INT NOT NULL,
  car_id                INT NOT NULL,
  service_id            INT NOT NULL,

  address_text          VARCHAR(255),
  latitude              DECIMAL(10,7) NOT NULL,
  longitude             DECIMAL(10,7) NOT NULL,

  scheduled_at          DATETIME,
  status                ENUM('PENDING','CONFIRMED','ASSIGNED','IN_PROGRESS','COMPLETED','CANCELLED')
                        NOT NULL DEFAULT 'PENDING',
  price_total           DECIMAL(10,2) NOT NULL,
  payment_method        ENUM('CASH','VISA','WALLET') NOT NULL DEFAULT 'CASH',
  special_instructions  TEXT,
  created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (customer_id) REFERENCES users(user_id),
  FOREIGN KEY (car_id) REFERENCES customer_cars(car_id),
  FOREIGN KEY (service_id) REFERENCES services(service_id),
  
  KEY idx_bookings_status (status),
  KEY idx_bookings_customer (customer_id),
  KEY idx_bookings_scheduled (scheduled_at),
  KEY idx_bookings_customer_status_created (customer_id, status, created_at),
  KEY idx_bookings_status_created (status, created_at),
  KEY idx_bookings_service (service_id),
  KEY idx_bookings_car (car_id),
  CHECK (price_total >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8) Booking Assignments
CREATE TABLE booking_assignments (
  assignment_id  INT AUTO_INCREMENT PRIMARY KEY,
  booking_id     INT NOT NULL,
  team_id        INT,
  employee_id    INT,
  assigned_by     INT,
  assigned_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  started_at     DATETIME,
  finished_at    DATETIME,

  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
    ON DELETE CASCADE,

  FOREIGN KEY (team_id) REFERENCES teams(team_id),
  FOREIGN KEY (employee_id) REFERENCES users(user_id),
  FOREIGN KEY (assigned_by) REFERENCES users(user_id),

  UNIQUE KEY uq_assignment_booking (booking_id),
  KEY idx_assignments_booking_employee (booking_id, employee_id),
  KEY idx_assignments_employee (employee_id),
  KEY idx_assignments_team (team_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9) Wallets
CREATE TABLE wallets (
  customer_id  INT PRIMARY KEY,
  balance      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  points       INT NOT NULL DEFAULT 0,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
               ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (customer_id) REFERENCES users(user_id)
    ON DELETE CASCADE,

  CHECK (balance >= 0),
  CHECK (points >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10) Wallet Transactions
CREATE TABLE wallet_transactions (
  txn_id       BIGINT AUTO_INCREMENT PRIMARY KEY,
  customer_id  INT NOT NULL,
  booking_id   INT,
  txn_type     ENUM('RECHARGE','PAYMENT','REFUND','POINTS_EARNED','POINTS_CONVERTED') NOT NULL,
  amount       DECIMAL(10,2) DEFAULT 0.00,
  points_earned INT DEFAULT 0,
  points_used   INT DEFAULT 0,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  note         VARCHAR(255),

  FOREIGN KEY (customer_id) REFERENCES users(user_id),
  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),

  KEY idx_transactions_customer (customer_id),
  KEY idx_transactions_booking (booking_id),
  KEY idx_transactions_created (created_at),
  
  CHECK (amount >= 0),
  CHECK (points_earned >= 0),
  CHECK (points_used >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 11) Ratings & Feedback
CREATE TABLE ratings_feedback (
  feedback_id  BIGINT AUTO_INCREMENT PRIMARY KEY,
  booking_id   INT NOT NULL,
  customer_id  INT NOT NULL,
  rating       TINYINT NOT NULL,
  comment      TEXT,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
    ON DELETE CASCADE,

  FOREIGN KEY (customer_id) REFERENCES users(user_id),

  CHECK (rating BETWEEN 1 AND 5),
  UNIQUE KEY uq_feedback_booking (booking_id),
  KEY idx_feedback_customer_created (customer_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SHOW TABLES;
