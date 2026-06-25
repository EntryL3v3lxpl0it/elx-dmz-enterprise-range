# Acme Docs (WEB-04) — intentionally vulnerable training app, lab only.
# Execution from an uploaded file is contained to this ephemeral container:
# non-root apache (www-data), no host mounts, no internet egress (host route),
# reset by redeploy. See compose for cap_drop / no-new-privileges / limits.
FROM php:8.2-apache

# AllowOverride so the fixed-mode uploads/.htaccess takes effect.
RUN sed -ri 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf || true

COPY src/ /var/www/html/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80
HEALTHCHECK --interval=15s --timeout=3s --retries=10 \
  CMD php -r 'exit(@file_get_contents("http://127.0.0.1/health.php")==="ok"?0:1);'

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
