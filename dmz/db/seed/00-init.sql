-- ELX DMZ Range — MariaDB init (runs once on first DB init, alphabetical order).
-- AUTHORIZED LAB USE ONLY.
--
-- App<->DB passwords below are lab-internal: the DB is published only on the
-- internal `backend` Docker network and is never reachable from outside the
-- host. Rotate by editing both this file and docker-compose.yml if desired.

CREATE DATABASE IF NOT EXISTS portal CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS search CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Portal app creates its own schema at startup, so it needs DDL — but only
-- within the `portal` database.
CREATE USER IF NOT EXISTS 'portal_app'@'%' IDENTIFIED BY 'portal_app_pw';
GRANT ALL PRIVILEGES ON portal.* TO 'portal_app'@'%';

-- Search app only reads its schema and upserts the flag row.
CREATE USER IF NOT EXISTS 'search_app'@'%' IDENTIFIED BY 'search_app_pw';
GRANT SELECT, INSERT, UPDATE ON search.* TO 'search_app'@'%';

FLUSH PRIVILEGES;
