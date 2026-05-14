<?php

/**
 * Send JSON response and exit
 */
function json_response($data, int $statusCode = 200)
{
    http_response_code($statusCode);
    header("Content-Type: application/json; charset=UTF-8");
    echo json_encode($data);
    exit;
}

/**
 * Send success response
 */
function success($data = [], string $message = "OK")
{
    json_response([
        "ok" => true,
        "message" => $message,
        "data" => $data
    ]);
}

/**
 * Send error response
 */
function error(string $message, int $statusCode = 400)
{
    json_response([
        "ok" => false,
        "error" => $message
    ], $statusCode);
}

/**
 * Read JSON body (for POST / PUT)
 */
function get_json_input()
{
    $raw = file_get_contents("php://input");
    return json_decode($raw, true);
}

/**
 * Require POST method
 */
function require_post()
{
    if ($_SERVER["REQUEST_METHOD"] !== "POST") {
        error("POST method required", 405);
    }
}

/**
 * Require GET method
 */
function require_get()
{
    if ($_SERVER["REQUEST_METHOD"] !== "GET") {
        error("GET method required", 405);
    }
}

/**
 * Protect setup-only endpoints such as manager creation/password reset.
 */
function require_setup_key(): void
{
    $expected = getenv("CARWASH_SETUP_KEY") ?: "";
    if ($expected === "") {
        error("Setup endpoint is disabled. Configure CARWASH_SETUP_KEY on the server.", 503);
    }

    $provided = $_SERVER["HTTP_X_SETUP_KEY"] ?? $_POST["setup_key"] ?? "";
    if (!hash_equals($expected, (string)$provided)) {
        error("Forbidden", 403);
    }
}

/**
 * Sanitize string
 */
function clean($value)
{
    return trim(htmlspecialchars($value ?? "", ENT_QUOTES, "UTF-8"));
}

/**
 * Read JSON body (alternative name used in some APIs)
 */
function read_json_body()
{
    $raw = file_get_contents("php://input");
    return json_decode($raw, true) ?? [];
}

/**
 * Respond with JSON (alternative response function)
 */
function respond($data, $statusCode = 200)
{
    http_response_code($statusCode);
    header("Content-Type: application/json; charset=UTF-8");
    echo json_encode($data);
    exit;
}

function is_success_response($data)
{
    return ($data["ok"] ?? false) === true ||
        strtolower((string)($data["status"] ?? "")) === "success";
}

function is_password_hash_value(string $value): bool
{
    return password_get_info($value)["algo"] !== 0;
}

function hash_user_password(string $password): string
{
    return password_hash($password, PASSWORD_DEFAULT);
}

function is_strong_password(string $password): bool
{
    return strlen($password) >= 8 &&
        preg_match('/[A-Za-z]/', $password) === 1 &&
        preg_match('/\d/', $password) === 1;
}

function validate_password_or_error(string $password): void
{
    if (!is_strong_password($password)) {
        error("Password must be at least 8 characters and include letters and numbers", 400);
    }
}

function verify_user_password(string $password, string $storedPassword): bool
{
    if (is_password_hash_value($storedPassword)) {
        return password_verify($password, $storedPassword);
    }

    return hash_equals($storedPassword, $password);
}

function migrate_legacy_password_if_needed(mysqli $conn, int $userId, string $password, string $storedPassword): void
{
    if (!verify_user_password($password, $storedPassword)) {
        return;
    }

    if (is_password_hash_value($storedPassword) &&
        !password_needs_rehash($storedPassword, PASSWORD_DEFAULT)) {
        return;
    }

    $hashed = hash_user_password($password);
    $stmt = $conn->prepare("UPDATE users SET password_hash = ? WHERE user_id = ?");
    $stmt->bind_param("si", $hashed, $userId);
    $stmt->execute();
    $stmt->close();
}
