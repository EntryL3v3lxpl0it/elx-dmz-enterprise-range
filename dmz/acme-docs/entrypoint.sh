#!/bin/sh
set -eu

# Flag readable only via in-container execution (the WEB-04 objective).
FLAG="${FLAG_WEB04:-ELX{web04_PLACEHOLDER}}"
printf '%s\n' "$FLAG" > /flag
chmod 0644 /flag

UP=/var/www/html/uploads
mkdir -p "$UP"
chown -R www-data:www-data "$UP"

# Toggle PHP execution in the upload directory.
#   chain enabled  -> remove .htaccess so uploaded .php executes (vulnerable)
#   chain disabled -> drop .htaccess that disables the PHP engine (fixed)
CHAIN="$(printf '%s' "${CHAIN_WEB04:-true}" | tr '[:upper:]' '[:lower:]')"
case "$CHAIN" in
  1|true|yes|on)
    rm -f "$UP/.htaccess"
    ;;
  *)
    {
      echo "# Fixed mode: never execute anything in the upload directory."
      echo "php_admin_flag engine off"
      echo "RemoveHandler .php .phtml .php3 .php4 .php5 .php7 .phps"
      echo "RemoveType .php .phtml .php3 .php4 .php5 .php7 .phps"
    } > "$UP/.htaccess"
    ;;
esac

exec apache2-foreground
