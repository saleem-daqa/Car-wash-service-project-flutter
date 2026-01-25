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
