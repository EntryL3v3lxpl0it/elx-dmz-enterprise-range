<?php
// Acme Search - DB bootstrap. AUTHORIZED LAB USE ONLY.
// The WEB-03 flag is injected from the environment per-deploy (never committed).

function acme_db(): mysqli {
    $host = getenv('DB_HOST') ?: 'db';
    $user = getenv('DB_USER') ?: 'search_app';
    $pass = getenv('DB_PASS') ?: 'search_app_pw';
    $name = getenv('DB_NAME') ?: 'search';

    // Retry briefly so the container can start before MariaDB is ready.
    for ($i = 0; $i < 30; $i++) {
        $c = @mysqli_connect($host, $user, $pass, $name);
        if ($c) {
            acme_ensure_flag($c);
            return $c;
        }
        sleep(2);
    }
    http_response_code(503);
    die("database unavailable");
}

function acme_ensure_flag(mysqli $c): void {
    // Idempotently set the secrets flag row from the environment.
    $flag = getenv('FLAG_WEB03') ?: 'ELX{web03_PLACEHOLDER}';
    $stmt = $c->prepare(
        "INSERT INTO secrets (name, value) VALUES ('web03_flag', ?)
         ON DUPLICATE KEY UPDATE value = VALUES(value)"
    );
    $stmt->bind_param('s', $flag);
    $stmt->execute();
    $stmt->close();
}

function chain_web03_enabled(): bool {
    $v = strtolower(trim((string)(getenv('CHAIN_WEB03') ?: 'true')));
    return in_array($v, ['1', 'true', 'yes', 'on'], true);
}
