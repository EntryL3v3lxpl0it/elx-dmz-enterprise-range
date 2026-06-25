-- ELX DMZ Range — Acme Search schema + seed. AUTHORIZED LAB USE ONLY.
-- WEB-03 (SQL injection) extracts from this database. Password hashes are
-- intentionally weak MD5 of weak passwords. Cracking the `padmin` hash yields
-- "Autumn2024!", which is also padmin's Acme Portal password (cross-link into
-- WEB-01 / WEB-08 territory).

USE search;

CREATE TABLE IF NOT EXISTS products (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(128) NOT NULL,
    description VARCHAR(255),
    price       DECIMAL(10,2)
);

CREATE TABLE IF NOT EXISTS users (
    id            INT PRIMARY KEY AUTO_INCREMENT,
    username      VARCHAR(64) UNIQUE NOT NULL,
    password_hash CHAR(32) NOT NULL          -- weak MD5, intentional
);

CREATE TABLE IF NOT EXISTS secrets (
    name  VARCHAR(64) PRIMARY KEY,
    value TEXT
);

INSERT INTO products (name, description, price) VALUES
    ('Acme Stapler',      'Heavy-duty desktop stapler',     19.99),
    ('Acme Notebook',     'A5 ruled, 200 pages',             4.50),
    ('Acme Monitor 27"',  '1440p IPS display',             279.00),
    ('Acme Keyboard',     'Mechanical, brown switches',     89.00),
    ('Acme Webcam',       '1080p with privacy shutter',     49.99)
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- Weak MD5 hashes (see project notes for plaintexts).
INSERT INTO users (username, password_hash) VALUES
    ('padmin',     '2d65c509dae7eac873ad1449afb5b1c6'),  -- Autumn2024!
    ('jbrown',     '21ca4318f03e978629157d88ef647031'),  -- summer2023
    ('svc_report', 'b56e0b4ea4962283bee762525c2d490f'),  -- Welcome1
    ('guest',      '084e0343a0486ff05530df6c705c8bb4')   -- guest
ON DUPLICATE KEY UPDATE password_hash = VALUES(password_hash);

-- Flag placeholder; the Search app upserts the real per-deploy value from
-- the FLAG_WEB03 environment variable at runtime.
INSERT INTO secrets (name, value) VALUES ('web03_flag', 'ELX{web03_PLACEHOLDER}')
ON DUPLICATE KEY UPDATE value = VALUES(value);
