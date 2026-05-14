#!/usr/bin/env python3
"""Static backend QA checks for the PHP API.

These tests cover security and schema regressions that are easy to miss in a
small PHP API without a framework test harness. They intentionally avoid a live
database so they can run in local/CI environments before integration testing.
"""

from pathlib import Path
import re
import unittest


API_DIR = Path(__file__).resolve().parent
ROOT_DIR = API_DIR.parents[1]
SCHEMA = (ROOT_DIR / "MobilePRJ.sql").read_text()


def php_files():
    return sorted(
        path
        for path in API_DIR.glob("*.php")
        if path.name not in {"db.php", "generate_password_hash.php", "migrate_passwords.php"}
    )


class BackendStaticQaTest(unittest.TestCase):
    def test_endpoints_do_not_bypass_shared_database_connection(self):
        offenders = []
        for path in php_files():
            source = path.read_text()
            if "new mysqli" in source:
                offenders.append(path.name)

        self.assertEqual(
            offenders,
            [],
            f"Endpoints must use db.php instead of opening their own DB connection: {offenders}",
        )

    def test_client_responses_do_not_expose_database_error_details(self):
        leak_patterns = [
            r"json_encode\([^\)]*\$conn->error",
            r"json_encode\([^\)]*\$stmt->error",
            r"json_encode\([^\)]*->error",
            r"respond\([^\)]*details[^\)]*getMessage\(",
            r'"details"\s*=>\s*\$e->getMessage\(',
            r'"message"\s*=>\s*\$e->getMessage\(',
        ]
        offenders = []

        for path in php_files():
            source = path.read_text()
            for pattern in leak_patterns:
                if re.search(pattern, source, flags=re.DOTALL):
                    offenders.append(path.name)
                    break

        self.assertEqual(
            sorted(set(offenders)),
            [],
            f"API responses should log internals server-side, not expose DB details: {offenders}",
        )

    def test_rating_endpoints_use_schema_columns(self):
        self.assertIn("feedback_id", SCHEMA)
        self.assertIn("comment", SCHEMA)
        self.assertNotIn("rating_id", SCHEMA)
        self.assertNotIn("feedback_text", SCHEMA)

        for endpoint in ("rating.php", "rating_feedback.php", "submit_rating.php"):
            source = (API_DIR / endpoint).read_text()
            self.assertNotIn("rating_id", source, endpoint)
            self.assertNotIn("feedback_text", source, endpoint)
            self.assertIn("customer_id", source, endpoint)
            self.assertIn("comment", source, endpoint)

    def test_mutating_endpoints_guard_http_methods(self):
        mutating = [
            "add_points.php",
            "booking_update_status.php",
            "change_password.php",
            "complete_registration.php",
            "convert_points.php",
            "create_booking.php",
            "create_manager.php",
            "create_vehicle.php",
            "delete_vehicle.php",
            "rating.php",
            "rating_feedback.php",
            "register.php",
            "submit_rating.php",
            "update_manager_password.php",
            "update_vehicle.php",
            "verify_password.php",
        ]

        offenders = []
        for endpoint in mutating:
            source = (API_DIR / endpoint).read_text()
            if "require_post()" not in source and "REQUEST_METHOD" not in source:
                offenders.append(endpoint)

        self.assertEqual(offenders, [], f"Missing HTTP method guards: {offenders}")

    def test_setup_only_manager_endpoints_require_setup_key(self):
        for endpoint in ("create_manager.php", "update_manager_password.php"):
            source = (API_DIR / endpoint).read_text()
            self.assertIn("require_setup_key()", source, endpoint)
            self.assertIn("X-Setup-Key", source, endpoint)

        helpers = (API_DIR / "helpers.php").read_text()
        self.assertIn("function require_setup_key", helpers)
        self.assertIn("CARWASH_SETUP_KEY", helpers)

    def test_wallet_booking_is_transactional(self):
        source = (API_DIR / "create_booking.php").read_text()
        transaction_pos = source.index("begin_transaction")
        wallet_lock_pos = source.index("FOR UPDATE")
        booking_insert_pos = source.index("INSERT INTO bookings")
        wallet_update_pos = source.index("UPDATE wallets SET balance")

        self.assertLess(transaction_pos, wallet_lock_pos)
        self.assertLess(wallet_lock_pos, booking_insert_pos)
        self.assertLess(booking_insert_pos, wallet_update_pos)

    def test_database_schema_has_integrity_checks_and_query_indexes(self):
        required_schema_clauses = [
            "KEY idx_customer_cars_customer_created (customer_id, created_at)",
            "KEY idx_services_active (is_active, service_id)",
            "KEY idx_company_cars_active (is_active, company_car_id)",
            "KEY idx_team_members_employee (employee_id)",
            "KEY idx_bookings_customer_status_created (customer_id, status, created_at)",
            "KEY idx_bookings_status_created (status, created_at)",
            "KEY idx_bookings_service (service_id)",
            "KEY idx_bookings_car (car_id)",
            "KEY idx_feedback_customer_created (customer_id, created_at)",
            "CHECK (price >= 0)",
            "CHECK (duration_minutes > 0)",
            "CHECK (price_total >= 0)",
            "CHECK (balance >= 0)",
            "CHECK (points >= 0)",
        ]

        missing = [clause for clause in required_schema_clauses if clause not in SCHEMA]
        self.assertEqual(missing, [], f"Missing DB integrity/performance clauses: {missing}")

    def test_database_migration_for_existing_installs_is_present(self):
        migration = API_DIR / "migrations" / "2026_05_14_database_performance_integrity.sql"
        self.assertTrue(migration.exists(), "DB migration for existing installs is missing")
        source = migration.read_text()
        for clause in (
            "idx_bookings_customer_status_created",
            "idx_bookings_status_created",
            "chk_wallets_balance_non_negative",
            "chk_bookings_price_non_negative",
        ):
            self.assertIn(clause, source)

    def test_large_collection_endpoints_support_safe_pagination(self):
        helpers = (API_DIR / "helpers.php").read_text()
        self.assertIn("function pagination_params", helpers)
        self.assertIn("function pagination_payload", helpers)

        for endpoint in (
            "customer_bookings.php",
            "get_current_bookings.php",
            "get_past_bookings.php",
            "manager_bookings.php",
            "get_all_bookings_for_employees.php",
            "get_all_vehicles.php",
        ):
            source = (API_DIR / endpoint).read_text()
            self.assertIn("pagination_params", source, endpoint)
            self.assertIn("pagination_payload", source, endpoint)
            self.assertIn("LIMIT", source, endpoint)
            self.assertIn("OFFSET", source, endpoint)


if __name__ == "__main__":
    unittest.main(verbosity=2)
