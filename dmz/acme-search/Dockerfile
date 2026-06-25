# Acme Search (WEB-03) — intentionally vulnerable training app, lab only.
FROM php:8.2-apache

RUN docker-php-ext-install mysqli && a2enmod rewrite

COPY src/ /var/www/html/

# Runs as www-data (default for this image). No host mounts; ephemeral.
EXPOSE 80
HEALTHCHECK --interval=15s --timeout=3s --retries=10 \
  CMD php -r 'exit(@file_get_contents("http://127.0.0.1/health.php")==="ok"?0:1);'
