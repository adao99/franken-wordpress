#!/bin/sh
set -e

WP_CONFIG="/var/www/html/wp-config.php"

# If wp-config.php doesn't exist, copy sample
if [ ! -f "$WP_CONFIG" ]; then
    cp /var/www/html/wp-config-sample.php "$WP_CONFIG"
fi

# Append standard WordPress env variables to wp-config.php if not already defined
{
  [ -n "$WORDPRESS_DB_HOST" ] && grep -q "DB_HOST" "$WP_CONFIG" || echo "define('DB_HOST', '${WORDPRESS_DB_HOST}');"
  [ -n "$WORDPRESS_DB_NAME" ] && grep -q "DB_NAME" "$WP_CONFIG" || echo "define('DB_NAME', '${WORDPRESS_DB_NAME}');"
  [ -n "$WORDPRESS_DB_USER" ] && grep -q "DB_USER" "$WP_CONFIG" || echo "define('DB_USER', '${WORDPRESS_DB_USER}');"
  [ -n "$WORDPRESS_DB_PASSWORD" ] && grep -q "DB_PASSWORD" "$WP_CONFIG" || echo "define('DB_PASSWORD', '${WORDPRESS_DB_PASSWORD}');"
  [ -n "$WORDPRESS_DEBUG" ] && grep -q "WP_DEBUG" "$WP_CONFIG" || echo "define('WP_DEBUG', ${WORDPRESS_DEBUG});"
} >> "$WP_CONFIG"

# Append extra config from environment variable
if [ -n "$WORDPRESS_CONFIG_EXTRA" ]; then
    echo "" >> "$WP_CONFIG"
    echo "// Extra config from WORDPRESS_CONFIG_EXTRA" >> "$WP_CONFIG"
    echo "$WORDPRESS_CONFIG_EXTRA" >> "$WP_CONFIG"
fi



# Execute the main command
exec "$@"