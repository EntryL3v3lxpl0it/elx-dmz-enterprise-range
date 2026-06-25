<?php
// Acme Search - WEB-03 SQL injection chain. AUTHORIZED LAB USE ONLY.
require __DIR__ . '/db.php';
$c = acme_db();

$q = isset($_GET['q']) ? $_GET['q'] : '';

header('Content-Type: text/plain');
echo "Acme Search results for: {$q}\n";
echo str_repeat('-', 50) . "\n";

if (chain_web03_enabled()) {
    // VULNERABLE: user input concatenated directly into the SQL string.
    // Enables UNION-based extraction of users / secrets, e.g.:
    //   q = x' UNION SELECT name, value, 1 FROM secrets-- -
    $sql = "SELECT name, description, price FROM products WHERE name LIKE '%{$q}%'";
    $res = $c->query($sql);
    if ($res === false) {
        // Error-based feedback is part of the learning surface in vuln mode.
        echo "SQL error: " . $c->error . "\n";
    } else {
        while ($row = $res->fetch_assoc()) {
            echo implode(' | ', array_map('strval', $row)) . "\n";
        }
    }
} else {
    // FIXED: parameterized query. Injection input is treated as data only.
    $stmt = $c->prepare(
        "SELECT name, description, price FROM products WHERE name LIKE CONCAT('%', ?, '%')"
    );
    $stmt->bind_param('s', $q);
    $stmt->execute();
    $res = $stmt->get_result();
    while ($row = $res->fetch_assoc()) {
        echo implode(' | ', array_map('strval', $row)) . "\n";
    }
    $stmt->close();
}
