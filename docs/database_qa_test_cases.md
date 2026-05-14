# Database and API QA Test Cases

These test cases focus on database correctness, SQL safety, backend compatibility,
and data integrity for the car wash service application.

## Database/API Test Matrix

| # | Test case title | Preconditions | Steps | Expected result | Type |
|---|---|---|---|---|---|
| 1 | Register a new customer | Database is running and email/phone are unused | Call `register.php` with valid name, email, phone, password | Customer row is inserted into `users` with role `CUSTOMER`; response is success | Positive |
| 2 | Reject duplicate email | A user already exists with the same email | Call `register.php` with the same email and a different phone | API rejects the request; no duplicate `users.email` row is created | Negative |
| 3 | Reject duplicate phone | A user already exists with the same phone | Call `register.php` with a new email and the same phone | API rejects the request; unique phone constraint remains valid | Negative |
| 4 | Login with valid credentials | A user exists with an active account and hashed password | Call `login.php` with correct email and password | API returns user profile data without exposing `password_hash` | Positive |
| 5 | Login with wrong password | A user exists | Call `login.php` with wrong password | API returns authentication failure and does not change DB state | Security |
| 6 | Create customer vehicle | Active customer exists | Call `create_vehicle.php` with required vehicle fields | Vehicle row is inserted with correct `customer_id` FK | Positive |
| 7 | Reject duplicate vehicle plate per customer | Customer already has a plate number | Create another vehicle with the same plate for that customer | API rejects duplicate; `uq_customer_plate` prevents duplicate data | Negative |
| 8 | Allow same plate for different customers only when business rules allow it | Two customers exist | Add same plate under a different customer | Current schema allows per-customer uniqueness; result should match business rule | Edge Case |
| 9 | Read vehicles with pagination | Customer has more vehicles than requested `limit` | Call `get_all_vehicles.php?customer_id=ID&limit=2&offset=0` | API returns at most 2 vehicles plus pagination metadata | Positive |
| 10 | Search vehicles | Customer has vehicles with different plates/brands/models | Call `get_all_vehicles.php` with `search` matching a plate or brand | Only matching customer vehicles are returned | Positive |
| 11 | Sort vehicles | Customer has multiple vehicles | Call `get_all_vehicles.php` with `sort=brand&direction=ASC` | Vehicles are sorted by allowed column and safe direction | Positive |
| 12 | Reject vehicle access for another customer | Customer A and Customer B exist | Attempt to update/delete Customer B vehicle using Customer A ID | API rejects request; FK-owned data is not modified | Security |
| 13 | Create booking with cash | Customer, vehicle, and service exist | Call `create_booking.php` with valid fields and payment `CASH` | Booking row is created as `CONFIRMED`; no wallet debit occurs | Positive |
| 14 | Create booking with wallet payment | Customer wallet has enough balance | Call `create_booking.php` with payment `WALLET` | Booking is inserted, wallet is debited, transaction row is inserted in one transaction | Positive |
| 15 | Wallet insufficient balance rollback | Customer wallet balance is lower than price | Call `create_booking.php` with payment `WALLET` | API rejects request; no booking, wallet debit, or transaction remains | Negative |
| 16 | Missing booking required fields | Customer exists | Call `create_booking.php` without date, time, price, or vehicle | API returns validation error; no booking is inserted | Negative |
| 17 | Invalid price | Customer exists | Call `create_booking.php` with negative or non-numeric price | API rejects request; `CHECK (price_total >= 0)` protects DB | Negative |
| 18 | Invalid coordinates | Customer exists | Call `create_booking.php` with missing or non-numeric latitude/longitude | API rejects request and avoids invalid location rows | Negative |
| 19 | Read customer bookings by type | Customer has current and past bookings | Call `customer_bookings.php` with `type=current`, `type=past`, and `type=all` | Results match status filters and include pagination metadata | Positive |
| 20 | Read manager bookings with status filter | Bookings exist in several statuses | Call `manager_bookings.php?status=COMPLETED` | Only completed bookings are returned; invalid status is ignored safely | Positive |
| 21 | Read employee queue with search | Active bookings exist | Call `get_all_bookings_for_employees.php?search=plate-or-name` | Current bookings matching customer/service/plate search are returned | Positive |
| 22 | Booking status transition to in progress | Booking exists and employee exists | Call `booking_update_status.php` to start job | Booking status changes to `IN_PROGRESS`; assignment row is created or updated | Positive |
| 23 | Booking completion adds points once | Booking is in progress and customer has wallet | Complete booking once, then retry completion | Points are awarded only according to valid completion logic; no duplicate transaction should be created | Edge Case |
| 24 | Rating completed booking | Completed booking exists for a customer | Call `rating.php` or `submit_rating.php` with rating 1-5 | Feedback row is inserted or updated by unique booking key | Positive |
| 25 | Reject invalid rating | Booking exists | Submit rating 0, 6, or non-numeric value | API rejects request; `CHECK (rating BETWEEN 1 AND 5)` protects DB | Negative |
| 26 | Delete vehicle with existing booking | Vehicle has one or more bookings | Call `delete_vehicle.php` | API rejects deletion to protect booking history | Negative |
| 27 | Foreign key invalid customer | No customer exists for provided ID | Attempt to create vehicle, booking, or wallet transaction | API rejects request before insert; DB FK also protects data | Negative |
| 28 | SQL injection attempt in search | Database has normal records | Send search value like `' OR 1=1 --` to vehicle/booking list endpoints | Query remains parameterized; no extra records or SQL error are returned | Security |
| 29 | Large booking dataset pagination | Database contains thousands of bookings | Request manager and employee booking lists with small `limit` and increasing `offset` | Response stays bounded and sorted; indexes support status/customer ordering | Performance |
| 30 | Empty database state | Tables exist but no operational data | Call list endpoints for vehicles, bookings, teams, and services | APIs return success with empty arrays, not crashes | Edge Case |
| 31 | Transaction failure rollback | Force transaction failure after booking insert in a test DB | Create wallet booking and simulate transaction insert failure | Booking and wallet changes are rolled back together | Edge Case |
| 32 | Backend/schema compatibility | Latest `MobilePRJ.sql` applied | Run PHP lint and `src/api/backend_qa_test.py` | Queries reference existing columns and static DB checks pass | Positive |

## Manual Database QA Notes

- Test the migration on a copy of an existing database before applying it to a
  real deployment.
- Verify MySQL version supports `CHECK` constraints. MySQL 8.0.16 or newer
  enforces them; older versions parse but ignore them.
- Use realistic production-like data volumes for booking list performance tests.
- Confirm frontend screens still render correctly when pagination metadata is
  present in responses.
