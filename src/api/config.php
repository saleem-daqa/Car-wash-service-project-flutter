<?php
define('DB_HOST', getenv('CARWASH_DB_HOST') ?: 'localhost');
define('DB_USER', getenv('CARWASH_DB_USER') ?: 'root');
define('DB_PASS', getenv('CARWASH_DB_PASS') ?: '');
define('DB_NAME', getenv('CARWASH_DB_NAME') ?: 'car_wash_db');
?>
