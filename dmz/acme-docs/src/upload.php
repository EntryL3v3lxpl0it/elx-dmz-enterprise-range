<?php
// Acme Docs - WEB-04 file upload chain. AUTHORIZED LAB USE ONLY.
// Execution of an uploaded file is confined to this single, non-root,
// no-host-mount, ephemeral container with no internet egress (host has no
// route). The proof artifact reads /flag inside the container only.

function chain_web04_enabled(): bool {
    $v = strtolower(trim((string)(getenv('CHAIN_WEB04') ?: 'true')));
    return in_array($v, ['1', 'true', 'yes', 'on'], true);
}

header('Content-Type: text/plain');

if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo "no file / upload error\n";
    exit;
}

$upload_dir = __DIR__ . '/uploads';
$tmp  = $_FILES['file']['tmp_name'];
$orig = basename($_FILES['file']['name']);

if (chain_web04_enabled()) {
    // ---------------- VULNERABLE PATH ----------------
    // Trusts the client-supplied Content-Type and keeps the original filename
    // (and therefore the original extension). A request with
    // Content-Type: image/png but filename poc.php and PHP body is accepted,
    // lands in a web-served dir, and Apache executes it as PHP.
    $allowed_types = ['image/png', 'image/jpeg', 'image/gif'];
    $client_type = $_FILES['file']['type'];          // attacker-controlled
    if (!in_array($client_type, $allowed_types, true)) {
        http_response_code(400);
        echo "rejected: type {$client_type} not allowed\n";
        exit;
    }
    $dest = $upload_dir . '/' . $orig;               // original name + extension
    move_uploaded_file($tmp, $dest);
    echo "stored: /uploads/" . $orig . "\n";
} else {
    // ---------------- FIXED PATH ----------------
    // Verifies the bytes are really an image, force-generates a random safe
    // name with a .png extension, and stores it where PHP execution is disabled
    // (uploads/.htaccess written by the entrypoint in fixed mode).
    $info = @getimagesize($tmp);
    $real_types = [IMAGETYPE_PNG, IMAGETYPE_JPEG, IMAGETYPE_GIF];
    if ($info === false || !in_array($info[2], $real_types, true)) {
        http_response_code(400);
        echo "rejected: file is not a valid image\n";
        exit;
    }
    $name = bin2hex(random_bytes(16)) . '.png';
    $dest = $upload_dir . '/' . $name;
    move_uploaded_file($tmp, $dest);
    echo "stored (sanitized): /uploads/" . $name . "\n";
}
