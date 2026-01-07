DROP DATABASE car_wash_db;
CREATE DATABASE car_wash_db;
USE car_wash_db;
SET NAMES utf8mb4;

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


CREATE TABLE customer_cars (
  car_id        INT AUTO_INCREMENT PRIMARY KEY,
  customer_id   INT NOT NULL,
  plate_number  VARCHAR(30) NOT NULL,
  brand         VARCHAR(60) NOT NULL,
  model         VARCHAR(60) NOT NULL,
  color         VARCHAR(40) NULL,
  notes         VARCHAR(255) NULL,
  is_default    TINYINT(1) NOT NULL DEFAULT 0,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (customer_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  UNIQUE KEY uq_customer_plate (customer_id, plate_number),
  KEY idx_customer_cars_customer (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE services (
  service_id        INT AUTO_INCREMENT PRIMARY KEY,
  name              VARCHAR(80) NOT NULL,
  description       TEXT NULL,
  price             DECIMAL(10,2) NOT NULL,
  duration_minutes  INT NOT NULL DEFAULT 30,
  is_active         TINYINT(1) NOT NULL DEFAULT 1,
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  UNIQUE KEY uq_services_name (name),
  KEY idx_services_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE company_cars (
  company_car_id  INT AUTO_INCREMENT PRIMARY KEY,
  plate_number    VARCHAR(30) NOT NULL,
  model           VARCHAR(60) NULL,
  is_active       TINYINT(1) NOT NULL DEFAULT 1,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  UNIQUE KEY uq_company_car_plate (plate_number),
  KEY idx_company_cars_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE teams (
  team_id         INT AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(80) NOT NULL,
  company_car_id  INT NOT NULL,
  is_active       TINYINT(1) NOT NULL DEFAULT 1,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (company_car_id) REFERENCES company_cars(company_car_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  UNIQUE KEY uq_teams_name (name),
  UNIQUE KEY uq_teams_company_car (company_car_id),
  KEY idx_teams_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE team_members (
  team_id     INT NOT NULL,
  employee_id INT NOT NULL,
  joined_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (team_id, employee_id),

  FOREIGN KEY (team_id) REFERENCES teams(team_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  FOREIGN KEY (employee_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  KEY idx_team_members_employee (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE bookings (
  booking_id            INT AUTO_INCREMENT PRIMARY KEY,
  customer_id           INT NOT NULL,
  car_id                INT NOT NULL,
  service_id            INT NOT NULL,

  address_text          VARCHAR(255) NULL,
  latitude              DECIMAL(10,7) NOT NULL,
  longitude             DECIMAL(10,7) NOT NULL,

  scheduled_at          DATETIME NULL,
  status                ENUM('PENDING','CONFIRMED','ASSIGNED','IN_PROGRESS','COMPLETED','CANCELLED')
                        NOT NULL DEFAULT 'PENDING',
  price_total           DECIMAL(10,2) NOT NULL,
  special_instructions  TEXT NULL,
  created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (customer_id) REFERENCES users(user_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  FOREIGN KEY (car_id) REFERENCES customer_cars(car_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  FOREIGN KEY (service_id) REFERENCES services(service_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  KEY idx_bookings_customer (customer_id, created_at),
  KEY idx_bookings_status (status, created_at),
  KEY idx_bookings_scheduled (scheduled_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE booking_assignments (
  assignment_id  INT AUTO_INCREMENT PRIMARY KEY,
  booking_id     INT NOT NULL,
  team_id        INT NOT NULL,
  assigned_by    INT NULL,
  assigned_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  started_at     DATETIME NULL,
  finished_at    DATETIME NULL,
  notes          TEXT NULL,

  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  FOREIGN KEY (team_id) REFERENCES teams(team_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  FOREIGN KEY (assigned_by) REFERENCES users(user_id)
    ON DELETE SET NULL ON UPDATE CASCADE,

  UNIQUE KEY uq_assignment_booking (booking_id),
  KEY idx_assignment_team (team_id, assigned_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE wallets (
  customer_id  INT PRIMARY KEY,
  balance      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
               ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (customer_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE wallet_transactions (
  txn_id       BIGINT AUTO_INCREMENT PRIMARY KEY,
  customer_id  INT NOT NULL,
  booking_id   INT NULL,
  txn_type     ENUM('RECHARGE','PAYMENT','REFUND') NOT NULL,
  amount       DECIMAL(10,2) NOT NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  note         VARCHAR(255) NULL,

  FOREIGN KEY (customer_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
    ON DELETE SET NULL ON UPDATE CASCADE,

  CHECK (amount > 0),

  KEY idx_wtx_customer (customer_id, created_at),
  KEY idx_wtx_booking (booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE ratings_feedback (
  feedback_id  BIGINT AUTO_INCREMENT PRIMARY KEY,
  booking_id   INT NOT NULL,
  customer_id  INT NOT NULL,
  rating       TINYINT NOT NULL,
  comment      TEXT NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  FOREIGN KEY (customer_id) REFERENCES users(user_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CHECK (rating BETWEEN 1 AND 5),

  UNIQUE KEY uq_feedback_booking (booking_id),
  KEY idx_feedback_customer (customer_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Short triggers (optional but useful)
DELIMITER $$

CREATE TRIGGER wallets_customer_only
BEFORE INSERT ON wallets
FOR EACH ROW
BEGIN
  IF (SELECT role FROM users WHERE user_id = NEW.customer_id) <> 'CUSTOMER' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Wallet is only for CUSTOMER';
  END IF;
END$$

CREATE TRIGGER rate_only_after_completed
BEFORE INSERT ON ratings_feedback
FOR EACH ROW
BEGIN
  IF (SELECT status FROM bookings WHERE booking_id = NEW.booking_id) <> 'COMPLETED' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rate only after COMPLETED';
  END IF;

  IF (SELECT customer_id FROM bookings WHERE booking_id = NEW.booking_id) <> NEW.customer_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking not yours';
  END IF;
END$$

CREATE TRIGGER team_members_employee_only
BEFORE INSERT ON team_members
FOR EACH ROW
BEGIN
  IF (SELECT role FROM users WHERE user_id = NEW.employee_id) <> 'EMPLOYEE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only EMPLOYEE can join team';
  END IF;
END$$

DELIMITER ;
SHOW TABLES;